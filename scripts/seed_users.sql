-- ============================================================
-- FaithFeed Seed Users
-- Run in Supabase SQL Editor (requires service_role / admin access)
-- Creates 15 accounts: 5 official FaithFeed branded + 10 realistic personas
-- ============================================================

-- ── 1. Auth users ────────────────────────────────────────────
INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
) VALUES
-- Official accounts
('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000001','authenticated','authenticated',
 'community@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '60 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '60 days',NOW()),

('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000002','authenticated','authenticated',
 'dailyverse@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '60 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '60 days',NOW()),

('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000003','authenticated','authenticated',
 'prayer@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '60 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '60 days',NOW()),

('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000004','authenticated','authenticated',
 'devotional@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '60 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '60 days',NOW()),

('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000005','authenticated','authenticated',
 'worship@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '60 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '60 days',NOW()),

-- Realistic personas
('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000006','authenticated','authenticated',
 'marcus.t@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '45 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '45 days',NOW()),

('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000007','authenticated','authenticated',
 'sarah.chen@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '40 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '40 days',NOW()),

('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000008','authenticated','authenticated',
 'emmanuel.o@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '38 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '38 days',NOW()),

('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000009','authenticated','authenticated',
 'grace.w@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '35 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '35 days',NOW()),

('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000010','authenticated','authenticated',
 'pastor.david@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '30 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '30 days',NOW()),

('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000011','authenticated','authenticated',
 'hannah.kim@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '28 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '28 days',NOW()),

('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000012','authenticated','authenticated',
 'michael.a@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '25 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '25 days',NOW()),

('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000013','authenticated','authenticated',
 'ruth.m@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '22 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '22 days',NOW()),

('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000014','authenticated','authenticated',
 'priscilla.j@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '20 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '20 days',NOW()),

('00000000-0000-0000-0000-000000000000','a0000000-0000-0000-0000-000000000015','authenticated','authenticated',
 'samuel.o@seed.faithfeed.app', crypt('FF_Seed_Never_Login!', gen_salt('bf')),
 NOW()-INTERVAL '18 days','{"provider":"email","providers":["email"]}','{}',NOW()-INTERVAL '18 days',NOW())

ON CONFLICT (id) DO NOTHING;


