# ActNow Dokumentation

Dieses Verzeichnis ist die zentrale Inhaltsübersicht für das ActNow-Masterprojekt. Das aktive
Portfolio-Frontend ist eine statische Demo; Backend-, Schema- und API-Dokumente beschreiben die
historische, nicht mehr angebundene Produktarchitektur.

## Inhaltsverzeichnis

- [Road Map](./road-map.md) - operativer Gesamtplan von aktuellem Stand bis Production Readiness.
- [Problem Statement](./problem-statement.md) - Zielbild, Zielgruppen und Kernproblem.
- [User Roles](./user-roles.md) - Rollenmodell und Verantwortlichkeiten.
- [User Stories](./user-stories.md) - fachliche Nutzeranforderungen fuer Helper, Organisationen,
  Admins und allgemeine Nutzer.
- [Technical Requirements](./technical-requirements.md) - Technologie-Stack, Architektur,
  Typisierung, RLS und Betriebsanforderungen.
- [Data Model](./data-model.md) - fachliches Datenmodell und Tabellenstruktur.
- [API Contract](./api-contract.md) - historischer Supabase-/Frontend-Contract.
- [Schema SQL](./schema.sql) - eingefrorene historische Schema-Referenz.
- [Seed SQL](./seed.sql) - historische lokale Entwicklungsdaten.
- [Design Port Phase 1 Report](./design-port-phase1-report.md) - aktueller Design-Port-Stand und
  Backend-Flags.
- [UI Screens](./ui-screens.md) - Screen-Inventar, UI-Regeln und offene produktive Screens.
- [Acceptance Criteria](./acceptance-criteria.md) - Feature-Gates und pruefbare Kriterien.
- [Deployment](./deployment.md) - statischer Build und Release-Gates.
- [Portfolio-Demo](./demo-deployment.md) - GitHub Pages, Custom Domain und HTTPS.

## Nutzung

Vor fachlichen oder technischen Aenderungen zuerst `road-map.md` und die betroffenen
Spezifikationsdateien pruefen. Wenn ein Feature umgesetzt wird, muessen Roadmap, Schema/API-Doku
und Seed-Daten konsistent bleiben.
