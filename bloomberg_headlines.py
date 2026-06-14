#!/usr/bin/env python3
"""
Bloomberg Article Downloader

Logs in via your browser cookies, grabs the top N articles from the
Bloomberg homepage, and saves each article's full text to a local folder.

Setup:
    pip install playwright
    playwright install chromium

Export cookies (do this while logged in to bloomberg.com):
    1. Install "Cookie-Editor" in Chrome/Edge/Firefox
    2. Go to bloomberg.com
    3. Click extension → Export → JSON
    4. Save as cookies.json

Usage:
    python bloomberg_headlines.py --cookies cookies.json
    python bloomberg_headlines.py --cookies cookies.json --count 10 --out articles/
"""

import argparse
import json
import re
import sys
import time
from datetime import datetime
from pathlib import Path

try:
    from playwright.sync_api import sync_playwright, TimeoutError as PWTimeout
except ImportError:
    sys.exit("Missing dependency. Run:\n  pip install playwright && playwright install chromium")


# ── Cookie helpers ────────────────────────────────────────────────────────────

def load_cookies(path: str) -> list[dict]:
    with open(path) as f:
        raw = json.load(f)
    out = []
    for c in raw:
        cookie: dict = {
            "name":   c["name"],
            "value":  c["value"],
            "domain": c.get("domain", ".bloomberg.com"),
            "path":   c.get("path", "/"),
        }
        if "secure"   in c: cookie["secure"]   = bool(c["secure"])
        if "httpOnly" in c: cookie["httpOnly"]  = bool(c["httpOnly"])
        ss = c.get("sameSite")
        if isinstance(ss, str) and ss in ("Strict", "Lax", "None"):
            cookie["sameSite"] = ss
        out.append(cookie)
    return out


# ── Homepage: collect article links ──────────────────────────────────────────

def get_article_links(page, limit: int) -> list[dict]:
    """Return up to `limit` {title, url} dicts from the Bloomberg homepage."""
    print("[*] Loading bloomberg.com homepage …")
    try:
        page.goto("https://www.bloomberg.com", wait_until="domcontentloaded", timeout=30_000)
    except PWTimeout:
        print("[!] Homepage load timed out — will try with whatever rendered")

    page.wait_for_timeout(3_000)   # let JS settle

    # Try broad selectors in priority order; deduplicate by URL.
    selectors = [
        "a[data-component='headline']",
        "a[class*='headline']",
        "h1 a", "h2 a", "h3 a",
        "[data-testid*='story'] a",
        "article a",
    ]

    seen_urls:   set[str]  = set()
    seen_titles: set[str]  = set()
    results: list[dict]    = []

    for sel in selectors:
        if len(results) >= limit:
            break
        for el in page.query_selector_all(sel):
            if len(results) >= limit:
                break
            title = (el.inner_text() or "").strip()
            href  = el.get_attribute("href") or ""
            if len(title) < 20:
                continue
            url = href if href.startswith("http") else f"https://www.bloomberg.com{href}"
            # Keep only bloomberg.com article paths
            if "bloomberg.com" not in url:
                continue
            if url in seen_urls or title in seen_titles:
                continue
            seen_urls.add(url)
            seen_titles.add(title)
            results.append({"title": title, "url": url})

    return results


# ── Article page: extract full text ──────────────────────────────────────────

