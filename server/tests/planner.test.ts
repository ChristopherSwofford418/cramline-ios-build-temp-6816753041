import { describe, expect, it } from "vitest";
import { planningRequestSchema } from "../src/contracts.js";
import { choosePlanningModel, createPlanningDraft } from "../src/planner.js";

const validRequest = {
  sprintEndDate: "2026-12-01T00:00:00Z",
  broadStudyDomain: "licensing" as const,
  desiredWeeklyHours: 7,
  preferredTimes: [],
  selfReportedConfidence: 3,
  consentAcknowledged: true as const,
};

describe("planning privacy boundary", () => {
  it("rejects selected apps, device identity, activity, and reflections", () => {
    for (const extra of [
      { selectedApps: ["FictionalSocial"] },
      { deviceID: "fictional-device" },
      { appActivity: "120 minutes" },
      { reflection: "I felt distracted" },
    ]) {
      expect(planningRequestSchema.safeParse({ ...validRequest, ...extra }).success).toBe(false);
    }
  });

  it("prefers the live catalog's low-cost planning model", () => {
    expect(choosePlanningModel([
      { id: "gpt-5", pricing: { input_per_1m_usd: 1.25, output_per_1m_usd: 10 } },
      { id: "gpt-5-mini", pricing: { input_per_1m_usd: 0.25, output_per_1m_usd: 2 } },
    ])).toBe("gpt-5-mini");
  });

  it("sends only validated planning fields and returns a structured draft", async () => {
    const bodies: unknown[] = [];
    const fakeFetch: typeof fetch = async (input, init) => {
      const url = String(input);
      if (url.endsWith("/models")) {
        return new Response(JSON.stringify({ data: [{ id: "gpt-5-mini" }] }), { status: 200 });
      }
      bodies.push(JSON.parse(String(init?.body)));
      return new Response(JSON.stringify({
        choices: [{ message: { content: JSON.stringify({
          sessions: [{ weekday: 2, start: { hour: 19, minute: 0 }, durationMinutes: 60, focusCue: "Complete one practice set." }],
          breakCadence: "Work for 50 minutes, then rest for 10 minutes.",
          implementationIntention: "If I want social media, I will note the thought and return to study.",
          isDraft: true,
        }) } }],
      }), { status: 200 });
    };
    const parsed = planningRequestSchema.parse(validRequest);
    const result = await createPlanningDraft(parsed, { baseURL: "https://example.test/v1", apiKey: "secret", fetchImpl: fakeFetch });
    expect(result.draft.sessions).toHaveLength(1);
    expect(JSON.stringify(bodies)).not.toMatch(/selectedApps|deviceID|appActivity|reflection/);
  });
});
