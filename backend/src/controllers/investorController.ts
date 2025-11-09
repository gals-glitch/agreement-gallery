import { z } from "zod";
import type { Request, Response, NextFunction } from "express";
import { portfolioService } from "../services/portfolioService";

const searchSchema = z.object({
  q: z.string().min(0).optional(),
});

const portfolioSchema = z.object({
  params: z.object({
    contactId: z
      .string()
      .transform((value) => Number(value))
      .refine((value) => Number.isFinite(value) && value > 0, "Invalid contact id"),
  }),
  query: z.object({
    from: z.string().optional(),
    to: z.string().optional(),
    base: z.string().optional(),
  }),
});

export class InvestorController {
  async search(req: Request, res: Response, next: NextFunction) {
    try {
      const { q } = searchSchema.parse(req.query);
      const results = await portfolioService.searchInvestors(q ?? "");
      res.json({ results });
    } catch (error) {
      next(error);
    }
  }

  async portfolio(req: Request, res: Response, next: NextFunction) {
    try {
      const parsed = portfolioSchema.parse({ params: req.params, query: req.query });
      const summary = await portfolioService.getPortfolio(parsed.params.contactId, {
        from: parsed.query.from,
        to: parsed.query.to,
        baseCurrency: parsed.query.base,
      });
      res.json(summary);
    } catch (error) {
      next(error);
    }
  }
}

export const investorController = new InvestorController();

