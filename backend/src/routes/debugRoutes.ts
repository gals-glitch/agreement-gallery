import { Router } from "express";
import { z } from "zod";
const router = Router();

const debugServicePath =
  process.env.TS_NODE_DEV === "1"
    ? "../services/debugService.ts"
    : "../services/debugService.js";

let debugServicePromise: Promise<typeof import("../services/debugService")> | null = null;

const loadDebugService = () => {
  if (!debugServicePromise) {
    debugServicePromise = import(debugServicePath);
  }
  return debugServicePromise;
};

const querySchema = z.object({
  email: z.string().email().optional(),
  contactId: z
    .string()
    .transform((value) => Number(value))
    .refine((value) => Number.isFinite(value) && value > 0, "Invalid contact id")
    .optional(),
  from: z.string().optional(),
  to: z.string().optional(),
});

router.get("/debug/investor", async (req, res, next) => {
  try {
    const parsed = querySchema.parse(req.query);
    if (!parsed.email && !parsed.contactId) {
      return res.status(400).json({ error: "email or contactId is required" });
    }
    const { getDebugInvestorFundSources } = await loadDebugService();
    const result = await getDebugInvestorFundSources({
      email: parsed.email,
      contactId: parsed.contactId,
      from: parsed.from,
      to: parsed.to,
    });
    res.json(result);
  } catch (error) {
    next(error);
  }
});

router.get("/portfolio/funds", async (req, res, next) => {
  try {
    const parsed = querySchema.parse(req.query);
    if (!parsed.email && !parsed.contactId) {
      return res.status(400).json({ error: "email or contactId is required" });
    }
    const { getDebugInvestorFundSources } = await loadDebugService();
    const result = await getDebugInvestorFundSources({
      email: parsed.email,
      contactId: parsed.contactId,
      from: parsed.from,
      to: parsed.to,
    });
    res.json({
      investmentsCount: result.unionFundCount,
      funds: result.perFund.map((fund) => ({
        id: fund.fundId,
        name: fund.fundName,
      })),
    });
  } catch (error) {
    next(error);
  }
});

export default router;
