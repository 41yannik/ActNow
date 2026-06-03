# Acceptance Criteria - ActNow

Status: Arbeitsstand fuer die naechsten Umsetzungsphasen. Dieses Dokument ergaenzt die
Roadmap um pruefbare Kriterien pro Gate und Feature.

## Globales Feature-Gate

Ein Feature gilt erst als fertig, wenn alle Punkte zutreffen:

- Fachlicher Scope ist in `docs/road-map.md` oder einer verlinkten Spezifikation beschrieben.
- Datenmodell, API-Vertrag und Supabase-RLS sind geprueft oder aktualisiert.
- Frontend nutzt Services aus `frontend/src/lib/services` statt direkter Datenbanklogik in
  Komponenten.
- Loading-, Empty-, Error- und Success-State sind vorhanden.
- Mobile und Desktop wurden visuell geprueft.
- Seed-Daten erlauben eine lokale Pruefung des Features.
- Dokumentation und Roadmap sind aktualisiert.
- `corepack pnpm run check` laeuft mit 0 Fehlern und 0 Warnungen.
- `corepack pnpm run build` laeuft erfolgreich.

## Prioritaet 0 - Arbeitsfaehigkeit

Das Projekt ist arbeitsfaehig, wenn:

- `frontend/package.json` einen eindeutigen `packageManager` enthaelt.
- `corepack pnpm --version` die erwartete pnpm-Version liefert.
- `corepack pnpm install --frozen-lockfile` ohne Lockfile-Aenderung erfolgreich ist.
- `frontend/node_modules/.pnpm` keine Finder-/iCloud-Duplikate wie `* 2` enthaelt.
- `.svelte-kit` durch `svelte-kit sync` erzeugt wird.
- `corepack pnpm run check` mit 0 Fehlern und 0 Warnungen endet.
- `corepack pnpm run build` erfolgreich endet.
- `scripts/bootstrap-frontend.sh --clean` das Frontend reproduzierbar neu aufsetzt.

## Helper MVP

### Registrierung und Login

- Helper und Organisation koennen sich mit E-Mail und Passwort registrieren.
- Signup-Metadaten erzeugen automatisch das passende Profil.
- Login setzt Session und Profil im Auth-Store.
- Fehler fuer bestehende E-Mail, schwaches Passwort und Netzwerkprobleme sind sichtbar.
- Rollenbasierte Redirects sind nach Login nachvollziehbar.

### Discover und Swipe

- Feed laedt nur sichtbare, passende Angebote ueber `search_offers`.
- Ort, Datum, Uhrzeit, Kategorie, remote/digital und Angebotstyp wirken auf die Query.
- Swipe links entfernt ein Angebot aus der aktuellen Queue.
- Swipe rechts erstellt genau eine Bewerbung oder erklaert, warum keine weitere Bewerbung moeglich ist.
- Favoriten-Toggle ist zwischen Discover, Detail und Favoritenliste konsistent.
- Queue, Undo und Empty-State bleiben nach Aktionen stabil.

### Angebotsdetail

- Detailseite zeigt echte Angebotsdaten und Organisation.
- CTA-Regeln respektieren `published`, `paused`, `filled`, `completed`, `cancelled` und `archived`.
- Bewerbung aus der Detailseite erzeugt eine Application und eine Conversation.
- Bereits beworbene Helper sehen den bestehenden Status statt einer zweiten Bewerbung.
- Dokumentanforderungen, Bilder und Organisationsprofil sind angebunden oder bewusst ausgeblendet.

### Bewerbungen und Einsaetze

- Helper sehen aktive Bewerbungen mit Status.
- Zugesagte Einsaetze sind separat sichtbar.
- Helper koennen eine offene Bewerbung zurueckziehen.
- Statuswechsel werden im UI eindeutig dargestellt.
- Jede Bewerbung und jeder Einsatz zeigt eine nachvollziehbare Timeline mit Einreichung,
  Statusereignissen und relevanten Application-Notifications.
- Zugesagte Einsaetze zeigen Reminder fuer 24h und 2h vor Einsatzbeginn als geplant, faellig
  oder gesendet.
- Helper koennen aus einer Bewerbung direkt den bewerbungsgebundenen Chat oeffnen.
- Seed-Daten enthalten Beispiele fuer submitted, shortlisted, accepted, rejected, withdrawn und
  completed sowie einen nahen zugesagten Einsatz mit Reminder.
- Kalender kann akzeptierte Einsaetze anzeigen.

### Favoriten

- Helper sehen nur eigene Favoriten.
- Entfernen wirkt optimistisch und rollt bei Fehlern zurueck.
- Nicht verfuegbare Angebote sind sichtbar als nicht verfuegbar markiert.
- Fremde Favoriten sind per RLS nicht lesbar oder manipulierbar.

### Community und Notifications

- Community zeigt Chats und Aktivitaeten getrennt.
- Unread Counts kommen aus `get_community_summary`.
- Neue Nachrichten werden per Realtime sichtbar, ohne Duplikate.
- Oeffnen eines Chats markiert fremde Nachrichten als gelesen.
- Notification-Links fuehren zum passenden Ziel oder zeigen einen klaren Fallback.

## Organisation MVP

- Organisation kann Profil pflegen.
- Organisation kann Angebote erstellen, bearbeiten, veroeffentlichen, pausieren und archivieren.
- Bewerbungen pro Angebot sind sichtbar.
- Organisation kann Bewerbungen annehmen, ablehnen und Helfer anschreiben.
- Dashboard-Metriken stammen aus echten Daten.

## Production Readiness

- Kritische Flows haben automatisierte Tests.
- RLS-Test-Suite deckt positive und negative Rollenfaelle ab.
- Staging-Deployment nutzt kein Produktiv-Seed mit Testpasswoertern.
- Monitoring, Logging und Backup-/Restore-Prozess sind dokumentiert.
- Rechtliche Seiten und Datenschutzentscheidungen sind final.
