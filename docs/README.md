# ActNow Dokumentation

Dieses Verzeichnis ist die zentrale Inhaltsuebersicht fuer Produkt, Technik, Datenmodell und
Umsetzungsplanung der ActNow Web App.

## Inhaltsverzeichnis

- [Road Map](./road-map.md) - operativer Gesamtplan von aktuellem Stand bis Production Readiness.
- [Problem Statement](./problem-statement.md) - Zielbild, Zielgruppen und Kernproblem.
- [User Roles](./user-roles.md) - Rollenmodell und Verantwortlichkeiten.
- [User Stories](./user-stories.md) - fachliche Nutzeranforderungen fuer Helper, Organisationen,
  Admins und allgemeine Nutzer.
- [Technical Requirements](./technical-requirements.md) - Technologie-Stack, Architektur,
  Typisierung, RLS und Betriebsanforderungen.
- [Data Model](./data-model.md) - fachliches Datenmodell und Tabellenstruktur.
- [API Contract](./api-contract.md) - erwartete Supabase-Queries, RPCs und Frontend-Contracts.
- [Schema SQL](./schema.sql) - aktuelle Supabase-Schema-Quelle.
- [Seed SQL](./seed.sql) - lokale Entwicklungsdaten.
- [Design Port Phase 1 Report](./design-port-phase1-report.md) - aktueller Design-Port-Stand und
  Backend-Flags.
- [UI Screens](./ui-screens.md) - Platz fuer Screen-Spezifikation und UI-Akzeptanz.
- [Acceptance Criteria](./acceptance-criteria.md) - Platz fuer Feature-Akzeptanzkriterien.
- [Deployment](./deployment.md) - Platz fuer Deployment-Annahmen und Release-Prozess.

## Nutzung

Vor fachlichen oder technischen Aenderungen zuerst `road-map.md` und die betroffenen
Spezifikationsdateien pruefen. Wenn ein Feature umgesetzt wird, muessen Roadmap, Schema/API-Doku
und Seed-Daten konsistent bleiben.
