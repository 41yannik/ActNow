# Deployment – ActNow Portfolio-Demo

Das einzige aktive Deployment-Ziel ist GitHub Pages mit der Custom Domain
`actnow.yannik-h-huber.de`. Die Anwendung ist eine statische SPA und benötigt keine
Laufzeitumgebung, Datenbank, Zugangsdaten oder Environment-Variablen.

## Lokale Prüfung

```bash
cd frontend
corepack pnpm install --frozen-lockfile
corepack pnpm lint
corepack pnpm check
corepack pnpm exec playwright install chromium
corepack pnpm test:e2e
corepack pnpm build
corepack pnpm preview
```

## Release-Gates

- Lint, Svelte-Typprüfung und Build sind erfolgreich.
- Es gibt keine Supabase-, Realtime- oder externe Font-Abhängigkeit im Frontend.
- Alle Demo-Routen laden ausschließlich fiktive lokale Daten.
- Schreibende Aktionen verändern keine Fixtures und keinen Browser-Speicher.
- Die Rechtsseiten verweisen auf die zentralen, aktuellen Portfolio-Rechtstexte.

Die konkrete Pages-, DNS- und HTTPS-Konfiguration ist in
[`demo-deployment.md`](./demo-deployment.md) beschrieben.
