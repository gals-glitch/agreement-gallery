import type { Request, Response, NextFunction } from "express";
import { logger } from "../utils/logger";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const errorHandler = (err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  const status = 500;
  const message = err instanceof Error ? err.message : "Unexpected error";
  logger.error("Request failed", {
    message,
    stack: err instanceof Error ? err.stack : undefined,
  });
  res.status(status).json({ error: message });
};

