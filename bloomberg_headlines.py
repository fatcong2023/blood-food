#!/usr/bin/env python3
"""
Bloomberg Top 20 Headlines Scraper

Usage:
    # Without cookies (public headlines):
    python bloomberg_headlines.py

    # With cookies exported from browser (for full subscription access):
    python bloomberg_headlines.py --cookies cookies.json

How to export cookies from Chrome/Edge:
    1. Install the "Cookie-Editor" browser extension
    2. Go to bloomberg.com while logged in
    3. Click the extension → Export → JSON
    4. Save as cookies.json in the same directory as this script

Dependencies:
    pip install playwright
    playwright install chromium
"""

import argparse
import json
import sys
from datetime import datetime

try:
    from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeout
except ImportError:
    print("Missing dependency. Run: pip install playwright && playwright install chromium")
    sys.exit(1)


def load_cookies(path: str) -> list[dict]:
    with open(path) as f:
        raw = json.load(f)

    # Normalize cookies from Cookie-Editor format or Playwright format
    normalized = []
    for c in raw:
        cookie = {
            "name": c["name"],
            "value": c["value"],
            "domain": c.get("domain", ".bloomberg.com"),
            "path": c.get("path", "/"),
        }
        # Cookie-Editor uses "secure" as bool; Playwright expects the same
        if "secure" in c:
            cookie["secure"] = bool(c["secure"])
        if "httpOnly" in c:
            cookie["httpOnly"] = bool(c["httpOnly"])
        if "sameSite" in c:
            # Playwright accepts "Strict", "Lax", "None"
            ss = c["sameSite"]
            if isinstance(ss, str) and ss in ("Strict", "Lax", "None"):
                cookie["sameSite"] = ss
        normalized.append(cookie)
    return normalized


def scrape_headlines(cookies_path: str | None = None, max_headlines: int = 20) -> list[dict]:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/124.0.0.0 Safari/537.36"
            )
        )

        if cookies_path:
            cookies = load_cookies(cookies_path)
            context.add_cookies(cookies)
            print(f"[+] Loaded {len(cookies)} cookies from {cookies_path}")

        page = context.new_page()

        print("[*] Navigating to bloomberg.com ...")
        try:
            page.goto("https://www.bloomberg.com", wait_until="domcontentloaded", timeout=30000)
        except PlaywrightTimeout:
            print("[!] Page load timed out — trying to extract whatever loaded")

        # Wait a moment for lazy-loaded content
        page.wait_for_timeout(3000)

        # Bloomberg renders story cards with various selectors over time.
        # We try several patterns and deduplicate by title.
        selectors = [
            "a[data-component='headline']",
            "a[class*='headline']",
            "h1 a", "h2 a", "h3 a",
            "[data-testid*='story'] a",
            "article a",
            ".story-package-module__story a",
        ]

        seen_titles: set[str] = set()
        headlines: list[dict] = []

        for selector in selectors:
            if len(headlines) >= max_headlines:
                break
            elements = page.query_selector_all(selector)
            for el in elements:
                if len(headlines) >= max_headlines:
                    break
                title = (el.inner_text() or "").strip()
                href = el.get_attribute("href") or ""
                # Filter out nav/footer links and very short strings
                if len(title) < 20:
                    continue
                if title in seen_titles:
                    continue
                seen_titles.add(title)
                url = href if href.startswith("http") else f"https://www.bloomberg.com{href}"
                headlines.append({"title": title, "url": url})

        browser.close()
        return headlines


def main():
    parser = argparse.ArgumentParser(description="Scrape top Bloomberg headlines")
    parser.add_argument(
        "--cookies", metavar="FILE",
        help="Path to cookies JSON exported from your browser (optional)"
    )
    parser.add_argument(
        "--count", type=int, default=20,
        help="Number of headlines to fetch (default: 20)"
    )
    parser.add_argument(
        "--output", metavar="FILE",
        help="Save results to a JSON file instead of printing"
    )
    args = parser.parse_args()

    headlines = scrape_headlines(cookies_path=args.cookies, max_headlines=args.count)

    if not headlines:
        print("[!] No headlines found. Bloomberg may have changed its markup.")
        sys.exit(1)

    if args.output:
        result = {
            "scraped_at": datetime.now().isoformat(),
            "count": len(headlines),
            "headlines": headlines,
        }
        with open(args.output, "w") as f:
            json.dump(result, f, indent=2, ensure_ascii=False)
        print(f"[+] Saved {len(headlines)} headlines to {args.output}")
    else:
        print(f"\n=== Bloomberg Top {len(headlines)} Headlines ({datetime.now().strftime('%Y-%m-%d %H:%M')}) ===\n")
        for i, h in enumerate(headlines, 1):
            print(f"{i:2}. {h['title']}")
            print(f"    {h['url']}\n")


if __name__ == "__main__":
    main()
