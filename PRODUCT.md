# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Groups of people in Indian cities who can't agree where to go, plus people exploring on their own. Confirmed audiences:

- **College friends** deciding where to eat or hang out, usually coordinating in a WhatsApp group.
- **The young working crowd**: colleagues and friend groups in their 20s–30s planning dinners, weekend outings and trips.
- **Couples and families**: two to five people who can't agree, often on the spot.
- **Solo users** who want help picking a place fast, or who want to explore somewhere new.

The job, in the user's words: deciding a place, made easy with Tinder-style swiping, so everyone knows which place got the most likes and can go there. Solo use is for exploring new places.

## Product Purpose

Hangout turns "we should hang out sometime" into a decided place. A crew picks a mode (food or places), each member drops a location pin, and everyone swipes on the same real nearby places. The place most people liked wins; the crew then books or gets directions, splits the bill, and the outing is kept as a memory.

Success means a crew goes from "where should we go?" to a chosen place and an action (book, directions) in minutes, with everyone having had an equal say.

## Positioning

Everyone swipes the same shortlist of real places, found around the middle of everyone's locations, and the most-liked place wins, visibly and fairly. Then the same app carries the outing through: booking or directions, and splitting the bill. A group-chat poll or a restaurant directory offers neither the shared swipe nor the end-to-end follow-through.

## Operating Context

- Crews form around an invite: a 6-character code or a WhatsApp share link. Maximum 10 members per crew.
- Members join from their own phones; each adds a location (map pin or area name). Places are searched around the midpoint of the crew's pins.
- Swiping has no time limit; results wait for every member to finish.
- Booking and directions hand off to other apps by deep link: Dineout, EazyDiner and Google Maps for food; Google Maps directions and the venue website for places. Hangout never books or takes payment itself.
- Money is settled person to person over UPI (GPay, PhonePe and similar); Hangout only computes shares and opens the UPI app.
- Solo sessions skip pins from others and let the user browse everything they swiped.

## Capabilities and Constraints

Built today:

- Sign-in with Google or phone OTP (+91).
- Crews: create, join by code, share via WhatsApp, leave or delete, refresh invite code.
- Two modes: food ("hunger") and places ("travel"), each group or solo.
- Group lobby with live location pins; places from the Google Places API (New) around the crew midpoint; filters for cuisine or category, budget, open-now and radius.
- Swipe deck with live group progress; ranked results with vote counts.
- Memories built from finished sessions; a profile with real counts; nickname and one of ten dinosaur avatars.

Confirmed must-ship for the app to be complete:

- **Bill split**: one person enters the total; it splits evenly across attendees; shares can be edited to custom amounts; each person marks themselves paid; a UPI pay button opens the payer's UPI app prefilled with the amount owed to whoever paid. The app never holds or moves money.
- **Push notifications** through Firebase Cloud Messaging for crew invites, "everyone's voted" and the reveal.
- **Full booking and directions**: Dineout, EazyDiner and Google Maps for food; "Get directions" and the website for places.
- **A reveal moment** for the winner, and **solo browse** of every place swiped.

Technical constraints:

- Flutter app talking to Supabase directly (auth, Postgres, realtime). Server-side work runs inside Supabase: bill changes go through Postgres functions that keep shares adding up to the total, and push notifications go out from a **Supabase Edge Function** (`notify`) called by database webhooks. No separate server exists or is planned.
- Android only; India only; prices in ₹.
- Launch goal is the Google Play Store. The package id is **`app.hangout.android`** (renamed from the placeholder `com.company.shuffle`). The Firebase app registration, `google-services.json`, and the Google Sign-In OAuth client must match it; the owner updates those in the Firebase and Google Cloud consoles. Play Store availability of this id has not been checked.
- English only at launch, with every user-facing string externalized so Hindi or regional languages can be added without changing screens.
- Cost target is free tiers at launch (Supabase, Google Places, Firebase).

Session lifecycle: `setup` (lobby, pins) → `swiping` → `revealed` (the host revealed the winner; this is the finished state). `completed` is legacy and treated the same as `revealed` everywhere.

Decided behaviour:

- **The host reveals the winner.** The host is whoever started the session. They can reveal once anyone has finished swiping (with a confirmation if some haven't); the crew is taken to the winner together. There is no timer.
- **A hangout becomes a memory at the reveal.** Any member can later mark it "Didn't go", which removes it from their memories and counts.
- **UPI ID is asked for when splitting.** The person entering the bill gives their UPI ID once; it is saved to their profile and editable on the You tab.

## Brand Commitments

- The product name is **Hangout**, everywhere: app label, store listing, in-app copy. "Shuffle" and "Decisionly" are retired names.
- The Hangout Design System (supplied as `Hangout Design System-handoff.zip`) is the binding visual and voice brief. It includes the two-circle "gathering" mark and wordmark, and the voice of a friend texting the group chat.
- The ten dinosaur avatars and dino-themed generated nicknames stay as a product quirk.
- Delight is **light and honest**: it lives in real moments (the reveal, the memory of where you went, real counts). No points, streaks, badges or invented stats.

## Evidence on Hand

- Real product data comes only from the live backend: crews, sessions, votes and results.
- Place photos, ratings and reviews come from the Google Places API at runtime. The repository contains no real venue photography; the design system's two bundled images are app-mockup screenshots, not photos.
- Bundled fonts (Bricolage Grotesque and Figtree, OFL) are in `assets/google_fonts/`.
- There are no users, testimonials, ratings, press, partnerships or booking integrations to cite. Dineout and EazyDiner are reached by public search links only; there is no partnership or API. None of these may be implied.

## Product Principles

1. **Decide in minutes.** Every screen moves the crew toward one place and one next action; nothing adds a detour.
2. **Every vote counts the same.** The result is transparent: how many said yes, and to what.
3. **Fair by default.** Places are searched around the middle of the crew, and bills split evenly unless someone chooses otherwise.
4. **Honest delight.** Joy comes from real moments, never from fake numbers, streaks or rewards.
5. **Solo is first-class.** Exploring alone is a full use of the app, not a group session missing people.

## Accessibility & Inclusion

- English at launch, with all copy externalized for later Hindi and regional-language support. Layouts must tolerate longer translated strings.
