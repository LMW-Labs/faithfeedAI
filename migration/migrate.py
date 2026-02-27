import os
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore
from supabase import create_client

load_dotenv()

cred = credentials.Certificate("serviceAccount.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

supabase = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))

print("Starting migration...")

batch = []
count = 0
last_doc = None
page_size = 500

while True:
    query = db.collection("verses").order_by("__name__").limit(page_size)

    if last_doc:
        query = query.start_after(last_doc)

    docs = list(query.stream())

    if not docs:
        print("All done!")
        break

    last_doc = docs[-1]

    for doc in docs:
        data = doc.to_dict()
        embedding = data.get("embedding")
        if not embedding:
            continue

        batch.append({
            "doc_id": doc.id,
            "book_code": data.get("book_code"),
            "book_name": data.get("book_name"),
            "chapter_number": data.get("chapter_number"),
            "verse_number": data.get("verse_number"),
            "text": data.get("text"),
            "version": data.get("version"),
            "version_shortcode": data.get("version_shortcode"),
            "embedding": embedding
        })
        count += 1

        if len(batch) == 100:
            supabase.table("bible_verses").upsert(batch, on_conflict="doc_id").execute()
            print(f"Inserted {count} verses...")
            batch = []

if batch:
    supabase.table("bible_verses").upsert(batch, on_conflict="doc_id").execute()
    print(f"Inserted {count} verses...")

print(f"Migration complete! Total: {count} verses")