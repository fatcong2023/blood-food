#!/usr/bin/env python3
"""
Bloomberg Article Downloader

Downloads the top N full articles from Bloomberg using either:
  (a) email/password login  ← simplest
  (b) cookies exported from your browser

Setup:
    pip install playwright
    playwright install chromium

Usage:
    # Login with email/password (reads password securely from terminal prompt):
    python bloomberg_headlines.py --email you@example.com

    # Or supply password via env var (good for scripting):
    BLOOMBERG_PASSWORD="yourpassword" python bloomberg_headlines.py --email you@example.com

    # Or use exported cookies instead:
    python bloomberg_headlines.py --cookies cookies.json

    # More options:
    python bloomberg_headlines.py --email you@example.com --count 10 --out ~/reading/
"""

import argparse
import getpass
import json
import os
import re
import sys
import time
from datetime import datetime
from pathlib import Path

try:
    from playwright.sync_api import sync_playwright, TimeoutError as PWTimeout
except ImportError:
    sys.exit("Missing dependency. Run:\n  pip install playwright && playwright install chromium")


# ── Login ─────────────────────────────────────────────────────────────────────

def login(page, email: str, password: str, visible: bool = False) -> bool:
    """Log in to Bloomberg with email/password. Returns True on success."""
    print("[*] Logging in to Bloomberg …")

    # Bloomberg's login redirects through their SSO — go via the main site
    login_urls = [
        "https://www.bloomberg.com/account/signin",
        "https://login.bloomberg.com/login",
    ]

    for url in login_urls:
        try:
            page.goto(url, wait_until="domcontentloaded", timeout=30_000)
            page.wait_for_timeout(3_000)
            # Print current URL so we know where we ended up
            print(f"  [*] Landed on: {page.url}")
            break
        except PWTimeout:
            continue

    # Dump all input fields so we can debug if needed
    inputs = page.query_selector_all("input")
    input_info = [(el.get_attribute("type"), el.get_attribute("name"), el.get_attribute("id")) for el in inputs]
    if not any(t in ("email", "text", None) for t, _, _ in input_info):
        print(f"  [!] Inputs on page: {input_info}")

    # Fill email — try broad set of selectors
    email_sel = (
        "input[type='email'],"
        "input[name='email'],"
        "input[name='username'],"
        "input[id*='email'],"
        "input[id*='username'],"
        "input[placeholder*='email' i],"
        "input[placeholder*='Email' i]"
    )
    try:
        page.wait_for_selector(email_sel, timeout=10_000)
        page.fill(email_sel, email)
        print("  [+] Filled email")
    except Exception:
        print(f"  [!] Could not find email field. Current URL: {page.url}")
        print(f"  [!] Inputs found: {input_info}")
        if not visible:
            print("  [!] Try running with --visible to watch the browser and see what's happening")
        return False

    # Click Next/Continue if present (some flows split email + password across two screens)
    for btn_text in ("Next", "Continue", "Sign In", "Log In"):
        btn = page.query_selector(f"button:has-text('{btn_text}')")
        if btn:
            btn.click()
            page.wait_for_timeout(2_000)
            break

    # Fill password
    pw_sel = "input[type='password'], input[name='password']"
    try:
        page.wait_for_selector(pw_sel, timeout=10_000)
        page.fill(pw_sel, password)
        print("  [+] Filled password")
    except Exception:
        print(f"  [!] Could not find password field. Current URL: {page.url}")
        return False

    # Submit
    submit = page.query_selector(
        "button[type='submit'],"
        "button:has-text('Sign In'),"
        "button:has-text('Log In'),"
        "button:has-text('Continue')"
    )
    if submit:
        submit.click()
    else:
        page.keyboard.press("Enter")

    # Wait for redirect away from login page
    try:
        page.wait_for_url(re.compile(r"bloomberg\.com(?!.*(login|signin))"), timeout=15_000)
    except PWTimeout:
        pass

    page.wait_for_timeout(3_000)
    print(f"  [*] After login URL: {page.url}")

    body = page.inner_text("body")
    if "Sign In" in body[:500] or "Log In" in body[:500]:
        print("[!] Login may have failed — still seeing login prompt")
        return False

    print("[+] Logged in successfully")
    return True


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

def get_article_links(page, limit: int, debug: bool = False) -> list[dict]:
    print("[*] Loading bloomberg.com homepage …")
    try:
        page.goto("https://www.bloomberg.com", wait_until="domcontentloaded", timeout=30_000)
    except PWTimeout:
        print("[!] Homepage load timed out — will try with whatever rendered")

    page.wait_for_timeout(4_000)

    # Scroll down to trigger lazy-loading of more story cards
    for _ in range(3):
        page.mouse.wheel(0, 3000)
        page.wait_for_timeout(1_000)

    if debug:
        page.screenshot(path="debug_homepage.png", full_page=True)
        Path("debug_homepage.html").write_text(page.content(), encoding="utf-8")
        print("  [debug] saved debug_homepage.png and debug_homepage.html")

    # Bloomberg article URLs follow predictable patterns. Grab every <a> whose
    # href looks like an article, which is far more robust than CSS classes.
    article_re = re.compile(r"/(news/articles|news/features|opinion|news/newsletters)/")

    seen_urls:   set[str] = set()
    seen_titles: set[str] = set()
    results: list[dict]   = []

    anchors = page.query_selector_all("a[href]")
    print(f"  [*] Scanning {len(anchors)} links on the page …")

    for el in anchors:
        if len(results) >= limit:
            break
        href = el.get_attribute("href") or ""
        if not article_re.search(href):
            continue
        url = href if href.startswith("http") else f"https://www.bloomberg.com{href}"
        if "bloomberg.com" not in url:
            continue
        if url in seen_urls:
            continue
        title = (el.inner_text() or "").strip()
        # Link text can be empty (image links); fall back to aria-label / the URL slug
        if len(title) < 15:
            title = (el.get_attribute("aria-label") or "").strip()
        if len(title) < 15:
            # derive from slug as last resort
            slug = href.rstrip("/").split("/")[-1].replace("-", " ")
            title = slug[:80]
        if title in seen_titles:
            continue
        seen_urls.add(url)
        seen_titles.add(title)
        results.append({"title": title, "url": url})

    return results


