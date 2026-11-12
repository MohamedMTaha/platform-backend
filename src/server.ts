import "dotenv/config";

import app from "./app.ts";

const PORT = Number(process.env.PORT ?? 3000);

if (!Number.isInteger(PORT) || PORT < 1 || PORT > 65535) {
  throw new Error("Invalid PORT configuration");
}

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
