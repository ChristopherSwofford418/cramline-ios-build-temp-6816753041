import { z } from "zod";

export const weekdaySchema = z.number().int().min(1).max(7);

export const broadStudyDomainSchema = z.enum([
  "licensing",
  "certification",
  "board",
  "admission",
  "qualifying",
  "other",
]);

export const localClockTimeSchema = z.object({
  hour: z.number().int().min(0).max(23),
  minute: z.number().int().min(0).max(59),
}).strict();

export const preferredStudyTimeSchema = z.object({
  weekday: weekdaySchema,
  start: localClockTimeSchema,
  maximumMinutes: z.number().int().min(25).max(180),
}).strict();

export const planningRequestSchema = z.object({
  sprintEndDate: z.string().datetime({ offset: true }),
  broadStudyDomain: broadStudyDomainSchema.nullable().optional(),
  desiredWeeklyHours: z.number().min(1).max(80),
  preferredTimes: z.array(preferredStudyTimeSchema).max(21),
  selfReportedConfidence: z.number().int().min(1).max(5).nullable().optional(),
  consentAcknowledged: z.literal(true),
}).strict();

export type PlanningRequest = z.infer<typeof planningRequestSchema>;

export const rawDraftSchema = {
  type: "object",
  properties: {
    sessions: {
      type: "array",
      minItems: 1,
      maxItems: 21,
      items: {
        type: "object",
        properties: {
          weekday: { type: "integer", minimum: 1, maximum: 7 },
          start: {
            type: "object",
            properties: {
              hour: { type: "integer", minimum: 0, maximum: 23 },
              minute: { type: "integer", minimum: 0, maximum: 59 },
            },
            required: ["hour", "minute"],
            additionalProperties: false,
          },
          durationMinutes: { type: "integer", minimum: 25, maximum: 180 },
          focusCue: { type: "string", minLength: 1, maxLength: 160 },
        },
        required: ["weekday", "start", "durationMinutes", "focusCue"],
        additionalProperties: false,
      },
    },
    breakCadence: { type: "string", minLength: 1, maxLength: 200 },
    implementationIntention: { type: "string", minLength: 1, maxLength: 240 },
    isDraft: { type: "boolean", const: true },
  },
  required: ["sessions", "breakCadence", "implementationIntention", "isDraft"],
  additionalProperties: false,
} as const;