-- ── 2. Auth identities (required for email provider) ─────────
INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
VALUES
('community@seed.faithfeed.app','a0000000-0000-0000-0000-000000000001',
 '{"sub":"a0000000-0000-0000-0000-000000000001","email":"community@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '60 days',NOW()-INTERVAL '60 days',NOW()),

('dailyverse@seed.faithfeed.app','a0000000-0000-0000-0000-000000000002',
 '{"sub":"a0000000-0000-0000-0000-000000000002","email":"dailyverse@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '60 days',NOW()-INTERVAL '60 days',NOW()),

('prayer@seed.faithfeed.app','a0000000-0000-0000-0000-000000000003',
 '{"sub":"a0000000-0000-0000-0000-000000000003","email":"prayer@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '60 days',NOW()-INTERVAL '60 days',NOW()),

('devotional@seed.faithfeed.app','a0000000-0000-0000-0000-000000000004',
 '{"sub":"a0000000-0000-0000-0000-000000000004","email":"devotional@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '60 days',NOW()-INTERVAL '60 days',NOW()),

('worship@seed.faithfeed.app','a0000000-0000-0000-0000-000000000005',
 '{"sub":"a0000000-0000-0000-0000-000000000005","email":"worship@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '60 days',NOW()-INTERVAL '60 days',NOW()),

('marcus.t@seed.faithfeed.app','a0000000-0000-0000-0000-000000000006',
 '{"sub":"a0000000-0000-0000-0000-000000000006","email":"marcus.t@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '45 days',NOW()-INTERVAL '45 days',NOW()),

('sarah.chen@seed.faithfeed.app','a0000000-0000-0000-0000-000000000007',
 '{"sub":"a0000000-0000-0000-0000-000000000007","email":"sarah.chen@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '40 days',NOW()-INTERVAL '40 days',NOW()),

('emmanuel.o@seed.faithfeed.app','a0000000-0000-0000-0000-000000000008',
 '{"sub":"a0000000-0000-0000-0000-000000000008","email":"emmanuel.o@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '38 days',NOW()-INTERVAL '38 days',NOW()),

('grace.w@seed.faithfeed.app','a0000000-0000-0000-0000-000000000009',
 '{"sub":"a0000000-0000-0000-0000-000000000009","email":"grace.w@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '35 days',NOW()-INTERVAL '35 days',NOW()),

('pastor.david@seed.faithfeed.app','a0000000-0000-0000-0000-000000000010',
 '{"sub":"a0000000-0000-0000-0000-000000000010","email":"pastor.david@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '30 days',NOW()-INTERVAL '30 days',NOW()),

('hannah.kim@seed.faithfeed.app','a0000000-0000-0000-0000-000000000011',
 '{"sub":"a0000000-0000-0000-0000-000000000011","email":"hannah.kim@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '28 days',NOW()-INTERVAL '28 days',NOW()),

('michael.a@seed.faithfeed.app','a0000000-0000-0000-0000-000000000012',
 '{"sub":"a0000000-0000-0000-0000-000000000012","email":"michael.a@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '25 days',NOW()-INTERVAL '25 days',NOW()),

('ruth.m@seed.faithfeed.app','a0000000-0000-0000-0000-000000000013',
 '{"sub":"a0000000-0000-0000-0000-000000000013","email":"ruth.m@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '22 days',NOW()-INTERVAL '22 days',NOW()),

('priscilla.j@seed.faithfeed.app','a0000000-0000-0000-0000-000000000014',
 '{"sub":"a0000000-0000-0000-0000-000000000014","email":"priscilla.j@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '20 days',NOW()-INTERVAL '20 days',NOW()),

('samuel.o@seed.faithfeed.app','a0000000-0000-0000-0000-000000000015',
 '{"sub":"a0000000-0000-0000-0000-000000000015","email":"samuel.o@seed.faithfeed.app","email_verified":true}',
 'email',NOW()-INTERVAL '18 days',NOW()-INTERVAL '18 days',NOW())

ON CONFLICT DO NOTHING;


-- ── 3. Profiles (batch 1 of 2 - Official accounts) ──────────
-- NOTE: Add avatar_url values after uploading to Supabase Storage
-- Free portrait source: thispersondoesnotexist.com
INSERT INTO public.profiles (
    id, username, full_name, bio, denomination, home_church_name,
    is_verified, is_premium, is_private,
    follower_count, following_count, post_count, lfs_total_score,
    created_at
) VALUES
('a0000000-0000-0000-0000-000000000001',
 'faithfeed', 'FaithFeed',
 'The official FaithFeed community account. Announcements, highlights, and encouragement for the whole body of Christ.',
 NULL, NULL, true, true, false, 842, 0, 0, 0, NOW()-INTERVAL '60 days'),

('a0000000-0000-0000-0000-000000000002',
 'daily_verse', 'Daily Verse',
 'A new scripture every morning to start your day anchored in the Word. Isaiah 40:8 — the Word of our God stands forever.',
 NULL, NULL, true, false, false, 1204, 0, 0, 0, NOW()-INTERVAL '60 days'),

('a0000000-0000-0000-0000-000000000003',
 'prayer_wall', 'The Prayer Wall',
 'Lifting requests from the FaithFeed community before the throne of grace. Matthew 18:20.',
 NULL, NULL, true, false, false, 976, 24, 0, 0, NOW()-INTERVAL '60 days'),

('a0000000-0000-0000-0000-000000000004',
 'daily_devotional', 'Daily Devotional',
 'Short, Spirit-led devotionals to keep you grounded throughout the week. New content Monday through Friday.',
 NULL, NULL, true, false, false, 1531, 8, 0, 0, NOW()-INTERVAL '60 days'),

('a0000000-0000-0000-0000-000000000005',
 'worship_collective', 'Worship Collective',
 'Sharing what the body of Christ is singing. Hymns, contemporary worship, and everything in between. Psalm 150.',
 NULL, NULL, true, false, false, 688, 42, 0, 0, NOW()-INTERVAL '60 days')

ON CONFLICT (id) DO NOTHING;


-- ── 4. Profiles (batch 2 of 2 - Realistic personas) ──────────
INSERT INTO public.profiles (
    id, username, full_name, bio, denomination, home_church_name,
    is_verified, is_premium, is_private,
    follower_count, following_count, post_count, lfs_total_score,
    created_at
) VALUES
('a0000000-0000-0000-0000-000000000006',
 'rev_marcus_t', 'Rev. Marcus Thompson',
 'Baptist pastor serving Grace Tabernacle for 22 years. Husband. Father of 3. Romans 8:28 is my life verse.',
 'Baptist', 'Grace Tabernacle Baptist Church', false, false, false, 312, 187, 0, 0, NOW()-INTERVAL '45 days'),

('a0000000-0000-0000-0000-000000000007',
 'sarah_chen_worship', 'Sarah Chen',
 'Worship leader and songwriter. Music is my prayer. Chasing the heart of God from California. John 4:24.',
 'Non-denominational', 'Hillside Community Church', false, false, false, 489, 231, 0, 0, NOW()-INTERVAL '40 days'),

('a0000000-0000-0000-0000-000000000008',
 'emmanuel_okafor', 'Emmanuel Okafor',
 'Evangelist and Missionary. Bridging cultures through the Gospel. Born in Lagos, planted in Houston. John 3:16.',
 'Evangelical', 'New Life Evangelical Church', false, false, false, 267, 154, 0, 0, NOW()-INTERVAL '38 days'),

('a0000000-0000-0000-0000-000000000009',
 'grace_williams_tn', 'Grace Williams',
 'Homeschool mom of 5. Scripture memory is our family sport. Tennessee mountains and morning devotions. Proverbs 22:6.',
 'Southern Baptist', 'First Baptist Church of Franklin', false, false, false, 198, 143, 0, 0, NOW()-INTERVAL '35 days'),

('a0000000-0000-0000-0000-000000000010',
 'pastor_david_r', 'Pastor David Rodriguez',
 'Pentecostal pastor from Miami. If God is for us who can be against us? Romans 8:31. Bilingual ministry.',
 'Pentecostal', 'Fuego Church Miami', false, false, false, 341, 209, 0, 0, NOW()-INTERVAL '30 days'),

('a0000000-0000-0000-0000-000000000011',
 'hannah_kim_music', 'Hannah Kim',
 'Worship songwriter. Piano and voice. Trying to write songs that last longer than a Sunday morning. Seattle, WA.',
 'Non-denominational', 'City Light Church', false, false, false, 523, 298, 0, 0, NOW()-INTERVAL '28 days'),

('a0000000-0000-0000-0000-000000000012',
 'michael_adeyemi', 'Michael Adeyemi',
 'Church planter in Chicago. The city is my mission field. Jeremiah 29:7. Nigerian-American. Father. Builder.',
 'Pentecostal', 'The Redeemed Church Chicago', false, false, false, 276, 188, 0, 0, NOW()-INTERVAL '25 days'),

('a0000000-0000-0000-0000-000000000013',
 'ruth_martinez_tx', 'Ruth Martinez',
 'Worship leader. Wife. Mom. San Antonio native. Bringing heaven to earth one song at a time. Psalm 95:1.',
 'Non-denominational', 'Victory Church San Antonio', false, false, false, 394, 217, 0, 0, NOW()-INTERVAL '22 days'),

('a0000000-0000-0000-0000-000000000014',
 'priscilla_j', 'Priscilla Jackson',
 'AME church mother. 40 years in the sanctuary and still learning. Still grateful. Blessed and highly favored.',
 'AME', 'Bethel AME Church', false, false, false, 156, 98, 0, 0, NOW()-INTERVAL '20 days'),

('a0000000-0000-0000-0000-000000000015',
 'pastor_samuel_o', 'Pastor Samuel Osei',
 'Elder and pastor. Ghanaian by birth, American by calling. Reformed theology, African heart. 1 Corinthians 9:22.',
 'Presbyterian', 'Calvary Presbyterian Church', false, false, false, 287, 162, 0, 0, NOW()-INTERVAL '18 days')

ON CONFLICT (id) DO NOTHING;

