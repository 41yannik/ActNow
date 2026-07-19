# ActNow Portfolio-Demo

Das Frontend ist eine vollständig statische, interaktive Portfolio-Demo. Alle sichtbaren Daten
sind fiktive TypeScript-Fixtures. Es gibt keine Anmeldung, kein Backend, keine Datenübertragung und
keine dauerhaften Änderungen im Browser.

## Lokale Entwicklung

Voraussetzungen: Node.js 22 und Corepack.

```bash
corepack pnpm install --frozen-lockfile
corepack pnpm dev
```

Die App benötigt keine `.env`-Datei und keine Zugangsdaten.

## Qualitätsprüfung

```bash
corepack pnpm lint
corepack pnpm check
corepack pnpm exec playwright install chromium
corepack pnpm test:e2e
corepack pnpm build
corepack pnpm preview
```

Der statische Build wird nach `frontend/build/` geschrieben und über GitHub Pages veröffentlicht.

## Demo-Verhalten

- Beide Rollen sind ohne Login über die Startseite oder die Demo-Leiste erreichbar.
- Navigation, Filter, Tabs, Formulare und Swipe-Deck funktionieren lokal.
- Schreibende Aktionen zeigen einen Demo-Hinweis und verändern keine Daten.
- Ein Reload stellt den Fixture-Ausgangszustand wieder her.
- Fonts und Icons werden mit dem Build ausgeliefert; es gibt keine externen Laufzeitanfragen.
