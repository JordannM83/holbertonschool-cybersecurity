#!/usr/bin/env python3
"""Unit tests for the breach-checking helpers."""

import unittest

from breach_check import check_policy, hash_password, validate_line


class TestValidateLine(unittest.TestCase):
    def test_valid_email_and_password(self):
        self.assertTrue(validate_line("alice@example.com:StrongPass1!"))

    def test_invalid_format(self):
        self.assertFalse(validate_line("alice@example.com-StrongPass1!"))

    def test_missing_parts(self):
        self.assertFalse(validate_line("alice@example.com:"))
        self.assertFalse(validate_line("alice@example.com"))
        self.assertFalse(validate_line(":StrongPass1!"))


class TestCheckPolicy(unittest.TestCase):
    def test_short_password(self):
        self.assertEqual(check_policy("a1!"), "WEAK")

    def test_numeric_password(self):
        self.assertEqual(check_policy("12345678"), "WEAK")

    def test_compliant_password(self):
        self.assertEqual(check_policy("StrongPass1!"), "COMPLIANT")


class TestHashPassword(unittest.TestCase):
    def test_same_input_has_same_hash(self):
        first_hash = hash_password("StrongPass1!", "test-salt")
        second_hash = hash_password("StrongPass1!", "test-salt")
        self.assertEqual(first_hash, second_hash)


if __name__ == "__main__":
    unittest.main()
