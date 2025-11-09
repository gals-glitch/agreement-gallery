import type { PresetRange } from "../lib/dateRange";

export interface TimeRangeOption {
  label: string;
  years: number | null;
  preset?: PresetRange;
}

export const quickRanges: TimeRangeOption[] = [
  { label: "3Y", years: 3, preset: "3Y" },
  { label: "5Y", years: 5, preset: "5Y" },
  { label: "10Y", years: 10, preset: "10Y" },
  { label: "12Y", years: 12, preset: "12Y" },
  { label: "All", years: null, preset: "All" },
  { label: "Custom", years: null },
];
