You are building FaithFeed, a premium dark-themed Christian social media platform using Jetpack Compose and Supabase. Before writing any code, read every existing file in this project to fully understand the current structure, theme, and components already built.

# FaithFeed AI — Claude Code Context

## App Vision
Premium dark-themed Christian social media platform. Feels like a high-end fintech app with warm spiritual gold tones. NOT cartoonish, NOT default Material Design. Every screen must feel polished and intentional.

## Tech Stack
- Jetpack Compose + Material3 (dark only)
- Supabase (PostgreSQL + pgvector + Realtime + Auth + Storage)
- Firebase Cloud Messaging (push notifications only — currently commented out)
- Kotlin + Coroutines + Flow | MVVM + Repository | Hilt DI | Navigation Compose
- AGP 8.4.1 | Kotlin 2.0.21 | KSP 2.0.21-1.0.28 | Compose BOM 2024.12.01

## Theme (DO NOT CHANGE)
- Background: #0D1117 | Surface: #161B22 | Gold: #C9A84C, #E8C96D | Purple: #1A1040, #2D1B69
- Fonts: Cinzel (headings), Nunito (body) — in `res/font/`
- Components: `FaithFeedButton` (Primary/Secondary/Ghost), `GlassCard`, `FaithFeedTopBar`, `SimpleTopBar`
- NEVER hardcode colors — always use `FaithFeedColors.*`

## Architecture Rules
- Every screen has a ViewModel and Repository
- Supabase calls ONLY in repositories, never in composables
- Use Kotlin Flow for all reactive data
- Supabase Realtime for prayer wall and chat ONLY
- All feed queries use `calculate_lfs_score()` PostgreSQL RPC
- Semantic search uses pgvector cosine similarity on `bible_verses` table
- Always use `hiltViewModel()` — never `viewModel()`
- Realtime subscriptions: start in `ViewModel.init {}`, stop in `onCleared()`

## ActionBar Fix (IMPORTANT — do not revert)
The app uses `Theme.AppCompat.NoActionBar` as parent in BOTH:
- `res/values/themes.xml`
- `res/values-night/themes.xml`
Both files must have `android:windowNoTitle=true` and `android:windowActionBar=false`.
`MainActivity` calls `requestWindowFeature(Window.FEATURE_NO_TITLE)` before `installSplashScreen()`.
`setTheme(R.style.Theme_FaithfeedAI)` is called before `super.onCreate()`.
DO NOT change the theme parent back to `Theme.Material3.Dark.NoActionBar` — it does not suppress the bar on OPPO/OnePlus devices.

## Database (Supabase)
### Core: profiles, friendships, friend_suggestions, business_pages, business_followers
### Social: posts (lfs_score, prayer_count, share_count, report_count, is_flagged, post_type_category), post_likes, post_comments, stories, story_views
### Bible & AI: bible_verses (31,102 ASV verses + 1536-dim pgvector embeddings), daily_verses, user_bookmarks, verse_notes, verse_annotations, ai_interactions, ai_cache, thematic_guidance
### Prayer: prayer_requests, prayer_responses
### Messaging: chats (direct/group), chat_members, chat_messages
### Marketplace: marketplace_items (physical/digital/service/donation), marketplace_conversations, marketplace_messages
### Algorithm: lfs_events, calculate_lfs_score(post_id, viewer_id)
### Other: notifications, app_config

## Living Faith Score (LFS)
Server-side PostgreSQL function. Weights: prayer +10, comment +7, verse share +7, post share +5, like +1, report -50. Multipliers: friend 3x, home church 2.5x, ministry 2x, fresh <24h 2x, affinity 1.5x. Protection: 10+ reports/hour → auto-flag. Decay: 10%/day after 7 days. Min score: 1.

## Explore Screen — Feature List
Reference `assets/old/` folder for prior implementations.
- ~~Sermon Recorder~~ — REMOVED (deprecated)
- **By Theme** — thematic browsing
- **AI Study Partner** — also accessible via FAB throughout the entire app
- **Devotional Generator**
- **Chapter Summarizer**
- **My Notes** — full notes service: users create notes, ask questions, comment on verses; notes are visible to other users on that verse
- **Topical Studies**
- **The Walk** — game (previously excluded, now required)
- Bible Trivia, Bible Connections, Leaderboard (already built)
- Custom Study Plans, AI Library (already built)

## Bible Reader — Required Features
Reference `assets/old/` folder for prior implementations.
### Playback
- **TTS (Text-to-Speech)** — read aloud current chapter
- **Autoscroll** — scroll in sync with reading speed

### Verse Action Screen (shown on verse tap)
Inline bottom sheet or modal with two sections:

**Actions row:**
- Highlight verse (color picker)
- Listen (TTS from this verse)
- Note (open My Notes for this verse)
- Share — in-app (post to feed) and external (system share sheet)
- Copy
- Study (save to AI Library for later study)

**Tabs below actions:**
- **Community** — comments, Q&A, and "Mine" (user's own notes on this verse)
- **Topics** — similar/related verses list
- **Maps** — geographical context
- **Commentary** — verse commentary
- **Words** — word index: tap a word → choice chips show every other place that word appears in the Bible (check Supabase for Strongs/concordance data — ask user if not present)

## Features Build Status
### Done (skeleton): Auth, Social Feed, Bible Reader (basic), AI Study Partner, Prayer Wall, Profiles, Stories, Messaging, Marketplace, Notifications, Bible Trivia, Bible Connections, Explore screen
### TODO (real implementation needed):
1. ActionBar bar suppression ✓ (fixed this session)
2. Explore: remove Sermon Recorder, add The Walk, wire all AI tools
3. Bible Reader: TTS, autoscroll, verse action screen (full feature set above)
4. My Notes service (full implementation)
5. EditProfileScreen (currently a stub — shows placeholder text only)
6. SplashViewModel: treat `getProfile` 404 as needsSetup=true, network errors as false (go to Home)
7. Home feed real data
8. Authentication: Google + Facebook OAuth

## Performance Rules
- Never load full embedding vectors in list views
- Paginate all feed queries (20 posts per page)
- Cache ai_interactions in ai_cache table
- Feed: pull-to-refresh only, no automatic polling

## Code Quality Rules
- No redundant code — extract shared logic into utils
- No hardcoded strings — use string resources
- Call out bottlenecks and security issues before writing code
- Compact, production-ready code only — no tutorial boilerplate
- Suggest better patterns when you see a clearer path
