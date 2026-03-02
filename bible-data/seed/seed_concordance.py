#!/usr/bin/env python3
"""
Seed script: Parse STEPBible data → upload to Supabase concordance tables.

Usage:
    pip install supabase
    python seed_concordance.py

Required env vars (or edit the constants below):
    SUPABASE_URL        e.g. https://byrqbwsgwhljpagphwqy.supabase.co
    SUPABASE_SERVICE_KEY  (service_role key — NOT anon key)

Run concordance_schema.sql in Supabase SQL editor FIRST.
"""

import os, re, sys
from pathlib import Path

try:
    from supabase import create_client
except ImportError:
    sys.exit("Install supabase-py first:  pip install supabase")

# ── Config ────────────────────────────────────────────────────────────────────
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://byrqbwsgwhljpagphwqy.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")   # MUST be service_role key
BATCH_SIZE   = 500

BASE = Path(__file__).parent.parent / "STEPBible-Data-master"
TTESV_PATH = BASE / "Tagged-Bibles" / "TTESV - Tyndale Translation tags for ESV - TyndaleHouse.com STEPBible.org CC BY-NC.txt"
TBESH_PATH = BASE / "Lexicons" / "TBESH - Translators Brief lexicon of Extended Strongs for Hebrew - STEPBible.org CC BY.txt"
TBESG_PATH = BASE / "Lexicons" / "TBESG - Translators Brief lexicon of Extended Strongs for Greek - STEPBible.org CC BY.txt"

# ── Helpers ───────────────────────────────────────────────────────────────────

def normalize_tag(raw: str) -> str:
    """'07225' (Hebrew 5-dig) → 'H7225',  '3056' (Greek 4-dig) → 'G3056'."""
    s = raw.strip()
    if len(s) == 5:                        # Hebrew: starts with extra leading 0
        return "H" + s[1:]                 # strip first '0' → 4-digit key
    else:                                  # Greek
        return "G" + s.zfill(4)


def parse_verse_strongs(path: Path) -> list[dict]:
    """Parse TTESV → list of {reference, strongs_tag, word_position}."""
    rows: list[dict] = []
    with open(path, encoding="utf-8-sig") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line.startswith("$"):
                continue
            parts = line.split("\t")
            if len(parts) < 2:
                continue

            ref_raw = parts[0][1:]          # strip leading '$'  → 'Gen 1:1'
            # Normalise reference: 'Gen 1:1' already matches our convention
            reference = ref_raw.strip()

            for token in parts[1:]:
                token = token.strip()
                if not token:
                    continue
                # token examples: '03=<07225>', '03+04=<06965>', '06=<00216>+<03588>'
                m = re.match(r"(\d+)(?:\+\d+)*=(.+)", token)
                if not m:
                    continue
                pos   = int(m.group(1))
                tags_str = m.group(2)       # '<07225>' or '<00216>+<03588>'
                for tag_m in re.finditer(r"<(\d+)>", tags_str):
                    rows.append({
                        "reference":     reference,
                        "strongs_tag":   normalize_tag(tag_m.group(1)),
                        "word_position": pos,
                    })
    return rows


def parse_lexicon(path: Path, lang: str) -> list[dict]:
    """
    Parse TBESH or TBESG TSV.
    Columns: eStrong#  dStrong  uStrong  word  transliteration  morph  gloss  meaning
    Returns one entry per unique eStrong# (first occurrence = canonical definition).
    """
    seen: set[str] = set()
    rows: list[dict] = []
    in_data = False
    with open(path, encoding="utf-8-sig") as f:
        for line in f:
            line = line.rstrip("\n")
            # Data starts after the header line containing "eStrong#\tdStrong\t..."
            if "eStrong#" in line and "dStrong" in line:
                in_data = True
                continue
            if not in_data:
                continue
            if not line or line.startswith("\t") or line.startswith("="):
                continue
            cols = line.split("\t")
            if len(cols) < 7:
                continue
            e_strong = cols[0].strip()
            if not e_strong or not re.match(r"^[HGA][0-9]", e_strong):
                continue
            # Normalise key: 'H0001' or 'H0001G' → use base e_strong as-is
            # But for lookup from TTESV we build 'H' + 4-digit-with-leading-zeros
            # So normalise: strip any trailing letter suffix from eStrong key
            base_tag = re.sub(r"[A-Z]$", "", e_strong)  # 'H0001G' → 'H0001'
            # Then strip internal leading zeros after the language prefix
            # to match normalize_tag() output: 'H0001' → 'H0001' (already matches)
            if base_tag in seen:
                continue
            seen.add(base_tag)
            rows.append({
                "strongs_tag":     base_tag,
                "language":        lang,
                "lemma":           cols[3].strip() if len(cols) > 3 else "",
                "transliteration": cols[4].strip() if len(cols) > 4 else "",
                "morph":           cols[5].strip() if len(cols) > 5 else "",
                "gloss":           cols[6].strip() if len(cols) > 6 else "",
                "definition":      cols[7].strip() if len(cols) > 7 else "",
            })
    return rows


def upsert_batches(client, table: str, rows: list[dict]):
    total = len(rows)
    for i in range(0, total, BATCH_SIZE):
        batch = rows[i:i + BATCH_SIZE]
        client.table(table).upsert(batch, on_conflict="strongs_tag" if table == "strongs_lexicon"
                                   else "reference,strongs_tag,word_position").execute()
        print(f"  {table}: {min(i + BATCH_SIZE, total):,}/{total:,}", end="\r")
    print(f"  {table}: {total:,}/{total:,}  ✓")


# ── Main ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    if not SUPABASE_KEY:
        sys.exit(
            "ERROR: Set SUPABASE_SERVICE_KEY env var to your Supabase service_role key.\n"
            "  export SUPABASE_SERVICE_KEY=eyJ..."
        )

    client = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("Connected to Supabase.\n")

    # 1. Lexicons
    print("Parsing Hebrew lexicon (TBESH)…")
    heb_rows = parse_lexicon(TBESH_PATH, "H")
    print(f"  {len(heb_rows):,} Hebrew entries")

    print("Parsing Greek lexicon (TBESG)…")
    grk_rows = parse_lexicon(TBESG_PATH, "G")
    print(f"  {len(grk_rows):,} Greek entries\n")

    print("Uploading strongs_lexicon…")
    upsert_batches(client, "strongs_lexicon", heb_rows + grk_rows)

    # 2. Verse-Strongs mapping
    print("\nParsing TTESV tagged Bible…")
    vs_rows = parse_verse_strongs(TTESV_PATH)
    print(f"  {len(vs_rows):,} verse-word-Strongs mappings\n")

    print("Uploading verse_strongs…")
    upsert_batches(client, "verse_strongs", vs_rows)

    print("\nDone!")
