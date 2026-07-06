# Demo-Deployment (Portfolio-Showcase)

Die App läuft als **read-only Demo** unter **https://actnow.yannik-h-huber.de** —
zum Vorzeigen, nicht zur produktiven Nutzung.

## Architektur

```
Besucher ──► GitHub Pages (statischer SPA-Build, VITE_DEMO_MODE=true)
                  │
                  ▼
             Supabase-Staging fhqgbenlufdqbihmmdrq (eu-central-1)
             App-Rollen ohne Schreibprivilegien (siehe supabase/README.md)
```

- **Auto-Login:** Besucher werden automatisch als Demo-Helferin „Anna" angemeldet
  (`frontend/src/lib/config/demo.ts`); eine Top-Leiste (`DemoBar.svelte`) erlaubt
  das Umschalten auf die Vereins-Ansicht (SV Sonnenschein).
- **Schreibblockade, zweistufig:**
  1. Frontend: `demoGuard()` in allen mutierenden Service-Funktionen
     (`frontend/src/lib/services/supabase/*`) — freundliche Toast-Meldung.
  2. Datenbank: `authenticated`/`anon` haben keine INSERT/UPDATE/DELETE-Privilegien
     und keinen EXECUTE auf mutierenden RPCs (Toggle siehe
     [supabase/README.md](../supabase/README.md#demo-modus-read-only)).
- Login-/Register-Seiten leiten im Demo-Modus um; Abmelden ist ausgeblendet.
- Die Demo-Zugangsdaten (`actnow-dev`) sind bewusst öffentlich — die DB ist
  read-only und Sign-ups sind deaktiviert.

## Build & Deploy

- `frontend/` baut mit `@sveltejs/adapter-static` (`fallback: index.html`, reine
  Client-SPA). `static/CNAME` (= `actnow.yannik-h-huber.de`) und `static/.nojekyll`
  landen im Build.
- [.github/workflows/deploy-pages.yml](../.github/workflows/deploy-pages.yml)
  deployt bei jedem Push auf `master` (Build mit `VITE_DEMO_MODE=true`,
  `404.html` = SPA-Fallback für GitHub Pages).
- [.github/workflows/keepalive.yml](../.github/workflows/keepalive.yml) pingt das
  Free-Tier-Supabase 2×/Woche an, damit es nicht pausiert. Falls es doch pausiert,
  zeigt die Demo ein Fehlerbanner; im Supabase-Dashboard reaktivieren.

### Einmalige Einrichtung (Repo-Admin, GitHub-UI)

1. **Settings → Pages → Source: „GitHub Actions"** (erfordert Admin-Rechte auf
   `dmu1981/ActNow`).
2. Nach dem ersten Deploy: **Settings → Pages → Custom domain:**
   `actnow.yannik-h-huber.de` eintragen, DNS-Check abwarten, dann
   **Enforce HTTPS** aktivieren (Zertifikat kann bis ~24 h dauern).
3. **Supabase-Dashboard → Authentication → Sign In / Up:** „Allow new users to
   sign up" **deaktivieren** (GoTrue schreibt mit eigener Rolle und wäre sonst
   trotz Privilegien-Entzug in der Lage, Accounts anzulegen).

Hinweis: Die Zwischen-URL `dmu1981.github.io/ActNow` funktioniert **nicht**
(absolute Asset-Pfade) — die Demo ist erst über die Custom Domain nutzbar.

## Hetzner-DNS (einmalig, vom Domain-Inhaber)

In der Hetzner-DNS-Konsole für `yannik-h-huber.de` einen Eintrag anlegen:

| Typ   | Name     | Wert                 |
| ----- | -------- | -------------------- |
| CNAME | `actnow` | `dmu1981.github.io.` |

(TTL Standard. Der Name im GitHub-Pages-Custom-Domain-Feld muss exakt dem
Inhalt von `frontend/static/CNAME` entsprechen.)

## Demo lokal testen

```bash
cd frontend
VITE_DEMO_MODE=true corepack pnpm build && corepack pnpm preview
# Achtung: `vite preview` cached die Fallback-HTML — nach jedem Rebuild neu starten.
```

## Demo-Modus wieder abschalten (für Weiterentwicklung)

1. Schreibprivilegien wiederherstellen: SQL-Block „OFF" in
   [supabase/README.md](../supabase/README.md#demo-modus-read-only).
2. Sign-ups im Dashboard wieder aktivieren.
3. Deploys pausieren: `deploy-pages.yml` Trigger entfernen oder Workflow im
   GitHub-UI deaktivieren.
