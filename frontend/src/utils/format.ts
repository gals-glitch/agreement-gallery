import { format } from "date-fns";

const FALLBACK = "—";

const currencyFormatterCache = new Map<string, Intl.NumberFormat>();
const integerFormatter = new Intl.NumberFormat("en-US", { maximumFractionDigits: 0 });
const compactFormatter = new Intl.NumberFormat("en-US", {
  notation: "compact",
  maximumFractionDigits: 1,
});

const getCurrencyFormatter = (currency: string) => {
  if (!currencyFormatterCache.has(currency)) {
    currencyFormatterCache.set(
      currency,
      new Intl.NumberFormat("en-US", {
        style: "currency",
        currency,
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      }),
    );
  }
  return currencyFormatterCache.get(currency)!;
};

export const formatCurrency = (value: number | null | undefined, currency = "USD") => {
  if (value == null || Number.isNaN(value)) {
    return FALLBACK;
  }
  return getCurrencyFormatter(currency).format(value);
};

export const formatPercent = (value: number | null | undefined, fractionDigits = 1) => {
  if (value == null || Number.isNaN(value)) {
    return FALLBACK;
  }
  return `${value.toFixed(fractionDigits)}%`;
};

export const formatNumber = (value: number | null | undefined) => {
  if (value == null || Number.isNaN(value)) {
    return FALLBACK;
  }
  return integerFormatter.format(value);
};

export const formatCompactNumber = (value: number | null | undefined) => {
  if (value == null || Number.isNaN(value)) {
    return FALLBACK;
  }
  return compactFormatter.format(value);
};

export const formatIsoDate = (value: string | undefined) => {
  if (!value) {
    return "";
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }
  return format(date, "MMM d, yyyy");
};

export const formatDelta = (value: number | null | undefined) => {
  if (value == null || Number.isNaN(value)) {
    return null;
  }
  const direction = value >= 0 ? "▲" : "▼";
  return `${direction} ${Math.abs(value).toFixed(1)}%`;
};