# ── Article page: extract full text ──────────────────────────────────────────

def extract_article(page, url: str) -> dict | None:
    try:
        page.goto(url, wait_until="domcontentloaded", timeout=30_000)
    except PWTimeout:
        print(f"  [!] Timed out: {url}")
        return None

    page.wait_for_timeout(2_500)

    def text(sel: str) -> str:
        el = page.query_selector(sel)
        return (el.inner_text() if el else "").strip()

    def texts(sel: str) -> list[str]:
        return [e.inner_text().strip() for e in page.query_selector_all(sel) if e.inner_text().strip()]

    title = (
        text("[data-component='headline']")
        or text("h1[class*='headline']")
        or text("h1")
    )

    subtitle = (
        text("[data-component='summary-text']")
        or text("[class*='summary']")
        or text("[class*='subtitle']")
        or text("[class*='deck']")
    )

    author_els = texts("[data-component='byline'] a") or texts("[class*='author'] a") or texts("[rel='author']")
    authors = ", ".join(author_els)

    pub_time = (
        text("time[datetime]")
        or text("[class*='published']")
        or text("[data-component='publish-time']")
    )

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

    page_text = page.inner_text("body")
    paywalled = (
        not paragraphs
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
    slug = re.sub(r"\s+", "_", slug)
    return slug[:80]


def save_article(article: dict, out_dir: Path, index: int) -> Path:
    fname = f"{index:02d}_{safe_filename(article['title'])}.txt"
    path  = out_dir / fname

    lines = [article["title"], "=" * len(article["title"])]
    if article["subtitle"]:
        lines += [article["subtitle"], ""]
    if article["authors"]:
        lines += [f"By {article['authors']}"]
    if article["time"]:
        lines += [article["time"]]
    lines += [article["url"], "", "─" * 60, ""]

    if article["paywalled"]:
        lines += ["[PAYWALL — login may have failed or session expired]"]
    else:
        lines += [article["body"]]

    path.write_text("\n".join(lines), encoding="utf-8")
    return path


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(description="Download full Bloomberg articles to text files")

    auth = ap.add_mutually_exclusive_group(required=True)
    auth.add_argument("--email",   metavar="EMAIL",
                      help="Your Bloomberg login email (password will be prompted, or set BLOOMBERG_PASSWORD env var)")
    auth.add_argument("--cookies", metavar="FILE",
                      help="cookies.json exported from your browser while logged in to bloomberg.com")

    ap.add_argument("--count", type=int, default=20,
                    help="Number of articles to fetch (default: 20)")
    ap.add_argument("--out",   default="bloomberg_articles",
                    help="Output folder (default: bloomberg_articles/)")
    ap.add_argument("--visible", action="store_true",
                    help="Show the browser window (useful for debugging login issues)")
    ap.add_argument("--debug", action="store_true",
                    help="Save a screenshot + HTML of the homepage to diagnose extraction issues")
    args = ap.parse_args()

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=not args.visible)
        context = browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/124.0.0.0 Safari/537.36"
            ),
            viewport={"width": 1280, "height": 900},
        )

        page = context.new_page()

        if args.cookies:
            cookies = load_cookies(args.cookies)
            context.add_cookies(cookies)
            print(f"[+] Loaded {len(cookies)} cookies from {args.cookies}")
            page.goto("https://www.bloomberg.com", wait_until="domcontentloaded", timeout=30_000)
            page.wait_for_timeout(2_000)
        else:
            # Password: env var → terminal prompt (never hardcode)
            password = os.environ.get("BLOOMBERG_PASSWORD") or getpass.getpass("Bloomberg password: ")
            ok = login(page, args.email, password, visible=args.visible)
            if not ok:
                browser.close()
                sys.exit(1)

        links = get_article_links(page, args.count, debug=args.debug)
        if not links:
            browser.close()
            sys.exit(
                "[!] Could not find any articles on the homepage.\n"
                "    Re-run with --debug to save debug_homepage.png/.html so we can see\n"
                "    what the page actually returned (often a bot-check or consent wall)."
            )
        print(f"[+] Found {len(links)} articles\n")

        saved = []
        for i, link in enumerate(links, 1):
            print(f"[{i}/{len(links)}] {link['title'][:70]} …")
            article = extract_article(page, link["url"])
            if article is None:
                print("  → skipped (load error)")
                continue
            if article["paywalled"]:
                print("  → [paywall]")
            else:
                print(f"  → {len(article['body'].split())} words")
            path = save_article(article, out_dir, i)
            saved.append(str(path))
            time.sleep(1)

        browser.close()

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
