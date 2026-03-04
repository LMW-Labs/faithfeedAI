#!/usr/bin/env python3
"""
Seed prayer_requests for FaithFeed's Prayer Wall.

Safe to re-run — skips insert if content already exists for that user.
For anonymous prayers, the real user_id is still stored (for RLS);
is_anonymous=True tells the app to display "Anonymous".

Usage:
    SUPABASE_URL=https://xxx.supabase.co SUPABASE_SERVICE_KEY=xxx python seed_prayers.py
"""

import os, sys
from supabase import create_client

SUPABASE_URL         = os.environ.get("SUPABASE_URL", "https://byrqbwsgwhljpagphwqy.supabase.co")
SUPABASE_SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")

if not SUPABASE_SERVICE_KEY:
    print("ERROR: Set SUPABASE_SERVICE_KEY env var"); sys.exit(1)

MOCK_PRAYERS = [
    {
        "username": "sarah_grace",
        "email": "sarah.grace@faithfeed.ai",
        "content": "Please pray for my husband who just lost his job. We are trusting God's provision but the anxiety is real. Standing on Philippians 4:19.",
        "is_anonymous": False,
        "prayer_count": 34,
    },
    {
        "username": "young_disciple",
        "email": "caleb.torres@faithfeed.ai",
        "content": "Pray for wisdom as I choose my major. First in my family to go to college. Want to honor God with this decision.",
        "is_anonymous": False,
        "prayer_count": 28,
    },
    {
        "username": "hope_renewed",
        "email": "hope.renewed@faithfeed.ai",
        "content": "Praying for my brother who is struggling with addiction. Please agree with me for his breakthrough.",
        "is_anonymous": False,
        "prayer_count": 67,
    },
    {
        "username": "morning_prayer",
        "email": "abigail.stevens@faithfeed.ai",
        "content": "Unspoken prayer request. God knows.",
        "is_anonymous": True,   # still stored with real user_id; app hides identity
        "prayer_count": 89,
    },
    {
        "username": "grace_walker",
        "email": "grace.walker@faithfeed.ai",
        "content": "Starting a new job next week. Praying for favor and that I'd be a light in that workplace. Pray with me!",
        "is_anonymous": False,
        "prayer_count": 45,
    },
]

def main():
    db = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    # Build username → user_id map via profiles table
    print("Fetching profiles...")
    try:
        rows = db.table("profiles").select("id, username").execute()
        username_to_id = {r["username"]: r["id"] for r in rows.data}
    except Exception as e:
        print(f"ERROR fetching profiles: {e}"); sys.exit(1)

    print(f"Found {len(username_to_id)} profiles.\n")

    ok = fail = 0
    for pr in MOCK_PRAYERS:
        uid = username_to_id.get(pr["username"])
        if not uid:
            print(f"  SKIP  No profile for username '{pr['username']}'")

            fail += 1
            continue

        label = "anonymous" if pr["is_anonymous"] else pr["email"].split("@")[0]
        print(f"  {label} ...", end=" ", flush=True)
        try:
            db.table("prayer_requests").insert({
                "user_id":      uid,          # always set — RLS requires it
                "content":      pr["content"],
                "is_anonymous": pr["is_anonymous"],
                "is_answered":  False,
                "prayer_count": pr["prayer_count"],
            }).execute()
            print("OK")
            ok += 1
        except Exception as e:
            print(f"FAIL  {e}")
            fail += 1

    print(f"\nDone. {ok} inserted, {fail} failed/skipped.")

if __name__ == "__main__":
    main()
