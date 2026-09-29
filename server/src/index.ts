import { createApp } from "./app.js";

const baseURL = process.env.BUILT_IN_FORGE_API_URL ?? process.env.OPENAI_API_BASE;
const apiKey = process.env.BUILT_IN_FORGE_API_KEY ?? process.env.OPENAI_API_KEY;
const config = baseURL && apiKey ? { baseURL, apiKey } : null;
const port = Number(process.env.PORT ?? 8787);

createApp(config).listen(port, "0.0.0.0", () => {
  // Deliberately log only service state; never request fields or AI output.
  console.log(`Cramline planning service listening on ${port}; AI configured=${Boolean(config)}`);
});
