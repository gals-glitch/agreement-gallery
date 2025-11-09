const BOM = "\ufeff";

export const exportToCsv = (filename: string, rows: Array<Array<string | number>>) => {
  const csvContent = rows
    .map((cols) =>
      cols
        .map((value) => {
          const cell = value ?? "";
          if (typeof cell === "number") {
            return cell.toString();
          }
          const needsQuotes = /[",\n]/.test(cell);
          const normalized = cell.replace(/"/g, '""');
          return needsQuotes ? `"${normalized}"` : normalized;
        })
        .join(","),
    )
    .join("\n");

  const blob = new Blob([BOM + csvContent], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  URL.revokeObjectURL(url);
};

