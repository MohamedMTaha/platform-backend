import "dotenv/config";

import { pool } from "../config/database.ts";

try {
  const result = await pool.query(`
    SELECT
      current_database() AS database,
      current_user AS user,
      TO_CHAR(NOW() AT TIME ZONE 'Africa/Cairo', 'YYYY-MM-DD HH24:MI:SS') AS server_time;
  `);

  console.log("Database connection successful!");
  console.table(result.rows);
} catch (error) {
  console.error("Database connection failed!");
  console.error(error);

  process.exitCode = 1;
} finally {
  await pool.end();
}
