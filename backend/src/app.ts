import express from "express";
import cors from "cors";
import morgan from "morgan";
import investorsRoute from "./routes/investorRoutes";\nimport investorSnapshotRoute from "./routes/investorSnapshot";
import { errorHandler } from "./middleware/errorHandler";
import { config } from "./config/env";

export const createApp = () => {
  const app = express();

  app.use(cors());
  app.use(express.json());

  if (config.enableRequestLogging) {
    app.use(morgan("combined"));
  }

  app.get("/api/health", (_req, res) => {
    res.json({ status: "ok", timestamp: new Date().toISOString() });
  });

  app.use("/api", investorSnapshotRoute);\n  app.use("/api/investors", investorsRoute);

  if (config.enableDebugRoutes) {
    const debugModulePath = process.env.TS_NODE_DEV ? "./routes/debugRoutes.ts" : "./routes/debugRoutes.js";

    import(debugModulePath)
      .then(({ default: debugRoute }) => {
        app.use("/api", debugRoute);
      })
      .catch((error) => {
        console.error("Failed to load debug routes", error);
      });
  }

  app.use(errorHandler);

  return app;
};





