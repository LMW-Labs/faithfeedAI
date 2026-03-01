#!/usr/bin/env python3
"""
FaithFeed daily seed activity.
Runs 3x/day via GitHub Actions. Posts, likes, and comments as seed users
to keep the feed alive during cold-start until real users take over.

Requirements: pip install supabase
Secrets needed: SUPABASE_URL, SUPABASE_SERVICE_KEY
"""

import os
import json
import random
from pathlib import Path
from supabase import create_client, Client

# ── Config ───────────────────────────────────────────────────────────────────
SUPABASE_URL = os.environ["SUPABASE_URL"]
SERVICE_KEY  = os.environ["SUPABASE_SERVICE_KEY"]

# Fixed UUIDs — must match seed_users.sql
OFFICIAL_USER_IDS = [
    "a0000000-0000-0000-0000-000000000001",  # FaithFeed
    "a0000000-0000-0000-0000-000000000002",  # Daily Verse
    "a0000000-0000-0000-0000-000000000003",  # Prayer Wall
    "a0000000-0000-0000-0000-000000000004",  # Daily Devotional
    "a0000000-0000-0000-0000-000000000005",  # Worship Collective
]

PERSONA_USER_IDS = [
    "a0000000-0000-0000-0000-000000000006",  # Rev. Marcus Thompson
    "a0000000-0000-0000-0000-000000000007",  # Sarah Chen
    "a0000000-0000-0000-0000-000000000008",  # Emmanuel Okafor
    "a0000000-0000-0000-0000-000000000009",  # Grace Williams
    "a0000000-0000-0000-0000-000000000010",  # Pastor David Rodriguez
    "a0000000-0000-0000-0000-000000000011",  # Hannah Kim
    "a0000000-0000-0000-0000-000000000012",  # Michael Adeyemi
    "a0000000-0000-0000-0000-000000000013",  # Ruth Martinez
    "a0000000-0000-0000-0000-000000000014",  # Priscilla Jackson
    "a0000000-0000-0000-0000-000000000015",  # Pastor Samuel Osei
]

ALL_SEED_IDS = OFFICIAL_USER_IDS + PERSONA_USER_IDS

CONTENT_FILE = Path(__file__).parent / "seed_content.json"


# ── Helpers ───────────────────────────────────────────────────────────────────
def load_content() -> dict:
    with open(CONTENT_FILE) as f:
        return json.load(f)


def get_recent_public_posts(client: Client, exclude_user_id: str, limit: int = 100) -> list:
    result = (
        client.table("posts")
        .select("id")
        .eq("is_public", True)
        .neq("user_id", exclude_user_id)
        .order("created_at", desc=True)
        .limit(limit)
        .execute()
    )
    return result.data or []


# ── Actions ───────────────────────────────────────────────────────────────────
def create_post(client: Client, user_id: str, content_bank: dict) -> None:
    posts = content_bank.get("posts", [])
    if not posts:
        return
    entry = random.choice(posts)
    data = {
        "user_id":       user_id,
        "content":       entry["content"],
        "post_type":     entry.get("post_type", "post"),
        "is_public":     True,
        "audience":      "public",
        "like_count":    0,
        "comment_count": 0,
        "share_count":   0,
        "prayer_count":  0,
        "lfs_score":     1,
    }
    if entry.get("verse_ref"):
        data["verse_ref"] = entry["verse_ref"]
    client.table("posts").insert(data).execute()
    print(f"  [post]    {user_id[:8]}... — {entry['content'][:60]}")


def like_posts(client: Client, user_id: str, count: int) -> None:
    posts = get_recent_public_posts(client, user_id, limit=100)
    if not posts:
        return
    sample = random.sample(posts, min(count, len(posts)))
    liked = 0
    for post in sample:
        try:
            client.table("post_likes").insert({
                "post_id": post["id"],
                "user_id": user_id,
            }).execute()
            liked += 1
        except Exception:
            pass  # already liked — skip
    print(f"  [like]    {user_id[:8]}... liked {liked} posts")


def add_comments(client: Client, user_id: str, content_bank: dict, count: int) -> None:
    comments = content_bank.get("comments", [])
    if not comments:
        return
    posts = get_recent_public_posts(client, user_id, limit=30)
    if not posts:
        return
    sample = random.sample(posts, min(count, len(posts)))
    for post in sample:
        text = random.choice(comments)
        try:
            client.table("post_comments").insert({
                "post_id": post["id"],
                "user_id": user_id,
                "content": text,
            }).execute()
        except Exception:
            pass
    print(f"  [comment] {user_id[:8]}... commented on {len(sample)} posts")


def add_prayer(client: Client, user_id: str, content_bank: dict) -> None:
    prayers = content_bank.get("prayers", [])
    if not prayers:
        return
    entry = random.choice(prayers)
    try:
        client.table("prayer_requests").insert({
            "user_id":      user_id,
            "title":        entry["title"],
            "content":      entry["content"],
            "is_anonymous": entry.get("is_anonymous", False),
            "prayer_count": 0,
        }).execute()
        print(f"  [prayer]  {user_id[:8]}... — {entry['title']}")
    except Exception:
        pass


# ── Main ──────────────────────────────────────────────────────────────────────
def main() -> None:
    client       = create_client(SUPABASE_URL, SERVICE_KEY)
    content_bank = load_content()

    posts    = content_bank.get("posts", [])
    comments = content_bank.get("comments", [])
    if not posts and not comments:
        print("seed_content.json has no posts or comments — nothing to do.")
        return

    # ── Official accounts: 1-2 active per run, lower frequency
    official_active = random.sample(OFFICIAL_USER_IDS, random.randint(1, 2))
    print(f"\nOfficial accounts active: {len(official_active)}")
    for uid in official_active:
        if random.random() < 0.8:           # 80% post
            create_post(client, uid, content_bank)
        like_posts(client, uid, random.randint(3, 8))
        if random.random() < 0.3:           # 30% comment (official accounts stay reserved)
            add_comments(client, uid, content_bank, 1)

    # ── Personas: 2-4 active per run, more organic behavior
    persona_active = random.sample(PERSONA_USER_IDS, random.randint(2, 4))
    print(f"Persona accounts active: {len(persona_active)}")
    for uid in persona_active:
        if random.random() < 0.6:           # 60% post
            create_post(client, uid, content_bank)
        like_posts(client, uid, random.randint(5, 14))
        if random.random() < 0.65:          # 65% comment
            add_comments(client, uid, content_bank, random.randint(1, 3))
        if random.random() < 0.15:          # 15% prayer request
            add_prayer(client, uid, content_bank)

    print("\nDone.")


if __name__ == "__main__":
    main()
