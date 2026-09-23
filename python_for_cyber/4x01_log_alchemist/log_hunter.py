#!/usr/bin/env python3

import argparse


def read_stream(file_path: str):
    """Yield one line at a time from *file_path*."""
    try:
        with open(file_path, "r", encoding="utf-8") as log_file:
            for line in log_file:
                yield line
    except FileNotFoundError:
        print(f"[ERROR] File not found: {file_path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("file", help="log file to read")
    args = parser.parse_args()

    print("[*] LogHunter - Log Analysis Engine")
    print(f"[*] Reading: {args.file}")

    lines_read = sum(1 for _ in read_stream(args.file))
    if lines_read == 0:
        print("[!] No data to process. Exiting.")
        return

    print(f"[*] Lines read: {lines_read}")


if __name__ == "__main__":
    main()
