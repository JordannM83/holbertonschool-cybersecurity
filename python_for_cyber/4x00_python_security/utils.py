#!/usr/bin/env python3

import argparse
import configparser
import pathlib
import sys
import re
import logging
import hashlib


def clean_data(lines: list) -> list:
    clean_lines = []
    for line_number, line in enumerate(lines, start=1):
        logging.debug("Cleaning line %d", line_number)
        line = line.strip()
        if not line:
            continue
        if line.startswith("#"):
            continue
        clean_lines.append(line)
    return clean_lines


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
