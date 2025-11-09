type LogLevel = "debug" | "info" | "warn" | "error";

const levelPriority: Record<LogLevel, number> = {
  debug: 10,
  info: 20,
  warn: 30,
  error: 40,
};

const resolvedLevel = () => {
  const envLevel = (process.env.LOG_LEVEL ?? "info").toLowerCase() as LogLevel;
  return levelPriority[envLevel] ? envLevel : "info";
};

const shouldLog = (level: LogLevel) => levelPriority[level] >= levelPriority[resolvedLevel()];

const format = (level: LogLevel, message: string, meta?: Record<string, unknown>) =>
  JSON.stringify({
    timestamp: new Date().toISOString(),
    level,
    message,
    ...(meta ? { meta } : {}),
  });

export const logger = {
  debug: (message: string, meta?: Record<string, unknown>) => {
    if (shouldLog("debug")) {
      // eslint-disable-next-line no-console
      console.debug(format("debug", message, meta));
    }
  },
  info: (message: string, meta?: Record<string, unknown>) => {
    if (shouldLog("info")) {
      // eslint-disable-next-line no-console
      console.info(format("info", message, meta));
    }
  },
  warn: (message: string, meta?: Record<string, unknown>) => {
    if (shouldLog("warn")) {
      // eslint-disable-next-line no-console
      console.warn(format("warn", message, meta));
    }
  },
  error: (message: string, meta?: Record<string, unknown>) => {
    if (shouldLog("error")) {
      // eslint-disable-next-line no-console
      console.error(format("error", message, meta));
    }
  },
};

