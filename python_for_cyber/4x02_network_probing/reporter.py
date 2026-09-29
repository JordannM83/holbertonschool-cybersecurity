"""Report output helpers."""

import json


def save_json_report(results: list, output_path: str) -> None:
    """Write scan results as an indented JSON report."""
    with open(output_path, "w", encoding="utf-8") as output_file:
        json.dump(results, output_file, indent=2)
        output_file.write("\n")
