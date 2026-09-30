# Hangout App — Backend & API Reference Document

> Last updated: April 29, 2026  
> App: Decisionly / Hangout — Flutter (Dart)  
> Platform: **Android only**  
> Market: **India only**  
> Current state: 100% static UI, zero backend

---

## TABLE OF CONTENTS

1. [App Flow](#1-app-flow)
2. [Restaurant & Place Suggestion API](#2-restaurant--place-suggestion-api)
3. [What Google Places Gives You (Swipe Cards)](#3-what-google-places-gives-you-swipe-cards)
4. [Table Booking Strategy (Deep-links)](#4-table-booking-strategy-deep-links)
5. [Travel Mode APIs](#5-travel-mode-apis)
6. [Full Pricing Breakdown](#6-full-pricing-breakdown)
7. [Recommended Stack — 100% Free at Launch](#7-recommended-stack--100-free-at-launch)
8. [Deployment — Free Options Explained](#8-deployment--free-options-explained)
9. [Database Schema](#9-database-schema)
10. [API Endpoints (Backend Routes)](#10-api-endpoints-backend-routes)
11. [Real-time Events](#11-real-time-events)
12. [Group History Bookings Screen](#12-group-history-bookings-screen)
13. [What We Need From You To Start](#13-what-we-need-from-you-to-start)

---

## 1. App Flow

```
Open App
  └── Login / Register (Google Sign-In or Phone OTP)
        └── Home Screen
              ├── HUNGER MODE
              │     ├── Create Group
              │     │     ├── Invite people → WhatsApp link / 6-char code
              │     │     ├── Each member adds a location (area name or map pin)
              │     │     ├── App fetches 15–20 nearby restaurants (Google Places)
              │     │     ├── All members swipe cards (Tinder-style)
              │     │     │     └── Cards show: Photos · Reviews · Menu link · Price level
              │     │     ├── Dramatic reveal (confetti + ranked list)
              │     │     ├── "Book Table" buttons → Dineout / EazyDiner / Google Maps
              │     │     ├── Enter total bill amount → split evenly among group
              │     │     └── Session saved as Memory (group history)
              │     │
              │     └── Play Solo
              │           ├── Add a location
              │           ├── App fetches 15–20 nearby restaurants
              │           ├── Swipe all cards
              │           └── Browse all swiped places with full details
              │
              └── TRAVEL MODE
                    ├── Same group / solo flow as Hunger
                    ├── Instead of restaurants → tourist spots, landmarks, experiences
                    ├── Cards show: Photos · Reviews · Entry info · Rating
                    └── "Get Directions" / "View on Maps" deep-link (no booking)
```

---

## 2. Restaurant & Place Suggestion API

### Google Places API (New) — THE ONLY API WE NEED

Everything — restaurant search, photos, reviews, price, and opening hours — comes from a **single API**. No Yelp, no Foursquare, no paid supplements needed.

**What it returns for each place:**
- Name + address + phone number
- Rating (1–5 stars) + total review count
- Price level: 1=₹ · 2=₹₹ · 3=₹₹₹ · 4=₹₹₹₹
- Opening hours (open now + full weekly schedule)
- Up to 10 photos (high-resolution)
- Up to 5 user reviews (text, rating, author name)
- Google Maps URI (direct link to the place)
- Website URL (often links to the restaurant's menu page)
- Cuisine type / category tags

**Three calls per session generation:**

```
STEP 1 — Find nearby restaurants
POST https://places.googleapis.com/v1/places:searchNearby
Body: {
  "locationRestriction": {
    "circle": {
      "center": { "latitude": 19.0760, "longitude": 72.8777 },
      "radius": 3000.0
    }
  },
  "includedTypes": ["restaurant"],
  "maxResultCount": 20,
  "rankPreference": "POPULARITY"
}

STEP 2 — Get full details for each place
GET https://places.googleapis.com/v1/places/{place_id}
Header: X-Goog-FieldMask: displayName,rating,userRatingCount,priceLevel,reviews,
                           regularOpeningHours,photos,nationalPhoneNumber,
                           websiteUri,formattedAddress,googleMapsUri,
                           primaryTypeDisplayName

STEP 3 — Resolve photo URLs
GET https://places.googleapis.com/v1/{photo_name}/media?maxWidthPx=800&key=API_KEY
→ Returns a direct image URL for each photo
```

**Pricing — India billing address (significantly discounted):**

| SKU | Free calls/month | Cost beyond free |
|-----|-----------------|-----------------|
| Nearby Search Pro | 35,000 | ~₹2.70 / 1,000 calls |
| Place Details Pro | 35,000 | ~₹1.45 / 1,000 calls |
| Place Details Photos | 35,000 | ~₹0.60 / 1,000 calls |
| Geocoding (address → lat/lng) | 70,000 | ~₹0.43 / 1,000 calls |

**Cost estimate for our app:**
```
Per session: 1 search + 20 detail calls + 60 photo calls = ~81 API calls total

Free tier: 35,000 calls/month ÷ 81 calls/session = ~430 sessions completely free

At 2,000 sessions/month:
  Extra sessions: 1,570 × 81 = ~127,000 calls
  Estimated cost: ₹400–500/month — still very cheap
```

**Setup:**  
Sign up → https://console.cloud.google.com/google/maps-apis/start  
Enable: **Places API (New)**, **Maps SDK for Android**, **Geocoding API**

---

## 3. What Google Places Gives You (Swipe Cards)

Each swipe card will show this data — everything from Google Places, zero additional APIs:

```
┌─────────────────────────────────────────┐
│  [PHOTO 1]  [PHOTO 2]  [PHOTO 3] ...   │  ← Google Places Photos (up to 10)
│                                          │
│  Neon Lotus                              │  ← displayName
│  Asian Fusion  •  Bandra West, Mumbai    │  ← primaryTypeDisplayName + formattedAddress
│  ⭐ 4.3  (847 reviews)   ₹₹₹           │  ← rating + userRatingCount + priceLevel
│                                          │
│  ─── Reviews ───                         │
│  "Amazing ambience and food..." — Raj    │  ← reviews[0] text + author
│  "Best cocktails in Mumbai..." — Priya   │  ← reviews[1] text + author
│                                          │
│  ─── Info ───                            │
│  🕐 Open until 11:30 PM                 │  ← regularOpeningHours
│  🌐 View Menu  →  (website deep-link)   │  ← websiteUri (opens restaurant website)
│  📞 Call Restaurant                      │  ← nationalPhoneNumber
│                                          │
│       [👍 YES]        [👎 NO]           │
└─────────────────────────────────────────┘
```

**Note on "Menu":** Google Places returns the restaurant's `websiteUri`, which usually has their menu. The "View Menu" button just opens that website in the browser — this is exactly what Swiggy and Zomato do for dine-in. A structured dish-level menu database would require a paid data deal with Zomato. Not needed for V1.

**Price level display for India context:**
```
priceLevel 1  →  ₹      (under ₹500 for two)
priceLevel 2  →  ₹₹     (₹500 – ₹1,500 for two)
priceLevel 3  →  ₹₹₹    (₹1,500 – ₹3,000 for two)
priceLevel 4  →  ₹₹₹₹   (₹3,000+ for two)
```

---

## 4. Table Booking Strategy (Deep-links Only)

After the winner is revealed, show three booking buttons. All are deep-links — **no API key, no cost, works on day one.**

### Button 1: Dineout (Swiggy)
```
URL pattern:
https://www.dineout.co.in/search?q=RESTAURANT_NAME&city=CITY_NAME

Example:
https://www.dineout.co.in/search?q=Neon+Lotus&city=Mumbai

Flutter implementation:
launchUrl(
  Uri.parse('https://www.dineout.co.in/search?q=${Uri.encodeComponent(name)}&city=${Uri.encodeComponent(city)}'),
  mode: LaunchMode.externalApplication,
);
```
If Dineout app is installed on the user's phone, it opens directly in app. Otherwise opens in browser.

### Button 2: EazyDiner
```
URL pattern:
https://www.eazydiner.com/search?q=RESTAURANT_NAME+CITY

Example:
https://www.eazydiner.com/search?q=Neon+Lotus+Bandra+Mumbai
```

### Button 3: Google Maps (always works — best fallback)
```
Use the googleMapsUri field returned directly by the Places API.
This opens Google Maps to the exact restaurant page.
If the restaurant supports "Reserve a Table" on Google, user can book from there.

URL: already stored in suggested_places.google_maps_uri
```

**What to store in the database per place:**
```
google_maps_uri    → from Places API response (always available)
dineout_url        → constructed: dineout.co.in/search?q={name}&city={city}
eazydiner_url      → constructed: eazydiner.com/search?q={name}+{city}
```

Zero accounts needed. Zero API keys. Zero cost. Ready immediately.

---

## 5. Travel Mode APIs

Travel mode uses the **exact same Google Places API** — just different `includedTypes`.

**Change the search request:**
```json
"includedTypes": [
  "tourist_attraction",
  "museum",
  "amusement_park",
  "national_park",
  "zoo",
  "aquarium",
  "art_gallery",
  "cultural_center",
  "historical_landmark"
]
```

**Travel swipe card:**
```
┌─────────────────────────────────────────┐
│  [PHOTO 1]  [PHOTO 2]  [PHOTO 3] ...   │
│                                          │
│  Gateway of India                        │
│  Historical Landmark  •  Colaba, Mumbai  │
│  ⭐ 4.6  (12,453 reviews)               │
│                                          │
│  "Iconic arch monument built in 1924..." │
│  "Must visit when in Mumbai..." — Neha   │
│                                          │
│  🗺️ Get Directions  (Google Maps link)  │
│  🌐 More Info  (website link)            │
│                                          │
│       [👍 YES]        [👎 NO]           │
└─────────────────────────────────────────┘
```

**Same API. Same cost. Same codebase. No extra work at all.**

---

## 6. Full Pricing Breakdown

### Everything free at launch:

| Service | What it does | Free tier | Cost at 500 sessions/mo |
|---------|-------------|-----------|--------------------------|
| **Google Places API** | Place search, photos, reviews, price | 35,000 calls/SKU/mo | ₹0 (within free tier) |
| **Supabase** | Database + Auth + Realtime + Storage | 500MB DB · 50,000 users · 2GB files | ₹0 |
| **Firebase FCM** | Push notifications | Unlimited | ₹0 |
| **Dineout deep-link** | Table booking | No API needed | ₹0 |
| **EazyDiner deep-link** | Table booking | No API needed | ₹0 |
| **Google Maps deep-link** | Directions + place page | No API needed for links | ₹0 |
| **Render (free tier)** | Backend server hosting | 750 hrs/mo free | ₹0 |

**Total monthly cost at launch: ₹0**

### When costs begin (growth milestones):

| When | What triggers cost | Approximate amount |
|------|-------------------|-------------------|
| 430+ sessions/month | Google Places beyond free tier | ~₹3–5/session extra |
| 50,000+ registered users | Supabase Pro plan | $25/mo (~₹2,100) |
| Need always-on server | Render Starter plan | $7/mo (~₹590) |
| Public Play Store launch | One-time developer fee | ₹2,100 (one time only) |

---

## 7. Recommended Stack — 100% Free at Launch

```
┌──────────────────────────────────────────────────────────────────┐
│  FLUTTER APP (Android)                                            │
│  ► supabase_flutter   — auth, database queries, realtime         │
│  ► url_launcher       — Dineout / EazyDiner / Maps deep-links    │
│  ► firebase_messaging — receive push notifications               │
│  ► google_sign_in     — Google OAuth login                       │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  BACKEND SERVER (Node.js + Fastify)                              │
│  ► Hosted on Render free tier (or Supabase Edge Functions)       │
│  ► Calls Google Places API to fetch + enrich place data          │
│  ► Computes results after all swipes are in                      │
│  ► Sends FCM push notifications via Firebase Admin SDK           │
│  ► Writes everything to Supabase                                 │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  DATABASE + AUTH + REALTIME (Supabase — free tier)               │
│  ► PostgreSQL database — all app data                            │
│  ► Auth — Google Sign-In + Phone OTP                             │
│  ► Realtime — swipe progress, reveal events, bill updates        │
│  ► Storage — profile avatars                                     │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  PLACE DATA (Google Places API — free tier)                      │
│  ► Nearby search by lat/lng                                      │
│  ► Photos, reviews, price level, hours, maps link                │
│  ► Same API for both Hunger and Travel modes                     │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  BOOKING (Zero cost — deep-links only)                           │
│  ► Dineout search URL                                            │
│  ► EazyDiner search URL                                          │
│  ► Google Maps URI (from Places API response)                    │
└──────────────────────────────────────────────────────────────────┘
```

---

## 8. Deployment — Free Options Explained

There are **two separate things** to understand here:

> **Backend server** = the Node.js code that runs on the internet and talks to Google Places + Supabase  
> **Android app** = the Flutter APK users install on their phone

The app is installed on devices — it doesn't need "deployment" like a server does. The server does.

---

### Backend Server — Free Hosting Options

#### Option A: Render ✅ Recommended to start

**URL:** https://render.com

**Free tier:**
- 1 web service (your Node.js backend)
- 750 compute hours/month = enough for 1 service running all month
- Auto-deploys when you push code to GitHub — no manual steps
- HTTPS (SSL) included
- Custom domain support

**The one issue:** Server "sleeps" after 15 minutes of no requests. First request after sleep takes 30–60 seconds (cold start). After that it runs normally.

**Free fix for cold start:** Create a free cron job at [cron-job.org](https://cron-job.org) → ping your Render URL every 10 minutes → server stays awake 24/7. Total cost: ₹0.

**When to upgrade:** Render Starter plan at $7/month (~₹590) eliminates sleep entirely. Only needed when you have regular active users.

**Deploy flow:**
```
1. Push backend code to GitHub repo
2. render.com → New Web Service → connect GitHub repo
3. Set environment variables (Supabase keys, Google API key, Firebase key)
4. Click Deploy
5. Get URL like: https://hangout-api.onrender.com
6. Done — your API is live
```

---

#### Option B: Supabase Edge Functions ✅ Even simpler

**What it is:** Write your backend logic as serverless functions that run directly inside Supabase's infrastructure. No separate server to manage at all.

**Free tier:** 500,000 function calls/month — more than enough for our scale

**How it changes the architecture:**
```
Instead of:   Flutter app → Render backend → Supabase + Google Places

You get:      Flutter app → Supabase Edge Function → Google Places
                                                    ↓
                                              Supabase DB (same project)
```

**Language:** TypeScript (Deno runtime) — similar to Node.js, just slightly different syntax

**Pros:**
- Zero extra service to sign up for
- No cold starts — functions are always ready
- Completely free at our scale
- Manage everything from the same Supabase dashboard
- Supabase CLI lets you test functions locally

**Cons:**
- Written in Deno/TypeScript, not plain Node.js (small learning curve)
- Slightly harder to debug than a regular server

**Verdict:** This is the cleanest approach for a small team with no DevOps experience. Start here, move to Render only if you outgrow it.

---

#### Option C: Railway

**URL:** https://railway.app

**Free tier:** $5 of credit/month — covers a small Node.js server running ~24/7  
**No sleep/cold start issue** — always on  
**Slightly easier setup than Render**

**Paid:** After free credit runs out, roughly $5–10/month based on usage

**Best for:** If cold start on Render bothers you and you don't want to set up the ping workaround.

---

#### Option D: Google Cloud Run

**Free tier:** 2 million requests/month + 360,000 GB-seconds compute — effectively free at our scale

**How it works:** Package backend in a Docker container, Google runs it and scales automatically

**Pros:** If you're already on Google Cloud for the Places API, one billing account covers everything  
**Cons:** Requires knowing Docker basics — more complex setup

---

### Comparison Table

| Service | Monthly cost | Cold start on idle? | Setup difficulty | Verdict |
|---------|-------------|--------------------|-----------------|---------| 
| **Supabase Edge Functions** | ₹0 | None | Medium | ✅ Best for starting |
| **Render (free)** | ₹0 | Yes (fixable free) | Very easy | ✅ Good alternative |
| **Railway** | ₹420 credit free | No | Very easy | Good if cold start bothers you |
| **Google Cloud Run** | ₹0 | Minor | Hard (Docker) | Use if you know Docker |
| **Heroku** | $5/month min | No | Easy | Not worth it, use Railway |
| **AWS / Azure** | Complex | No | Very hard | Overkill for now |

**Recommendation: Start with Supabase Edge Functions. Add Render if complexity increases.**

---

### Android App Distribution

The Flutter app does not need server deployment. Users get it one of two ways:

#### For testing / early users: Share APK directly
```
flutter build apk --release
→ Share the APK file via WhatsApp / Google Drive / email
→ Users enable "Install from unknown sources" in phone settings and install
```
**Cost: ₹0**  
Use this during development and for testing with your first group of friends.

#### For public launch: Google Play Store
```
flutter build appbundle --release
→ Upload to Google Play Console
→ Fill store listing, add screenshots, privacy policy
→ Submit for review (1–3 days first time, much faster after)
→ Users install from Play Store like any other app
```
**Cost: ₹2,100 one-time** (Google Play Developer account — never recurring)

There is no free way to publish on the Play Store. ₹2,100 is the one-time fee and you never pay it again regardless of how many apps you publish.

---

## 9. Database Schema

```sql
-- USERS
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  phone TEXT UNIQUE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  username TEXT UNIQUE,
  fcm_token TEXT,              -- for push notifications, updated on each login
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- GROUPS (persistent friend groups, reusable across sessions)
CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  mode TEXT NOT NULL CHECK (mode IN ('hunger', 'travel')),
  created_by UUID REFERENCES users(id),
  invite_code TEXT UNIQUE NOT NULL,   -- 6-char alphanumeric e.g. "ABX7K2"
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- GROUP MEMBERS
CREATE TABLE group_members (
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'member')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (group_id, user_id)
);

-- SESSIONS (one swipe round = one session)
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id),   -- NULL for solo sessions
  user_id UUID REFERENCES users(id),     -- solo player OR group owner who created it
  mode TEXT NOT NULL CHECK (mode IN ('hunger', 'travel')),
  type TEXT NOT NULL CHECK (type IN ('group', 'solo')),
  status TEXT DEFAULT 'setup' CHECK (
    status IN ('setup', 'swiping', 'revealed', 'completed')
  ),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- INPUT LOCATIONS (areas members want restaurant suggestions from)
CREATE TABLE session_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  added_by UUID REFERENCES users(id),
  place_name TEXT NOT NULL,          -- e.g. "Bandra West, Mumbai"
  lat DECIMAL(10, 8),
  lng DECIMAL(11, 8),
  radius_km INT DEFAULT 3,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- SUGGESTED PLACES (fetched from Google Places, stored per session)
CREATE TABLE suggested_places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  google_place_id TEXT NOT NULL,
  name TEXT NOT NULL,
  address TEXT,
  lat DECIMAL(10, 8),
  lng DECIMAL(11, 8),
  rating DECIMAL(2, 1),
  rating_count INT,
  price_level INT,                   -- 1 to 4 (₹ to ₹₹₹₹)
  is_open_now BOOLEAN,
  opening_hours_display TEXT,        -- e.g. "Open until 11:30 PM"
  phone TEXT,
  website_url TEXT,                  -- used as "View Menu" deep-link
  google_maps_uri TEXT,              -- direct link to Google Maps page
  dineout_url TEXT,                  -- constructed dineout search URL
  eazydiner_url TEXT,                -- constructed eazydiner search URL
  photos JSONB,                      -- [{photo_name, url}] array
  reviews JSONB,                     -- [{text, rating, author_name}] array (up to 5)
  cuisine_type TEXT,                 -- primaryTypeDisplayName from Places API
  display_order INT,                 -- ranking (1 = shown first)
  cached_at TIMESTAMPTZ DEFAULT NOW()
);

-- SWIPES
CREATE TABLE swipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  place_id UUID REFERENCES suggested_places(id),
  direction TEXT NOT NULL CHECK (direction IN ('yes', 'no')),
  swiped_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (session_id, user_id, place_id)  -- prevent duplicate swipes
);

-- SESSION RESULTS (computed once all members finish swiping)
CREATE TABLE session_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  place_id UUID REFERENCES suggested_places(id),
  yes_votes INT DEFAULT 0,
  no_votes INT DEFAULT 0,
  vote_percentage DECIMAL(5, 2),
  rank INT,
  is_winner BOOLEAN DEFAULT FALSE
);

-- BILL SPLITS (manual amount entry — no photo, no OCR)
CREATE TABLE bill_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES sessions(id),
  entered_by UUID REFERENCES users(id),
  total_amount DECIMAL(10, 2) NOT NULL,  -- e.g. 3200.00
  currency TEXT DEFAULT 'INR',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- BILL SPLIT SHARES (one row per group member)
CREATE TABLE bill_split_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id UUID REFERENCES bill_splits(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  amount DECIMAL(10, 2) NOT NULL,   -- auto-calculated as total / member count
  is_paid BOOLEAN DEFAULT FALSE,
  paid_at TIMESTAMPTZ
);

-- BOOKINGS (log when user taps a booking button — no actual booking API)
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES sessions(id),
  place_id UUID REFERENCES suggested_places(id),
  booked_by UUID REFERENCES users(id),
  booking_platform TEXT CHECK (
    booking_platform IN ('dineout', 'eazydiner', 'google_maps')
  ),
  party_size INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- MEMORIES (auto-created when session completes — feeds history screen)
CREATE TABLE memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  session_id UUID REFERENCES sessions(id),
  group_id UUID REFERENCES groups(id),   -- NULL for solo sessions
  title TEXT,                            -- "Friday Night — Neon Lotus"
  winner_place_name TEXT,
  winner_place_photo TEXT,
  total_spent DECIMAL(10, 2),            -- from bill split if entered
  participant_count INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 10. API Endpoints (Backend Routes)

### Auth
```
POST  /auth/register          → { email?, phone?, display_name, password? }
POST  /auth/login             → returns Supabase JWT session
POST  /auth/google            → Google ID token → returns JWT session
POST  /auth/phone/send-otp    → { phone } → sends OTP via Supabase
POST  /auth/phone/verify-otp  → { phone, otp } → returns JWT session
POST  /auth/logout
GET   /auth/me                → current user profile
PUT   /auth/profile           → update display_name, avatar_url, fcm_token
```

### Groups
```
POST   /groups                      → create { name, mode: 'hunger'|'travel' }
GET    /groups                      → all groups I'm a member of
GET    /groups/:id                  → group details + member list
POST   /groups/:id/invite           → generate/refresh 6-char invite code
POST   /groups/join/:code           → join via invite code
DELETE /groups/:id/members/:userId  → remove member (owner only)
GET    /groups/:id/history          → all past completed sessions for this group
```

### Sessions
```
POST  /sessions                   → create { group_id?, mode, type: 'group'|'solo' }
GET   /sessions/:id               → session state + details
POST  /sessions/:id/locations     → add { place_name, lat?, lng?, radius_km }
GET   /sessions/:id/locations     → list all added locations
POST  /sessions/:id/generate      → fetch places from Google API, notify group
PUT   /sessions/:id/start         → move status → 'swiping', notify all members
GET   /sessions/:id/places        → list of 15–20 enriched place cards
POST  /sessions/:id/swipes        → record { place_id, direction: 'yes'|'no' }
GET   /sessions/:id/progress      → { done: 3, total: 5 }
GET   /sessions/:id/results       → ranked list (only returns when all members voted)
PUT   /sessions/:id/reveal        → compute winner, broadcast, move status → 'revealed'
GET   /sessions/:id/summary       → solo: all swiped places with full details
```

### Bill Split (manual amount, no image)
```
POST  /sessions/:id/bill           → { total_amount } — auto-splits evenly by member count
GET   /sessions/:id/bill           → bill + per-person amounts + paid status
PUT   /sessions/:id/bill/split     → adjust custom amounts { shares: [{user_id, amount}] }
PUT   /sessions/:id/bill/pay/:userId → mark a member as paid
```

### Booking (log only — actual booking happens in Dineout/EazyDiner)
```
POST  /sessions/:id/booking        → log { platform, party_size }
GET   /sessions/:id/booking        → retrieve booking log
```

### Memories
```
GET    /memories       → current user's full history
GET    /memories/:id   → single memory detail
DELETE /memories/:id   → delete a memory
```

---

## 11. Real-time Events

Using **Supabase Realtime** — all clients in a session subscribe to channel `session:{session_id}`.

| Event | When it fires | Payload |
|-------|-------------|---------|
| `member_joined` | A new member joins the group | `{ user_id, display_name }` |
| `location_added` | A member adds an input location | `{ place_name, added_by }` |
| `places_ready` | Backend finishes fetching places from Google | `{ place_count: 18 }` |
| `swipe_progress` | Any member completes swiping a card | `{ done: 3, total: 5 }` |
| `all_voted` | Last member swipes their last card | triggers countdown + reveal animation |
| `reveal` | Owner confirms reveal | `{ winner, ranked_list }` |
| `bill_entered` | Someone enters the bill amount | `{ total: 3200, per_person: 800 }` |
| `member_paid` | A member marks themselves as paid | `{ user_id, display_name }` |

---

## 12. Group History Bookings Screen

The history screen shows all past sessions for a group. Feeds directly into the existing Memory Lane screen design.

**API call:** `GET /groups/:id/history`

**Response shape:**
```json
{
  "sessions": [
    {
      "id": "session-uuid",
      "created_at": "2026-04-20T19:00:00Z",
      "mode": "hunger",
      "status": "completed",
      "winner": {
        "name": "Neon Lotus",
        "photo_url": "https://lh3.googleusercontent.com/...",
        "cuisine": "Asian Fusion",
        "address": "Bandra West, Mumbai",
        "rating": 4.3,
        "google_maps_uri": "https://maps.google.com/?cid=..."
      },
      "booking": {
        "platform": "dineout",
        "party_size": 4,
        "logged_at": "2026-04-20T20:00:00Z"
      },
      "bill": {
        "total_amount": 3200,
        "currency": "INR",
        "your_share": 800,
        "your_status": "paid"
      },
      "participants": [
        { "display_name": "Alex", "avatar_url": "..." },
        { "display_name": "Sam", "avatar_url": "..." },
        { "display_name": "Rahul", "avatar_url": "..." },
        { "display_name": "Priya", "avatar_url": "..." }
      ],
      "participant_count": 4
    }
  ]
}
```

---

## 13. What We Need From You To Start

### 13A. Accounts to Create (One-time setup)

| Service | Link | What to do | Cost |
|---------|------|-----------|------|
| **Supabase** | https://supabase.com | Sign up → New Project → copy: Project URL + anon key + service_role key | Free |
| **Google Cloud** | https://console.cloud.google.com | New project → Enable "Places API (New)" + "Maps SDK for Android" + "Geocoding API" → Create API key → Add billing card (won't charge within free tier) | Free |
| **Firebase** | https://console.firebase.google.com | New project → Add Android app (enter package name) → Download `google-services.json` | Free |
| **GitHub** | https://github.com | Create repo for backend code | Free |
| **Render** | https://render.com | Sign up with GitHub | Free |

**On the Google billing card requirement:** You must add a card to use the Places API. Google will NOT charge you within the 35,000 free calls/month. Think of it like adding a card to Swiggy — it doesn't charge unless you order beyond what's free. You can set a hard billing cap at ₹0 in Google Cloud Console if you want extra safety.

---

### 13B. Decisions Still Needed From You

**All decisions confirmed ✅**

| Question | Decision |
|----------|---------|
| App name | **Shuffle** |
| Login methods | **Google Sign-In + Phone OTP** |
| Group invite | **Both** — 6-char code + WhatsApp share link |
| Max group size | **10 members** |
| Swipe timeout | **No timeout** — wait for all members to finish |
| Backend platform | **Google Cloud Run** (user is comfortable with Docker) |

### 13C. Credentials Configured ✅

| Service | Status |
|---------|--------|
| Supabase (URL + anon key) | ✅ Set in `lib/config/app_config.dart` |
| Supabase service_role key | ✅ Saved — goes in Cloud Run env vars ONLY, never in app |
| Google Places + Maps SDK API key | ✅ Set in `lib/config/app_config.dart` |
| Firebase `google-services.json` | ✅ Placed at `android/app/google-services.json` |

### 13D. Build Order

```
Week 1–2:   Auth (Google Sign-In + Phone OTP) + User profiles
Week 3–4:   Groups + invite codes + WhatsApp share links
Week 5–6:   Sessions + Google Places API integration + place card data
Week 7–8:   Tinder-style swipe loop + real-time vote progress + reveal
Week 9:     Bill split (manual amount entry + per-person split + paid tracking)
Week 10:    Booking deep-links (Dineout + EazyDiner + Maps) + memory/history screen
Week 11:    Push notifications (FCM) for invites, all-voted, reveal
Week 12:    Testing on Android devices + bug fixes + Play Store submission
```
