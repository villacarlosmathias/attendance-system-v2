require("dotenv").config();

const express = require("express");
const cors = require("cors");
const pool = require("./db");

const app = express();
const PORT = process.env.PORT || 10000;

app.use(cors());
app.use(express.json({ limit: "20mb" }));

app.get("/", (req, res) => {
  res.json({ message: "Attendance API is running" });
});

app.get("/test-db", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW()");
    res.json({ success: true, time: result.rows[0].now });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post("/setup-db", async (req, res) => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS events (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        venue TEXT,
        event_date DATE,
        start_time TEXT,
        end_time TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS event_attendees (
        id SERIAL PRIMARY KEY,
        event_id INTEGER REFERENCES events(id) ON DELETE CASCADE,
        seat_no INTEGER,
        student_no VARCHAR(50),
        full_name TEXT,
        college_school TEXT,
        program TEXT,
        college TEXT,
        sport TEXT,
        status VARCHAR(30) DEFAULT 'Pending',
        checked_in_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(event_id, student_no)
      );

      CREATE TABLE IF NOT EXISTS attendance_logs (
        id SERIAL PRIMARY KEY,
        attendee_id INTEGER REFERENCES event_attendees(id) ON DELETE CASCADE,
        event_id INTEGER REFERENCES events(id) ON DELETE CASCADE,
        student_no VARCHAR(50),
        ip_address TEXT,
        user_agent TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    res.json({ success: true, message: "Database tables created" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get("/events", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM events ORDER BY id DESC");
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get("/events/:id", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM events WHERE id = $1", [
      req.params.id,
    ]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Event not found" });
    }

    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post("/events", async (req, res) => {
  try {
    const { title, venue, event_date, start_time, end_time } = req.body;

    const result = await pool.query(
      `INSERT INTO events (title, venue, event_date, start_time, end_time)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [title, venue, event_date, start_time, end_time]
    );

    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.delete("/events/:id", async (req, res) => {
  try {
    const { id } = req.params;

    await pool.query("DELETE FROM events WHERE id = $1", [id]);

    res.json({
      success: true,
      message: "Event deleted successfully.",
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get("/events/:eventId/attendees", async (req, res) => {
  try {
    const { eventId } = req.params;

    const result = await pool.query(
      `SELECT * FROM event_attendees
       WHERE event_id = $1
       ORDER BY seat_no ASC, full_name ASC`,
      [eventId]
    );

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post("/events/:eventId/attendees", async (req, res) => {
  try {
    const { eventId } = req.params;

    const {
      seat_no,
      student_no,
      full_name,
      college_school,
      program,
      college,
      sport,
    } = req.body;

    const result = await pool.query(
      `INSERT INTO event_attendees
       (event_id, seat_no, student_no, full_name, college_school, program, college, sport)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT (event_id, student_no)
       DO UPDATE SET
         seat_no = EXCLUDED.seat_no,
         full_name = EXCLUDED.full_name,
         college_school = EXCLUDED.college_school,
         program = EXCLUDED.program,
         college = EXCLUDED.college,
         sport = EXCLUDED.sport
       RETURNING *`,
      [
        eventId,
        seat_no || null,
        student_no,
        full_name,
        college_school || null,
        program || null,
        college || null,
        sport || null,
      ]
    );

    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post("/events/:eventId/import-attendees", async (req, res) => {
  const client = await pool.connect();

  try {
    const { eventId } = req.params;
    const { attendees } = req.body;

    if (!Array.isArray(attendees) || attendees.length === 0) {
      return res.status(400).json({ message: "No attendees to import." });
    }

    await client.query("BEGIN");

    let imported = 0;
    let skipped = 0;

    for (const attendee of attendees) {
      const {
        seat_no,
        student_no,
        full_name,
        college_school,
        program,
        college,
        sport,
      } = attendee;

      if (!student_no || !full_name) {
        skipped++;
        continue;
      }

      await client.query(
        `INSERT INTO event_attendees
         (event_id, seat_no, student_no, full_name, college_school, program, college, sport)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (event_id, student_no)
         DO UPDATE SET
           seat_no = EXCLUDED.seat_no,
           full_name = EXCLUDED.full_name,
           college_school = EXCLUDED.college_school,
           program = EXCLUDED.program,
           college = EXCLUDED.college,
           sport = EXCLUDED.sport`,
        [
          eventId,
          seat_no || null,
          student_no,
          full_name,
          college_school || null,
          program || null,
          college || null,
          sport || null,
        ]
      );

      imported++;
    }

    await client.query("COMMIT");

    res.json({ success: true, imported, skipped });
  } catch (error) {
    await client.query("ROLLBACK");
    res.status(500).json({ message: error.message });
  } finally {
    client.release();
  }
});

app.post("/events/:eventId/register", async (req, res) => {
  try {
    const { eventId } = req.params;
    const { student_no } = req.body;

    const found = await pool.query(
      `SELECT * FROM event_attendees
       WHERE event_id = $1 AND student_no = $2`,
      [eventId, student_no]
    );

    if (found.rows.length === 0) {
      return res.status(404).json({
        message: "Student number not found for this event.",
      });
    }

    const attendee = found.rows[0];

    if (attendee.status === "Checked In") {
      return res.json({
        message: "Already checked in.",
        ...attendee,
      });
    }

    const updated = await pool.query(
      `UPDATE event_attendees
       SET status = 'Checked In', checked_in_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING *`,
      [attendee.id]
    );

    await pool.query(
      `INSERT INTO attendance_logs
       (attendee_id, event_id, student_no, ip_address, user_agent)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        attendee.id,
        eventId,
        student_no,
        req.ip,
        req.headers["user-agent"] || null,
      ]
    );

    res.json({
      message: "Attendance confirmed.",
      ...updated.rows[0],
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get("/events/:eventId/report", async (req, res) => {
  try {
    const { eventId } = req.params;

    const result = await pool.query(
      `SELECT
        seat_no,
        student_no,
        full_name,
        college_school,
        program,
        college,
        sport,
        status,
        checked_in_at
       FROM event_attendees
       WHERE event_id = $1
       ORDER BY seat_no ASC, full_name ASC`,
      [eventId]
    );

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});