import { randomUUID } from "node:crypto";
import type { PlanningRequest } from "./contracts.js";
import { rawDraftSchema } from "./contracts.js";

type CatalogModel = {
  id: string;
  pricing?: { input_per_1m_usd?: number; output_per_1m_usd?: number };
};

type ModelCatalog = { data: CatalogModel[] };

export type LLMConfig = {
  baseURL: string;
  apiKey: string;
  fetchImpl?: typeof fetch;
};

function normalizeBaseURL(value: string): string {
  return value.replace(/\/+$/, "");
}

export async function listLLMModels(config: LLMConfig): Promise<CatalogModel[]> {
  const request = config.fetchImpl ?? fetch;
  const response = await request(`${normalizeBaseURL(config.baseURL)}/models`, {
    headers: { Authorization: `Bearer ${config.apiKey}` },
    cache: "no-store",
  });
  if (!response.ok) throw new Error("model_catalog_unavailable");
  const catalog = (await response.json()) as ModelCatalog;
  return Array.isArray(catalog.data) ? catalog.data : [];
}

export function choosePlanningModel(models: CatalogModel[]): string {
  if (models.some((model) => model.id === "gpt-5-mini")) return "gpt-5-mini";
  const affordable = [...models].sort((a, b) => {
    const aCost = (a.pricing?.input_per_1m_usd ?? 999) + (a.pricing?.output_per_1m_usd ?? 999);
    const bCost = (b.pricing?.input_per_1m_usd ?? 999) + (b.pricing?.output_per_1m_usd ?? 999);
    return aCost - bCost;
  });
  if (!affordable[0]) throw new Error("no_planning_model_available");
  return affordable[0].id;
}

export async function createPlanningDraft(input: PlanningRequest, config: LLMConfig) {
  const request = config.fetchImpl ?? fetch;
  const models = await listLLMModels(config);
  const model = choosePlanningModel(models);
  const upstreamBody: Record<string, unknown> = {
    model,
    messages: [
      {
        role: "system",
        content: [
          "You draft calm, non-clinical professional-exam study schedules.",
          "Use only the user-entered planning fields in the request.",
          "Never claim guaranteed focus or exam results.",
          "Never make enforcement, override, legitimacy, diagnosis, or surveillance decisions.",
          "Return a reviewable draft, not an automatic schedule.",
        ].join(" "),
      },
      { role: "user", content: JSON.stringify(input) },
    ],
    response_format: {
      type: "json_schema",
      json_schema: { name: "cramline_planning_draft", strict: true, schema: rawDraftSchema },
    },
  };
  if (model.startsWith("gpt-")) upstreamBody.max_completion_tokens = 2500;

  const response = await request(`${normalizeBaseURL(config.baseURL)}/chat/completions`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${config.apiKey}`,
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
    body: JSON.stringify(upstreamBody),
    cache: "no-store",
  });
  if (!response.ok) throw new Error("planning_model_unavailable");
  const result = await response.json() as { choices?: Array<{ message?: { content?: string } }> };
  const content = result.choices?.[0]?.message?.content;
  if (!content) throw new Error("planning_model_invalid_response");
  const draft = JSON.parse(content) as {
    sessions: Array<Record<string, unknown>>;
    breakCadence: string;
    implementationIntention: string;
    isDraft: true;
  };
  return {
    draft: {
      ...draft,
      sessions: draft.sessions.map((session) => ({ id: randomUUID(), ...session })),
    },
    modelLabel: model,
    retainedByCramline: false,
  };
}
