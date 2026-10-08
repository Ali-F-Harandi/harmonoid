#!/usr/bin/env python3
"""
Recover Harmonoid's external dependencies from the Software Heritage archive.

The upstream harmonoid GitHub organization turned the external/* submodule
repositories private, which makes this repository impossible to build as-is.
The full git history of each of those repositories, including the exact
commits pinned by this repository, is still available through the public
Software Heritage archive.

This script walks the archived directory tree of each pinned commit through
the Software Heritage REST API (read-only GET endpoints) and writes every
file back to disk, effectively "un-submoduling" the dependencies so the
project can be built from a plain checkout.

The public localizations repository is cloned directly from GitHub.

Usage:
    python3 scripts/recover_external_deps.py [--interval 0.7] [--only path,...]
"""

import argparse
import io
import json
import os
import shutil
import subprocess
import sys
import tarfile
import time
import urllib.error
import urllib.request

SH_BASE = "https://archive.softwareheritage.org"
API = f"{SH_BASE}/api/1"

# repository path -> pinned commit (from the former .gitmodules gitlinks)
PINNED = {
    "external/adaptive_layouts": "e04662f5c54dca8031318dbe8cea5b0d18457d03",
    "external/identity": "3da4d6a4e3e136451dc73476a74ab8f029f86114",
    "external/lastfm": "1d03ea02503056badaa2a80d8be81e6d6084a82f",
    "external/media_library": "dd76c9ab69bdf2151543023173be15f4d68d9cc3",
    "external/smtc-win32": "7b005eafe00fc7171f5cd8a06e0ef26fef2e9d70",
    "external/tag_reader": "b8478a02bdc691fc0ea1ffb177dd141fe3a2c197",
    "external/taglib": "d11c12257ee89607b05fb738bfc33d3fce114d86",
    "lib/private": "ad7d14241ab35f097220a2e4e41340749230822b",
}

LOCALIZATIONS_URL = "https://github.com/harmonoid/localizations.git"
LOCALIZATIONS_REF = "2da20983c27d6b2c962abc2a95190f62860fb1b4"

UA = "harmonoid-dependency-recovery/1.0 (GitHub Actions CI)"

REQUEST_INTERVAL = 0.7


class Blocked(Exception):
    """An anti-bot layer (e.g. Anubis) served an HTML page instead of JSON."""


def log(message):
    print(message, flush=True)


def fetch(url, binary=False, retries=5):
    last_error = None
    for attempt in range(1, retries + 1):
        time.sleep(REQUEST_INTERVAL)
        request = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
        try:
            with urllib.request.urlopen(request, timeout=90) as response:
                data = response.read()
            if not binary and data[:64].lstrip().startswith(b"<!doctype html"):
                raise Blocked(url)
            return data
        except Blocked:
            raise
        except urllib.error.HTTPError as error:
            last_error = error
            if error.code in (429, 500, 502, 503, 504):
                wait = min(20 * attempt, 90)
                log(f"    HTTP {error.code}; retrying in {wait}s ({attempt}/{retries})")
                time.sleep(wait)
                continue
            raise
        except Exception as error:  # noqa: BLE001
            last_error = error
            log(f"    {type(error).__name__}: {error}; retrying ({attempt}/{retries})")
            time.sleep(10)
    raise RuntimeError(f"giving up on {url}: {last_error}")


def get_json(path_or_url):
    url = path_or_url if path_or_url.startswith("http") else f"{SH_BASE}{path_or_url}"
    return json.loads(fetch(url).decode("utf-8"))


def try_vault(sha, destination):
    """Fast path: use an already-cooked vault flat bundle when available."""
    try:
        info = get_json(f"{API}/vault/flat/{sha}/")
    except (Blocked, urllib.error.HTTPError, RuntimeError):
        return False
    if not isinstance(info, dict) or info.get("status") != "done":
        return False
    url = info.get("download_url")
    if not url:
        return False
    if url.startswith("/"):
        url = f"{SH_BASE}{url}"
    log("    vault bundle already cooked; downloading")
    try:
        data = fetch(url, binary=True)
    except Exception as error:  # noqa: BLE001
        log(f"    vault download failed ({error}); falling back to tree walk")
        return False
    shutil.rmtree(destination, ignore_errors=True)
    os.makedirs(destination, exist_ok=True)
    with tarfile.open(fileobj=io.BytesIO(data), mode="r:*") as archive:
        members = [m for m in archive.getmembers() if m.isfile() or m.isdir()]
        tops = {m.name.split("/")[0] for m in members if m.name not in ("", ".")}
        strip = 1 if len(members) > 1 and len(tops) == 1 else 0
        for member in members:
            parts = [p for p in member.name.split("/")[strip:] if p not in ("", ".")]
            if not parts:
                continue
            out = os.path.join(destination, *parts)
            if member.isdir():
                os.makedirs(out, exist_ok=True)
            else:
                os.makedirs(os.path.dirname(out) or destination, exist_ok=True)
                with open(out, "wb") as handle:
                    handle.write(archive.extractfile(member).read())
    return True


