import type { Request, Response, NextFunction } from "express";
import { Router } from "express";
import { z } from "zod";

import { snapshotService } from "../services/snapshotService";

const router = Router();

const paramsSchema = z.object({
  contactId: z
    .string()
    .transform((value) => Number(value))
    .refine((value) => Number.isFinite(value) && value > 0, "Invalid contact id"),
});

const querySchema = z.object({
  from: z.string(),
  to: z.string(),
  base: z.string().default("USD"),
  lang: z.string().optional(),
  preset: z.string().optional(),
  netView: z.enum(["invested", "toInvestor"]).optional(),
});

const CACHE_CONTROL = "public, max-age=60, stale-while-revalidate=300";

router.get(
  "/investor/:contactId/snapshot",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const params = paramsSchema.parse(req.params);
      const query = querySchema.parse(req.query);
      const { payload, etag } = await snapshotService.getSnapshot(params.contactId, {
        from: query.from,
        to: query.to,
        base: query.base,
        lang: query.lang,
        preset: query.preset,
        netView: query.netView ?? "invested",
      });

      if (req.headers["if-none-match"] === etag) {
        res.status(304).end();
        return;
      }

      res.setHeader("Cache-Control", CACHE_CONTROL);
      res.setHeader("ETag", etag);
      res.json(payload);
    } catch (error) {
      next(error);
    }
  },
);

export default router;