def extract_article(page, url: str) -> dict | None:
    """Navigate to an article and return {title, subtitle, body, url, authors, time}."""
    try:
        page.goto(url, wait_until="domcontentloaded", timeout=30_000)
    except PWTimeout:
        print(f"  [!] Timed out: {url}")
        return None

    # Extra wait for dynamic content / anti-bot checks
    page.wait_for_timeout(2_500)

    def text(sel: str) -> str:
        el = page.query_selector(sel)
        return (el.inner_text() if el else "").strip()

    def texts(sel: str) -> list[str]:
        return [e.inner_text().strip() for e in page.query_selector_all(sel) if e.inner_text().strip()]

    # ── Title ────────────────────────────────────────────────────────────────
    title = (
        text("[data-component='headline']")
        or text("h1[class*='headline']")
        or text("h1")
    )

    # ── Subtitle / deck ──────────────────────────────────────────────────────
    subtitle = (
        text("[data-component='summary-text']")
        or text("[class*='summary']")
        or text("[class*='subtitle']")
        or text("[class*='deck']")
    )

    # ── Authors ──────────────────────────────────────────────────────────────
    author_els = texts("[data-component='byline'] a") or texts("[class*='author'] a") or texts("[rel='author']")
    authors = ", ".join(author_els)

    # ── Publish time ─────────────────────────────────────────────────────────
    pub_time = (
        text("time[datetime]")
        or text("[class*='published']")
        or text("[data-component='publish-time']")
    )

    # ── Body paragraphs ──────────────────────────────────────────────────────
    body_selectors = [
        "[data-component='body-text'] p",
        "[class*='body-content'] p",
        "[class*='article-body'] p",
        "article p",
        ".paywall p",
    ]
    paragraphs: list[str] = []
    for bsel in body_selectors:
        paragraphs = [p for p in texts(bsel) if len(p) > 30]
        if paragraphs:
            break

    # Detect paywall
    page_text = page.inner_text("body")
    paywalled = (
        not paragraphs
        or "Subscribe" in page_text[:500]
        or len("\n".join(paragraphs)) < 200
    )

    return {
        "title":     title,
        "subtitle":  subtitle,
        "authors":   authors,
        "time":      pub_time,
        "url":       url,
        "paywalled": paywalled,
        "body":      "\n\n".join(paragraphs),
    }


# ── Save helpers ──────────────────────────────────────────────────────────────

def safe_filename(title: str) -> str:
    slug = re.sub(r"[^\w\s-]", "", title).strip()
    slug = re.sub(r"[\s]+", "_", slug)
    return slug[:80]


def save_article(article: dict, out_dir: Path, index: int):
    fname = f"{index:02d}_{safe_filename(article['title'])}.txt"
    path  = out_dir / fname

    lines = [
        article["title"],
        "=" * len(article["title"]),
    ]
    if article["subtitle"]:
        lines += [article["subtitle"], ""]
    if article["authors"]:
        lines += [f"By {article['authors']}"]
    if article["time"]:
        lines += [article["time"]]
    lines += [article["url"], "", "─" * 60, ""]

    if article["paywalled"]:
        lines += ["[PAYWALL — cookies may have expired or article requires login]"]
    else:
        lines += [article["body"]]

    path.write_text("\n".join(lines), encoding="utf-8")
    return path


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(description="Download full Bloomberg articles to text files")
    ap.add_argument("--cookies", metavar="FILE", required=True,
                    help="cookies.json exported from your browser while logged in to bloomberg.com")
    ap.add_argument("--count",   type=int, default=20,
                    help="Number of articles to fetch (default: 20)")
    ap.add_argument("--out",     default="bloomberg_articles",
                    help="Output folder (default: bloomberg_articles/)")
    args = ap.parse_args()

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/124.0.0.0 Safari/537.36"
            ),
            viewport={"width": 1280, "height": 900},
        )

        cookies = load_cookies(args.cookies)
        context.add_cookies(cookies)
        print(f"[+] Loaded {len(cookies)} cookies")

        page = context.new_page()

        # Step 1: collect article links
        links = get_article_links(page, args.count)
        if not links:
            sys.exit("[!] Could not find any articles on the homepage.")
        print(f"[+] Found {len(links)} articles\n")

        # Step 2: fetch each article
        saved = []
        for i, link in enumerate(links, 1):
            print(f"[{i}/{len(links)}] {link['title'][:70]} …")
            article = extract_article(page, link["url"])
            if article is None:
                print("  → skipped (load error)")
                continue
            if article["paywalled"]:
                print("  → ⚠️  paywall detected — cookies may need refresh")
            else:
                words = len(article["body"].split())
                print(f"  → {words} words")
            path = save_article(article, out_dir, i)
            saved.append(str(path))
            time.sleep(1)   # be polite

        browser.close()

    # Step 3: summary index
    index_path = out_dir / "00_index.txt"
    with open(index_path, "w") as f:
        f.write(f"Bloomberg Articles — {datetime.now().strftime('%Y-%m-%d %H:%M')}\n")
        f.write("=" * 50 + "\n\n")
        for i, link in enumerate(links, 1):
            f.write(f"{i:2}. {link['title']}\n    {link['url']}\n\n")

    print(f"\n[✓] Done. {len(saved)} articles saved to '{args.out}/'")
    print(f"    Index: {index_path}")


if __name__ == "__main__":
    main()
