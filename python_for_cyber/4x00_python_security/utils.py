#!/usr/bin/env python3

import argparse
import configparser
import pathlib
import sys
import re
import logging
import hashlib


def read_file(filename: str):
    """Yield one line at a time instead of loading the whole file into RAM."""
    try:
        with open(filename, "r", encoding="utf-8") as file:
            for line in file:
                yield line
    except FileNotFoundError:
        logging.error("File not found: %s", filename)
        sys.exit(1)
    except PermissionError:
        logging.error("Permission denied: %s", filename)
        sys.exit(1)


def clean_data(lines):
    for line_number, line in enumerate(lines, start=1):
        logging.debug("Cleaning line %d", line_number)
        line = line.strip()
        if not line:
            continue
        if line.startswith("#"):
            continue
        yield line


def validate_line(line: str, line_number: int = 0) -> bool:
    pattern = r"^[^@\s:]+@[^@\s:]+\.[^@\s:]+:[^:\s]+$"
    logging.debug("Starting regex check on line %d", line_number)
    valid = re.fullmatch(pattern, line) is not None
    logging.debug("Regex check on line %d: %s", line_number,
                  "valid" if valid else "invalid")
    return valid


def hash_password(password: str, salt: str) -> str:
    """Return the SHA-256 hexdigest of the password with its salt appended."""
    salted_password = (password + salt).encode("utf-8")
    return hashlib.sha256(salted_password).hexdigest()