def walk_directory(directory_url, destination, stats):
    entries = get_json(directory_url)
    for entry in entries:
        name = entry["name"]
        path = os.path.join(destination, name)
        if entry["type"] == "dir":
            os.makedirs(path, exist_ok=True)
            walk_directory(entry.get("target_url") or f"{API}/directory/{entry['target']}/", path, stats)
        elif entry["type"] == "file":
            content_url = entry.get("target_url") or f"{API}/content/sha1_git:{entry['target']}/"
            if content_url.startswith("/"):
                content_url = f"{SH_BASE}{content_url}"
            if not content_url.endswith("/"):
                content_url += "/"
            raw = fetch(f"{content_url}raw/", binary=True)
            os.makedirs(os.path.dirname(path) or destination, exist_ok=True)
            with open(path, "wb") as handle:
                handle.write(raw)
            stats["files"] += 1
            stats["bytes"] += len(raw)
        elif entry["type"] == "rev":
            log(f"    WARNING: nested gitlink '{name}' cannot be recovered from the archive")


def recover_one(relative_path, sha):
    destination = os.path.abspath(relative_path)
    log(f"==> {relative_path} @ {sha[:12]}")
    stats = {"files": 0, "bytes": 0}
    if try_vault(sha, destination):
        for root, _, files in os.walk(destination):
            stats["files"] += len(files)
            stats["bytes"] += sum(os.path.getsize(os.path.join(root, name)) for name in files)
        log(f"    vault: {stats['files']} files, {stats['bytes'] / 1e6:.2f} MB")
        return stats
    revision = get_json(f"{API}/revision/{sha}/")
    root_directory = revision.get("directory")
    if not root_directory:
        raise RuntimeError(f"revision {sha} exposes no directory")
    shutil.rmtree(destination, ignore_errors=True)
    os.makedirs(destination, exist_ok=True)
    walk_directory(f"{API}/directory/{root_directory}/", destination, stats)
    log(f"    walked: {stats['files']} files, {stats['bytes'] / 1e6:.2f} MB")
    return stats


def recover_localizations():
    log("==> assets/localizations (public repository)")
    temporary = "/tmp/localizations-clone"
    shutil.rmtree(temporary, ignore_errors=True)
    subprocess.run(["git", "clone", "--no-checkout", LOCALIZATIONS_URL, temporary], check=True)
    subprocess.run(["git", "checkout", LOCALIZATIONS_REF], cwd=temporary, check=True)
    destination = os.path.abspath("assets/localizations")
    shutil.rmtree(destination, ignore_errors=True)
    os.makedirs(destination, exist_ok=True)
    for entry in os.listdir(temporary):
        if entry == ".git":
            continue
        source = os.path.join(temporary, entry)
        if os.path.isdir(source):
            shutil.copytree(source, os.path.join(destination, entry))
        else:
            shutil.copy2(source, os.path.join(destination, entry))
    count = sum(len(files) for _, _, files in os.walk(destination))
    log(f"    copied {count} files")
    return count


EXPECTED = {
    "external/adaptive_layouts": ["pubspec.yaml"],
    "external/identity": ["pubspec.yaml"],
    "external/lastfm": ["pubspec.yaml"],
    "external/media_library": ["pubspec.yaml"],
    "external/smtc-win32": ["smtc-win32.sln", "bindings/system_media_transport_controls/pubspec.yaml"],
    "external/tag_reader": ["pubspec.yaml"],
    "external/taglib": ["taglib/pubspec.yaml", "taglib_libs/pubspec.yaml"],
    "lib/private": None,
    "assets/localizations": ["index.json"],
}


def validate():
    failures = []
    for path, markers in EXPECTED.items():
        if not os.path.isdir(path) or not os.listdir(path):
            failures.append(f"{path}: missing or empty")
            continue
        for marker in markers or []:
            if not os.path.exists(os.path.join(path, marker)):
                failures.append(f"{path}: expected '{marker}' not found")
        if os.path.exists(os.path.join(path, ".gitmodules")):
            failures.append(f"{path}: contains a nested .gitmodules (needs manual handling)")
    if os.path.isdir("lib/private") and os.listdir("lib/private"):
        dart_files = [name for name in os.listdir("lib/private") if name.endswith(".dart")]
        if not dart_files and not os.path.exists(os.path.join("lib/private", "lib")):
            failures.append("lib/private: no dart sources found")
    else:
        failures.append("lib/private: missing or empty")
    return failures


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--interval", type=float, default=0.7, help="seconds between API requests")
    parser.add_argument("--only", help="comma separated repository paths to recover")
    parser.add_argument("--skip-localizations", action="store_true")
    arguments = parser.parse_args()

    global REQUEST_INTERVAL
    REQUEST_INTERVAL = arguments.interval

    targets = dict(PINNED)
    if arguments.only:
        keep = {item.strip() for item in arguments.only.split(",")}
        targets = {key: value for key, value in targets.items() if key in keep}

    errors = []
    for relative_path, sha in targets.items():
        try:
            recover_one(relative_path, sha)
        except Exception as error:  # noqa: BLE001
            log(f"    FAILED: {type(error).__name__}: {error}")
            errors.append(relative_path)

    if not arguments.skip_localizations:
        try:
            recover_localizations()
        except Exception as error:  # noqa: BLE001
            log(f"    FAILED: {error}")
            errors.append("assets/localizations")

    failures = validate()
    if errors or failures:
        log("RECOVERY INCOMPLETE")
        for item in errors:
            log(f"  error: {item}")
        for item in failures:
            log(f"  validation: {item}")
        sys.exit(1)
    log("RECOVERY OK")


if __name__ == "__main__":
    main()
