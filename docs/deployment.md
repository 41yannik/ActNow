# Deployment - ActNow

Status: Arbeitsfaehiger lokaler Build ist hergestellt. Ein konkretes Hosting-Ziel ist noch nicht
entschieden.

## Lokales Frontend

Voraussetzungen:

- Node.js 22.x
- Corepack
- Zugriff auf das Repository

Setup und Verifikation:

```bash
cd frontend
corepack prepare pnpm@10.24.0 --activate
corepack pnpm install --frozen-lockfile
corepack pnpm run check
corepack pnpm run build
```

Alternativ vom Repository-Root:

```bash
./scripts/bootstrap-frontend.sh --clean
```

`--clean` entfernt nur generierte Frontend-Artefakte (`node_modules`, `.svelte-kit`) und baut sie
aus dem Lockfile neu auf.

## Lokales Backend

Supabase bleibt in dieser Entwicklungsphase schema-basiert:

- `docs/schema.sql` ist die aktuelle Schema-Quelle.
- `docs/seed.sql` enthaelt lokale Entwicklungsdaten.
- `supabase/README.md` beschreibt Reset, Schema-Apply und Seed.

Backend-Befehle:

```bash
supabase start
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/schema.sql
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/seed.sql
```

## Environment Variables

Frontend benoetigt nur Vite-Variablen:

```bash
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
```

Root-/Backend-Umgebung siehe `.env.example`:

```bash
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
SUPABASE_DB_URL=
```

`SUPABASE_SERVICE_ROLE_KEY` darf niemals in Browser-Code oder ein oeffentliches Frontend-Bundle.

## Aktueller Build-Stand

- `corepack pnpm run check`: muss 0 Fehler und 0 Warnungen liefern.
- `corepack pnpm run build`: muss erfolgreich sein.
- `@sveltejs/adapter-auto` baut lokal, meldet aber ohne Hosting-Umgebung, dass kein konkretes
  Production-Ziel erkannt wurde.

## Hosting-Entscheidung

Offen fuer M4:

- Netlify
- Vercel
- anderer SvelteKit-kompatibler Hoster

Nach Entscheidung:

- passenden SvelteKit-Adapter konfigurieren, falls `adapter-auto` nicht ausreicht.
- Staging-Projekt in Supabase erstellen.
- Staging-Environment-Variablen setzen.
- Schema-Apply-Prozess fuer Staging definieren.
- Seed-Prozess ohne Testpasswoerter fuer produktionsnahe Umgebungen definieren.

## Release-Checkliste

Vor jedem Preview- oder Production-Release:

- Git-Arbeitsbaum ist sauber oder die Release-Aenderungen sind bewusst gestaged.
- `corepack pnpm install --frozen-lockfile` laeuft.
- `corepack pnpm run check` laeuft mit 0 Fehlern und 0 Warnungen.
- `corepack pnpm run build` laeuft.
- Supabase-Schema/API-Aenderungen sind dokumentiert.
- RLS-Auswirkungen sind geprueft.
- Relevante Seed-Daten fuer lokale Pruefung existieren.
- Roadmap und Acceptance Criteria sind aktualisiert.
