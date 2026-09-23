#!/usr/bin/env python3

import argparse
import configparser
import pathlib
import sys
import logging
from utils import hash_password, validate_line, clean_data

LOG_FORMAT = "%(asctime)s - %(levelname)s - %(message)s"
CONFIG_FILE = pathlib.Path(__file__).with_name("config.ini")


def configure_logging() -> None:
    """Send INFO and above to the console and DEBUG and above to the log file."""
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.DEBUG)
    root_logger.handlers.clear()

    formatter = logging.Formatter(LOG_FORMAT)

    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    console.setFormatter(formatter)

    file_handler = logging.FileHandler("breach_check.log")
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(formatter)

    root_logger.addHandler(console)
    root_logger.addHandler(file_handler)


def load_security_config() -> configparser.SectionProxy:
    """Load security settings from config.ini or exit with a clear error."""
    config = configparser.ConfigParser()
    if not config.read(CONFIG_FILE):
        sys.exit("[ERROR] Config file missing: config.ini")
    if "SECURITY" not in config:
        sys.exit("[ERROR] SECURITY section missing")
    return config["SECURITY"]


def check_policy(password: str) -> str:
    """Return WEAK or COMPLIANT according to the password policy."""
    security = load_security_config()
    minimum_length = security.getint("MinLength")
    common_passwords = {
        item.strip().lower()
        for item in security.get("CommonList", "").split(",")
        if item.strip()
    }
    normalized_password = password.lower()

    if (
        len(password) < minimum_length
        or password.isalpha()
        or normalized_password in common_passwords
    ):
        return "WEAK"
    return "COMPLIANT"



def main():
    parser = argparse.ArgumentParser(description="Analyze a file for potential data breach information.")
    parser.add_argument("-f","--file",required=True,type=str,help="Path to the input file to analyze.")
    parser.add_argument("-v","--verbose",action="store_true",help="Enable verbose output.")
    parser.add_argument("-o","--output",type=str,help="Path to the output report file.")
    args = parser.parse_args()
    load_security_config()
    configure_logging()
    logging.info("Processing file: %s", args.file)

    lines = clean_data(read_file(args.file))
    valid_lines = []
    for line_number, line in enumerate(lines, start=1):
        if validate_line(line, line_number):
            valid_lines.append(line)

    logging.info("Processing complete: %d valid record(s)", len(valid_lines))
    if args.output:
        with open(args.output, "w", encoding="utf-8") as report:
            report.write("\n".join(valid_lines))
            report.write("\n" if valid_lines else "")
        logging.info("Report written to %s", args.output)


def read_file(filename: str) -> list:
    try:
        with open(filename, "r", encoding="utf-8") as file:
            return file.readlines()
    except FileNotFoundError:
        logging.error("File not found: %s", filename)
        sys.exit(1)
    except PermissionError:
        logging.error("Permission denied: %s", filename)
        sys.exit(1)



if __name__ == "__main__":
    main()
