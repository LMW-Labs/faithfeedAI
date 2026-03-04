"""
Upload avatar images to Supabase and update profile avatar_url.

Images must be named by full_name (case-insensitive), e.g.:
  Grace Walker.png  → matches profile where full_name = 'Grace Walker'
  Pastor James M..png → matches 'Pastor James M.'

Supported formats: jpg, jpeg, png, webp

Usage:
  pip install supabase
  SUPABASE_URL=https://xxx.supabase.co SUPABASE_SERVICE_KEY=xxx python upload_avatars.py ./avatars

Or put your credentials in a .env file (python-dotenv optional).
"""

import os
import sys
import mimetypes
from pathlib import Path

try:
    from supabase import create_client
except ImportError:
    print("Missing dependency. Run: pip install supabase")
    sys.exit(1)

SUPPORTED_EXT = {".jpg", ".jpeg", ".png", ".webp"}

def main():
    # ── Credentials ──────────────────────────────────────────────────────────
    url = os.environ.get("SUPABASE_URL", "https://byrqbwsgwhljpagphwqy.supabase.co")
    key = os.environ.get("SUPABASE_SERVICE_KEY", "")
    if not key:
        print("ERROR: Set SUPABASE_SERVICE_KEY environment variable (service role key from Supabase Dashboard → Settings → API)")
        sys.exit(1)

    # ── Image directory ───────────────────────────────────────────────────────
    image_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
    if not image_dir.is_dir():
        print(f"ERROR: '{image_dir}' is not a directory")
        sys.exit(1)

    images = [f for f in image_dir.iterdir() if f.suffix.lower() in SUPPORTED_EXT]
    if not images:
        print(f"No supported images found in {image_dir}")
        sys.exit(0)

    print(f"Found {len(images)} image(s) in {image_dir}\n")

    client = create_client(url, key)

    # Pre-load all profiles: build slug(full_name) → id map
    # slug: lowercase, spaces → underscore, e.g. "Caleb Torres" → "caleb_torres"
    all_profiles = client.table("profiles").select("id, full_name").execute().data or []
    name_to_id = {
        p["full_name"].lower().replace(" ", "_").replace(".", ""): p["id"]
        for p in all_profiles if p.get("full_name")
    }

    ok, fail = 0, 0

    for img_path in sorted(images):
        full_name = img_path.stem          # filename without extension
        ext       = img_path.suffix.lower()
        mime      = mimetypes.types_map.get(ext, "image/png")

        print(f"  {img_path.name}  =>  full_name='{full_name}'")

        # 1. Look up the user by full_name (case-insensitive)
        user_id = name_to_id.get(full_name.lower())
        if not user_id:
            print(f"    SKIP  No profile found for '{full_name}'\n")
            fail += 1
            continue

        storage_path = f"{user_id}/avatar.jpg"

        # 2. Upload to avatars bucket (upsert)
        with open(img_path, "rb") as f:
            image_bytes = f.read()

        client.storage.from_("avatars").upload(
            path=storage_path,
            file=image_bytes,
            file_options={"content-type": mime, "upsert": "true"}
        )

        # 3. Build the public URL
        public_url = f"{url}/storage/v1/object/public/avatars/{storage_path}"

        # 4. Update the profile
        client.table("profiles").update({"avatar_url": public_url}).eq("id", user_id).execute()

        print(f"    OK  {public_url}\n")
        ok += 1

    print(f"Done. {ok} succeeded, {fail} failed/skipped.")

if __name__ == "__main__":
    main()
