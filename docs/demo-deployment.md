# Statische Portfolio-Demo

ActNow wird als rein statische SvelteKit-SPA über GitHub Pages veröffentlicht. Die Demo ist ein
Masterprojekt zum Erkunden und keine produktive Vermittlungsplattform.

## Architektur

```text
Besucher → GitHub Pages → statische HTML-, CSS-, JavaScript-, Font- und Bilddateien
```

- Kein Backend, Supabase-Projekt, Login, Realtime oder externer Datendienst.
- Fiktive Beispieldaten liegen in `frontend/src/lib/demo/fixtures.ts`.
- Das lokale `DemoRepository` stellt ausschließlich Leseoperationen bereit.
- Schreibende UI-Aktionen zeigen einen Hinweis und verändern keine Daten.
- Es werden weder Browser-Speicher noch Cookies für einen Demo-Zustand verwendet.

## Build und Deployment

Der Workflow `.github/workflows/deploy-pages.yml` prüft und baut das Frontend bei jedem Push auf
`master`. Unbekannte Pfade werden über eine Kopie von `index.html` als `404.html` an die SPA
zurückgegeben.

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

Environment-Variablen oder Secrets werden nicht benötigt.

## Custom Domain und HTTPS

1. In GitHub unter **Settings → Pages** die Quelle **GitHub Actions** wählen.
2. `actnow.yannik-h-huber.de` als Custom Domain speichern.
3. Beim DNS-Anbieter einen CNAME `actnow` auf `41yannik.github.io.` setzen und widersprüchliche
   A-/AAAA-Einträge entfernen.
4. Die Domain über den von GitHub angebotenen TXT-Eintrag verifizieren.
5. Nach erfolgreicher Zertifikatsausstellung **Enforce HTTPS** aktivieren.

Wenn das Zertifikat nicht zum Hostnamen passt, die Custom Domain in den Pages-Einstellungen
entfernen und erneut eintragen. Falls CAA-Einträge verwendet werden, muss `letsencrypt.org`
zugelassen sein. DNS- und Zertifikatsänderungen können bis zu 24 Stunden benötigen.

## Manueller Release-Check

- `http://actnow.yannik-h-huber.de` leitet auf HTTPS um.
- Das Zertifikat gilt für `actnow.yannik-h-huber.de`.
- Startseite und direkte Unterseiten funktionieren.
- Beide Rollen lassen sich wechseln.
- Browserkonsole und Netzwerkprotokoll zeigen keine Backend- oder Fremdhost-Anfragen.
- Impressum und Datenschutz verweisen auf die zentralen Rechtstexte unter `yannik-h-huber.de`.

## Historisches Backend

Das Verzeichnis `supabase/` dokumentiert die frühere Backend-Ausarbeitung des Masterprojekts. Es
wird von der Portfolio-Demo weder gebaut noch ausgeführt.
