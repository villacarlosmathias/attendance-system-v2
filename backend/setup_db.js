require("dotenv").config();
const pool = require("./db");

async function setupDatabase() {
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
        student_no TEXT NOT NULL,
        full_name TEXT NOT NULL,
        college_school TEXT,
        program TEXT,
        college TEXT,
        sport TEXT,
        status TEXT DEFAULT 'Pending',
        checked_in_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(event_id, student_no)
      );

      CREATE TABLE IF NOT EXISTS attendance_logs (
        id SERIAL PRIMARY KEY,
        attendee_id INTEGER REFERENCES event_attendees(id) ON DELETE CASCADE,
        event_id INTEGER REFERENCES events(id) ON DELETE CASCADE,
        student_no TEXT,
        action TEXT DEFAULT 'Checked In',
        ip_address TEXT,
        user_agent TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    console.log("Database tables created successfully.");
  } catch (error) {
    console.error("Database setup failed:", error.message);
  } finally {
    await pool.end();
  }
}

setupDatabase();
