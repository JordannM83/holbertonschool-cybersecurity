"""Asynchronous API clients and the on-disk response cache."""

import asyncio
import json
import time
from pathlib import Path

import aiohttp

CACHE_FILE = Path(__file__).resolve().parent / "cache.json"
CACHE_TTL = 60 * 60
UNAVAILABLE = {"error": "Unavailable"}
_CACHE_LOCK = asyncio.Lock()


def _load_cache() -> dict:
    try:
        with open(CACHE_FILE, "r", encoding="utf-8") as cache_file:
            data = json.load(cache_file)
            return data if isinstance(data, dict) else {}
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return {}


def _save_cache(cache: dict) -> None:
    with open(CACHE_FILE, "w", encoding="utf-8") as cache_file:
        json.dump(cache, cache_file, indent=4)
        cache_file.write("\n")


def _cache_parts(url: str):
    parts = url.rstrip("/").split("/")
    return parts[-1], parts[-2] if len(parts) > 1 else "api"


async def fetch_api(session, url: str) -> dict:
    """Fetch JSON data, using a one-hour cache for each IP and API."""
    ip, source = _cache_parts(url)
    now = time.time()

    async with _CACHE_LOCK:
        cache = _load_cache()
        ip_cache = cache.get(ip, {})
        timestamp = ip_cache.get("timestamp", 0)
        cached_data = ip_cache.get("data", {}).get(source)
        if cached_data is not None and now - timestamp < CACHE_TTL:
            return cached_data

    try:
        async with session.get(url) as response:
            if response.status < 200 or response.status >= 300:
                return UNAVAILABLE.copy()
            data = await response.json()
            if not isinstance(data, dict):
                return UNAVAILABLE.copy()

            async with _CACHE_LOCK:
                cache = _load_cache()
                ip_cache = cache.setdefault(ip, {})
                api_data = ip_cache.setdefault("data", {})
                api_data[source] = data
                ip_cache["timestamp"] = time.time()
                _save_cache(cache)
            return data
    except (aiohttp.ClientError, asyncio.TimeoutError, ConnectionError,
            ValueError):
        return UNAVAILABLE.copy()


async def query_virustotal(session, ip: str) -> dict:
    return await fetch_api(session, f"http://localhost:5000/virustotal/{ip}")


async def query_abuseipdb(session, ip: str) -> dict:
    return await fetch_api(session, f"http://localhost:5000/abuseipdb/{ip}")
