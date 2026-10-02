"""Output helpers for the intelligence broker."""

import json


def save_json_report(dossier, output_path: str) -> None:
    with open(output_path, "w", encoding="utf-8") as report:
        json.dump(dossier.__dict__, report, indent=4)
        report.write("\n")
