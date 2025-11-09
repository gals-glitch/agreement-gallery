export const ensureIsoDate = (value: string): string => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new Error(`Invalid date: ${value}`);
  }
  return date.toISOString().slice(0, 10);
};

export const clampRange = (from: string, to: string): { from: string; to: string } => {
  const start = new Date(from);
  const end = new Date(to);
  if (start > end) {
    return { from: to, to: from };
  }
  return { from: ensureIsoDate(from), to: ensureIsoDate(to) };
};

export const yearKey = (date: string) => date.slice(0, 4);

