import "dotenv/config";

import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import { pool } from "../config/database.ts";

import { type PoolClient } from "pg";

async function runMigrations() {
  let client: PoolClient | undefined;

  try {
    client = await pool.connect();
    await client.query(`
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        file_name TEXT NOT NULL UNIQUE,
        executed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    const migrationsPath = fileURLToPath(
      new URL("../../database/migrations/", import.meta.url),
    );

    const files = (await readdir(migrationsPath))
      .filter((file) => file.endsWith(".sql"))
      .sort();

    for (const file of files) {
      const migrationExists = await client.query(
        `
          SELECT 1
          FROM migrations
          WHERE file_name = $1
        `,
        [file],
      );

      if (migrationExists.rows.length > 0) {
        console.log(`↷ Skipped ${file}`);
        continue;
      }

      const sql = await readFile(join(migrationsPath, file), "utf8");

      try {
        await client.query("BEGIN");

        await client.query(sql);

        await client.query(
          `
            INSERT INTO migrations (file_name)
            VALUES ($1)
          `,
          [file],
        );

        await client.query("COMMIT");

        console.log(`✓ ${file}`);
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      }
    }

    console.log("All migrations completed 🚀");
  } finally {
    client?.release();
    await pool.end();
  }
}

runMigrations().catch((error) => {
  console.error("Migration failed ❌");
  console.error(error);

  process.exitCode = 1;
});
