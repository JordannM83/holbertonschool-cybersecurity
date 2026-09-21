#!/usr/bin/env python3

import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="Analyze a file for potential data breach information.")
    parser.add_argument("-f","--file",required=True,type=str,help="Path to the input file to analyze.")
    parser.add_argument("-v","--verbose",action="store_true",help="Enable verbose output.")
    parser.add_argument("-o","--output",type=str,help="Path to the output report file.")
    args = parser.parse_args()
    read_file(args.file)


def read_file(filename: str) -> list:
    try :
        with open(filename, "r", encoding="utf-8") as f:
            contenu = f.read()
    except FileNotFoundError:
        sys.exit(f"[ERROR] File not found: {filename}")
    except PermissionError:
        sys.exit(f"[ERROR] Permission denied: {filename}")


if __name__ == "__main__":
    main()
