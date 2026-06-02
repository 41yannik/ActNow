# ActNow — Prototype Design Port, Phase 1 Report

## Why

The `actnow vorlage` folder is the **design source of truth**: a high-fidelity React/JSX
clickable prototype built from the pitch deck. This work brings the prototype's **design
language, screens, and features** into the real **SvelteKit + Supabase** app.

Two hard constraints were respected throughout:

1. **Backend stayed the same for Phase 1.** No schema changes were needed for the Discover
   slice. Features the prototype shows but the backend still can't support are built as
   **front-end design shells driven by mock data**, each flagged in code with
   `// TODO(backend)`.
2. **Foundations stay the same.** SvelteKit, the `$lib/components/*` library, services,
   stores, and types are reused and extended — not rewritten.

Delivery is **phased**; this report covers **Phase 1 (Discover slice)**. Backend follow-up is
tracked in **issue #1**.

## What changed

### Shared design foundation
- **`frontend/src/app.css`** — added the **Caveat** font (prototype tagline) and a `slideUp`
  animation for bottom sheets.
- **`frontend/static/logo_actnow.png`** — prototype logo asset.
- **`frontend/src/lib/components/layout/SageHeader.svelte`** *(new)* — the reusable sage
  header band (centered logo, title/subtitle, bell + unread badge, trailing slot). Replaces
  the per-page mobile header.
- **`frontend/src/lib/components/layout/BottomNavBar.svelte`** — restyled to the prototype's
  **5-tab** nav (Social · Rewards · **Start** raised center · Favoriten · Profil).
- **`frontend/src/routes/(helper)/+layout.svelte`** — wired the 5-tab nav + matching desktop
  top-nav; `TopNavBar` is now desktop-only so the `SageHeader` owns the mobile header.
- Design tokens / Button / MobileTopBar / `app.html` theme-color — Sage/Olive/Cream system
  (`tailwind.config.js`, `Button.svelte`, `MobileTopBar.svelte`).

### Discover
- **`frontend/src/routes/(helper)/discover/+page.svelte`** — `SageHeader` greeting (`Hallo
  {name} · {city}`) + Kalender chip, a horizontal **day strip**, the swipe deck, an action
  bar with hint row. Swipe right → apply; bookmark / ♥ → save.
- **`frontend/src/lib/features/offers/components/SwipeCard.svelte`** — full redesign:
  category badge, SOS pill, bookmark, friends pill, meta rows (location/date/duration),
  description, and the "Passt in deinen Kalender" match badge. BEWERBEN / NICHTS FÜR DICH
  drag stamps.
- **`frontend/src/lib/features/offers/components/SwipeDeck.svelte`** — forwards
  save/open/saved-state to the top card; deck height made responsive for phones.

### Offer detail (new screen)
- **`frontend/src/routes/(helper)/offers/[id]/+page.svelte`** *(new)* — hero image, org row
  (verified + rating), facts grid, "Was du brauchst" requirements, "Wer ist dabei?" friends,
  calendar-fit banner, sticky CTA, and a **bottom-sheet apply confirmation** that calls
  `createApplication`. Detects an existing application and shows "✓ Bewerbung gesendet".

### Real backend wiring (no schema change)
- **`frontend/src/lib/services/supabase/savedOffers.ts`** *(new)* — `list / save / unsave`
  against the existing `saved_offers` table; **`SavedOfferRow`** added to `types/database.ts`.
- **`(helper)/favorites`** now reads the existing `saved_offers` table, displays compact saved
  offer cards, marks unavailable saved offers in red, and supports secure remove/open actions.

### Placeholders (built out in later phases)
- `(helper)/rewards` — minimal page so the new 5-tab nav never 404s.

### Community / Chat v1 (implemented after Phase 1)
- `(helper)/community` now uses real Supabase `conversations`, `messages`, and
  `notifications` data.
- Community has Chats + Activity tabs, real unread counts, Realtime refreshes, and links into
  `/messages/[id]`.
- The backend now includes Community RPCs for conversation lists, unread summary, and
  marking conversations read.

## Backend flag

Prototype-only, **mock** data lives in
**`frontend/src/lib/features/offers/mockEnrich.ts`** (friends, distance/km, SOS, calendar-fit),
all marked `// TODO(backend)`. Rewards, org-follow, and onboarding verification remain
design shells. Community/Chat and offer Favorites are no longer design shells and are connected
to real Supabase data.

## New backend issue

Filed **[#1 — Backend: support features introduced by the prototype design port](https://github.com/dmu1981/ActNow/issues/1)**
to track matching the backend to these front-end changes (urgent-offer flag, rewards model,
follow model, calendar integration).

## Incidental bug fixes
- `TopNavBar` and `CategoryBadge` accepted a `class` / `style` prop but never applied it.
- `AppShell`'s `<main>` lacked `min-w-0`, causing ~672px horizontal overflow on mobile.

## Verification
- `npm run check` → **0 errors**.
- Logged in as `helper1@actnow.test` and walked Discover, the 5-tab nav, the offer detail,
  and the full apply flow (confirm sheet → "Ja, bewerben" → button flips) — no page errors.

## Not in scope (Phase 1)
- Backend/schema changes (tracked in #1).
- Phases 2–4: organization Favorites, Rewards, Profile, Calendar, Onboarding.
- The prototype's iOS device frame.
