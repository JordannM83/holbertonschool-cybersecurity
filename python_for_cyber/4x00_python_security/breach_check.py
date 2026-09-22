#!/usr/bin/env python3

import argparse
import sys
import re
import logging


LOG_FORMAT = "%(asctime)s - %(levelname)s - %(message)s"
LOGGER = logging.getLogger("breach_check")


def configure_logging() -> None:
    """Send INFO and above to the console and DEBUG and above to the log file."""
    LOGGER.setLevel(logging.DEBUG)
    LOGGER.handlers.clear()

    formatter = logging.Formatter(LOG_FORMAT)

    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    console.setFormatter(formatter)

    file_handler = logging.FileHandler("breach_check.log")
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(formatter)

    LOGGER.addHandler(console)
    LOGGER.addHandler(file_handler)


def main():
    parser = argparse.ArgumentParser(description="Analyze a file for potential data breach information.")
    parser.add_argument("-f","--file",required=True,type=str,help="Path to the input file to analyze.")
    parser.add_argument("-v","--verbose",action="store_true",help="Enable verbose output.")
    parser.add_argument("-o","--output",type=str,help="Path to the output report file.")
    args = parser.parse_args()
    configure_logging()
    LOGGER.info("Processing file: %s", args.file)

    lines = clean_data(read_file(args.file))
    valid_lines = []
    for line_number, line in enumerate(lines, start=1):
        if validate_line(line, line_number):
            valid_lines.append(line)

    LOGGER.info("Processing complete: %d valid record(s)", len(valid_lines))
    if args.output:
        with open(args.output, "w", encoding="utf-8") as report:
            report.write("\n".join(valid_lines))
            report.write("\n" if valid_lines else "")
        LOGGER.info("Report written to %s", args.output)


def read_file(filename: str) -> list:
    try:
        with open(filename, "r", encoding="utf-8") as file:
            return file.readlines()
    except FileNotFoundError:
        LOGGER.error("File not found: %s", filename)
        sys.exit(1)
    except PermissionError:
        LOGGER.error("Permission denied: %s", filename)
        sys.exit(1)



def clean_data(lines: list) -> list:
    clean_lines=[]
    for line_number, line in enumerate(lines, start=1):
        LOGGER.debug("Cleaning line %d", line_number)
        line = line.strip()
        if not line:
            continue
        if line.startswith("#"):
            continue
        clean_lines.append(line)
    return clean_lines



def validate_line(line: str, line_number: int = 0) -> bool:
    pattern = r"^[^@\s:]+@[^@\s:]+\.[^@\s:]+:[^:\s]+$"
    LOGGER.debug("Starting regex check on line %d", line_number)
    valid = re.fullmatch(pattern, line) is not None
    LOGGER.debug("Regex check on line %d: %s", line_number, "valid" if valid else "invalid")
    return valid



if __name__ == "__main__":
    main()
