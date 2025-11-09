import dayjs from "dayjs";

export type PresetRange = "3Y" | "5Y" | "10Y" | "12Y" | "All";

export interface ResolvedRange {
  from: string;
  to: string;
}

const EARLIEST_SUPPORTED = dayjs("1900-01-01");

export const resolvePresetRange = (preset: PresetRange, asOf = dayjs()): ResolvedRange => {
  const to = asOf.startOf("day");

  if (preset === "All") {
    return {
      from: EARLIEST_SUPPORTED.format("YYYY-MM-DD"),
      to: to.format("YYYY-MM-DD"),
    };
  }

  const years = Number(preset.replace("Y", ""));
  const from = to.clone().subtract(years, "year");

  return {
    from: from.format("YYYY-MM-DD"),
    to: to.format("YYYY-MM-DD"),
  };
};

