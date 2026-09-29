import express from "express";
import { planningRequestSchema } from "./contracts.js";
import { createPlanningDraft, type LLMConfig } from "./planner.js";

export function createApp(config: LLMConfig | null) {
  const app = express();
  app.disable("x-powered-by");
  app.use(express.json({ limit: "16kb", strict: true }));
  app.use((_request, response, next) => {
    response.setHeader("Cache-Control", "no-store");
    response.setHeader("Pragma", "no-cache");
    response.setHeader("Referrer-Policy", "no-referrer");
    next();
  });

  app.get("/health", (_request, response) => {
    response.json({ ok: true, aiConfigured: Boolean(config) });
  });

  app.post("/v1/plan", async (request, response) => {
    if (!config) {
      response.status(503).json({ error: "ai_not_configured", fallback: "Use the on-device planner." });
      return;
    }
    const parsed = planningRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      response.status(400).json({ error: "invalid_planning_fields" });
      return;
    }
    try {
      const draft = await createPlanningDraft(parsed.data, config);
      response.status(200).json(draft);
    } catch {
      response.status(503).json({ error: "ai_unavailable", fallback: "Use the on-device planner." });
    }
  });

  app.use((_request, response) => response.status(404).json({ error: "not_found" }));
  return app;
}
