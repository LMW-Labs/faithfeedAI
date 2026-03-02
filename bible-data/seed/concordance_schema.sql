-- ============================================================
-- Concordance tables for FaithFeed Bible Reader "Words" tab
-- Run this in Supabase SQL editor BEFORE running the seed script
-- ============================================================

-- Strongs lexicon: one canonical entry per Strongs number
CREATE TABLE IF NOT EXISTS strongs_lexicon (
    strongs_tag     TEXT PRIMARY KEY,   -- 'H7225', 'G3056'
    language        CHAR(1) NOT NULL,   -- 'H' (Hebrew) or 'G' (Greek)
    lemma           TEXT DEFAULT '',    -- Hebrew/Greek word form
    transliteration TEXT DEFAULT '',
    morph           TEXT DEFAULT '',    -- 'H:N-M', 'G:V', etc.
    gloss           TEXT DEFAULT '',    -- short English gloss
    definition      TEXT DEFAULT ''     -- HTML definition from BDB/LSJ
);

-- Verse-word → Strongs mapping
CREATE TABLE IF NOT EXISTS verse_strongs (
    reference       TEXT    NOT NULL,   -- 'Gen 1:1'  (matches bible_verses.book + chapter + verse)
    strongs_tag     TEXT    NOT NULL,   -- 'H7225'
    word_position   INTEGER NOT NULL,   -- 1-based word index within the verse
    PRIMARY KEY (reference, strongs_tag, word_position)
);

CREATE INDEX IF NOT EXISTS idx_verse_strongs_ref     ON verse_strongs (reference);
CREATE INDEX IF NOT EXISTS idx_verse_strongs_tag     ON verse_strongs (strongs_tag);

-- ── RLS ──────────────────────────────────────────────────────
ALTER TABLE strongs_lexicon ENABLE ROW LEVEL SECURITY;
ALTER TABLE verse_strongs   ENABLE ROW LEVEL SECURITY;

-- Public read (no auth required)
CREATE POLICY "public_read_lexicon"
    ON strongs_lexicon FOR SELECT USING (true);

CREATE POLICY "public_read_verse_strongs"
    ON verse_strongs FOR SELECT USING (true);
