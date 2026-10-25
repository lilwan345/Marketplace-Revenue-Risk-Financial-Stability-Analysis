"""Copy the data/*.csv marts into dashboard.html's inline `fallback` object.

dashboard.html fetches data/*.csv, and falls back to an inline copy when the
fetch fails (for example when the file is opened straight from disk). This
keeps that copy identical to the CSVs, so both paths show the same numbers.

Run from the repo root after changing anything in data/:
    python3 tools/sync_dashboard_fallback.py
"""
import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DASHBOARD = ROOT / "dashboard.html"
KEYS = ["kpi_summary", "monthly_revenue", "state_revenue", "customer_decile_summary",
        "customer_lorenz_curve", "payment_summary", "installment_distribution", "action_plan"]
LORENZ_STEP = 10  # 1,000 Lorenz points -> every 10th (101 points) is plenty for the chart


def value(text):
    # "NA" stays a string, exactly as the fetched CSV delivers it, so both paths
    # go through the same Number.isFinite filters in the page.
    if text == "":
        return None
    try:
        number = float(text)
    except ValueError:
        return text
    return int(number) if number.is_integer() and "." not in text else number


def rows(key):
    with open(ROOT / "data" / f"{key}.csv", newline="", encoding="utf-8") as f:
        data = [{k: value(v) for k, v in row.items()} for row in csv.DictReader(f)]
    if key == "customer_lorenz_curve":
        data = data[::LORENZ_STEP] + ([data[-1]] if (len(data) - 1) % LORENZ_STEP else [])
    return data


def main():
    lines = ["    const fallback = {"]
    for i, key in enumerate(KEYS):
        body = ",\n".join(f"        {json.dumps(r, ensure_ascii=False)}" for r in rows(key))
        lines.append(f"      {key}: [\n{body}\n      ]" + ("," if i < len(KEYS) - 1 else ""))
    lines.append("    };")
    block = "\n".join(lines)

    html = DASHBOARD.read_text(encoding="utf-8")
    new, n = re.subn(r"    const fallback = \{.*?\n    \};", lambda m: block, html, count=1, flags=re.S)
    if n != 1:
        raise SystemExit("could not find the fallback block in dashboard.html")
    DASHBOARD.write_text(new, encoding="utf-8")
    print(f"synced {len(KEYS)} datasets into {DASHBOARD.name}")


if __name__ == "__main__":
    main()
