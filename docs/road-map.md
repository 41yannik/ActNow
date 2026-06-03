# Road Map - ActNow Web App

Stand: 02.06.2026

Diese Roadmap beschreibt den Weg von der aktuellen Codebasis zu einer voll funktionsfaehigen
ActNow-Web-App. Sie ist als operative Checkliste gedacht: bereits umgesetzte Inhalte sind
abgehakt, offene Punkte bleiben als konkrete Arbeitsschritte sichtbar.

Quellen und Abgleich:

- `docs/problem-statement.md`
- `docs/user-roles.md`
- `docs/user-stories.md`
- `docs/technical-requirements.md`
- `docs/data-model.md`
- `docs/api-contract.md`
- `docs/design-port-phase1-report.md`
- aktueller Stand der SvelteKit-App, Supabase-Schema und Seed-Daten

Legende:

- [x] umgesetzt und lokal verifiziert oder in dieser Session umgesetzt
- [ ] offen oder nur teilweise als Shell/Design vorbereitet

## 1. Zielbild

ActNow soll eine mobile-first Web-App fuer ehrenamtliches Engagement werden. Helferinnen und
Helfer finden passende Angebote, bewerben sich, merken Favoriten, kommunizieren mit
Organisationen und verwalten Einsaetze. Organisationen erstellen Angebote, verwalten Bewerbungen,
kommunizieren mit Helfenden und schliessen Einsaetze ab. Admins sichern Qualitaet, Support und
Missbrauchsbehandlung ab.

## 2. Aktueller Stand aus dieser Session

- [x] Lokale Supabase-Datenbank ueber `docs/schema.sql` und `docs/seed.sql` neu ladbar gemacht.
- [x] Community-v1 mit bestehenden Tabellen `conversations`, `messages`, `notifications`,
  `applications`, `offers`, `profiles` verbunden.
- [x] Realtime-Publication fuer `messages`, `conversations` und `notifications` im Schema
  aufgenommen.
- [x] Community-RPCs umgesetzt:
  `list_community_conversations`, `get_community_summary`, `mark_conversation_read`.
- [x] Message-Trigger erweitert:
  `last_message_at` wird gepflegt und Message-Notifications werden erzeugt.
- [x] Message-Update-Schutz ergaenzt, damit nicht beliebige Nutzer Body/Sender/Conversation
  manipulieren.
- [x] Community-Seite mit Tabs fuer Chats und Aktivitaet umgesetzt.
- [x] `/messages` nutzt dieselbe Conversation-Quelle statt doppelte Listenlogik.
- [x] `/messages/[id]` markiert Conversations beim Oeffnen als gelesen und bleibt Chat-Detailroute.
- [x] `notifications.ts` Service fuer Activity-Feed, einzelne Reads und Mark-all-read ergaenzt.
- [x] Seed-Daten fuer sichtbare Chats, unread Messages und Message-Notifications ergaenzt.
- [x] Auth-Initialisierung gegen haengende Session-/Profilabfragen abgesichert.
- [x] Favoriten-V1 mit vorhandener Tabelle `saved_offers` umgesetzt.
- [x] Favoriten-Route `/favorites` ersetzt den Platzhalter durch echte kompakte Angebotskarten.
- [x] Favoriten zeigen nicht verfuegbare Angebote rot als `Nicht verfuegbar`.
- [x] Favoriten-Aktionen bewusst auf `Oeffnen` und `Entfernen` begrenzt.
- [x] `listSavedOffers` liefert nun die gespeicherte Zeile plus zugehoeriges Angebot.
- [x] Seed enthaelt fuer `helper1@actnow.test` zwei Favoriten, davon einen abgeschlossenen.
- [x] Roadmap-relevante Codex-Markierungen bereinigt: Community und Angebot-Favoriten sind nicht
  mehr als reine Design-Shells markiert.
- [x] Discover-Action-Bar optimiert:
  `Karte zurueck`, `Nein`, `Favoriten`, `Bewerben` stehen direkt unter den jeweiligen Buttons.
- [x] Discover-Text `Merken` wurde durch `Favoriten` ersetzt.
- [x] Karten-Icon oben rechts wurde von Bookmark auf Herz geaendert.
- [x] Lokale Browser-Pruefung fuer `/discover`, `/favorites`, `/community` und Chat-Flows
  durchgefuehrt.
- [x] Helper-MVP Bewerbungen/Einsaetze umgesetzt:
  `/applications` zeigt offene Bewerbungen, zugesagte Einsaetze und Verlauf.
- [x] Helper kann Bewerbungen aus `/applications` zurueckziehen.
- [x] Seed-Daten fuer `helper1@actnow.test` decken submitted, shortlisted, accepted, rejected,
  withdrawn und completed ab.
- [x] Status-Timeline je Bewerbung/Einsatz in `/applications` ergaenzt.
- [x] Einsatz-Reminder fuer zugesagte Einsaetze aus Startzeit und Application-Notifications
  abgeleitet.
- [x] Seed-Daten enthalten einen nahen zugesagten Einsatz mit erzeugtem 24h-Reminder und
  geplantem 2h-Reminder.
- [x] `npm run check` im Frontend laeuft mit 0 Fehlern; bestehende Warnungen sind bekannt.

## 3. Projektstruktur und Entwicklungsgrundlagen

### 3.1 Dokumentation und Quellen

- [x] Kernanforderungen liegen in `/docs`.
- [x] `docs/schema.sql` ist aktuelle Schema-Quelle.
- [x] `docs/seed.sql` ist aktuelle Seed-Quelle.
- [x] `docs/design-port-phase1-report.md` dokumentiert Design-Port und aktuelle Backend-Flags.
- [x] Diese Roadmap liegt als `docs/road-map.md` vor.
- [x] `docs/README.md` wird als Inhaltsverzeichnis ergaenzt.
- [x] Leere oder unvollstaendige Dokumente fuellen:
  `acceptance-criteria.md`, `deployment.md`, `ui-screens.md`.
- [x] Roadmap bei jedem groesseren Featureabschluss aktualisieren.

### 3.2 Lokales Setup

- [x] SvelteKit-Frontend unter `frontend/`.
- [x] Supabase-Backend lokal ueber Docker/CLI vorgesehen.
- [x] Lokaler Standard-DB-URL dokumentiert: `postgresql://postgres:postgres@localhost:54322/postgres`.
- [x] Dev-Server laeuft auf `http://127.0.0.1:5173`.
- [x] `.env.example` gegen aktuellen Frontend-/Supabase-Bedarf pruefen und vervollstaendigen.
- [x] Frontend-Bootstrap-Skript fuer neue Entwickler ergaenzt:
  Dependencies installieren, Check und Build ausfuehren.
- [ ] Ein vollstaendiges Bootstrap-Skript fuer neue Entwickler ergaenzen:
  Dependencies installieren, Supabase starten, Schema/Seed laden, Frontend starten.
- [ ] Docker-Setup fuer reproduzierbare lokale Entwicklung dokumentieren und testen.

### 3.3 Qualitaetsregeln

- [x] TypeScript ist aktiv.
- [x] Supabase-Zugriffe laufen ueber Service-Dateien in `frontend/src/lib/services/supabase`.
- [x] UI-Komponenten werden in `frontend/src/lib/components` und `frontend/src/lib/features`
  wiederverwendet.
- [ ] Automatisierte Tests verpflichtend machen:
  Unit, Service, RLS-SQL, Playwright-E2E.
- [ ] CI-Pipeline mit Check, Build, SQL-Smoke-Tests und E2E-Sanity einrichten.
- [x] A11y-Warnungen aus `svelte-check` priorisieren und abbauen.

## 4. Backend und Supabase

### 4.1 Datenmodell

- [x] Tabellen vorhanden:
  `profiles`, `helper_profiles`, `organization_profiles`, `offers`, `offer_recurrences`,
  `applications`, `helper_documents`, `application_document_shares`, `conversations`,
  `messages`, `ratings`, `saved_offers`, `notifications`, `admin_audit_log`, `reports`.
- [x] Enums fuer Rollen, Profile, Organisationstypen, Angebotstypen, Angebotstatus,
  Bewerbungsstatus, Dokumentstatus, Nachrichtstatus und Wiederholungen vorhanden.
- [x] `saved_offers` ist im Schema und Datenmodell als MVP-Bestandteil gefuehrt.
- [ ] Datenmodell gegen alle aktuellen User Stories erneut reviewen.
- [ ] Fehlende Spalten fuer produktive UX entscheiden:
  Angebotsbilder, klare Einsatzdauer, Benachrichtigungseinstellungen, Reminder-Zeitpunkte,
  Meldungsgruende, Admin-Kommentare, Consent-/Privacy-Felder.
- [ ] Optional: Organisation-Favoriten erst nach Produktentscheidung als eigene Tabelle oder
  Follow-Modell entwerfen.

### 4.2 RLS und Sicherheit

- [x] RLS fuer alle App-Tabellen aktiviert.
- [x] Zugriff auf Profile, Angebote, Bewerbungen, Dokumente, Chats, Ratings, Favoriten,
  Notifications, Reports und Audit-Log ueber Policies geregelt.
- [x] Rollenwechsel und sensible Profilfelder werden per Trigger geschuetzt.
- [x] Conversations und Messages sind auf Teilnehmer begrenzt.
- [x] Fremde Favoriten sind per RLS nicht sichtbar oder manipulierbar.
- [x] Fremder Insert in `saved_offers` wurde lokal als blockiert verifiziert.
- [ ] Vollstaendige RLS-Test-Suite als SQL-Datei anlegen.
- [ ] Negative Tests fuer jede Rolle ergaenzen:
  Helper, Organisation, Admin, anon.
- [ ] Security-Review fuer `security definer` RPCs durchfuehren.
- [ ] Datenschutzloeschung definieren:
  Konto deaktivieren, Konto loeschen, personenbezogene Daten anonymisieren.

### 4.3 Authentifizierung und Rollen

- [x] Supabase Auth ist integriert.
- [x] Seed-Accounts fuer Admin, Helper und Organisationen vorhanden.
- [x] Signup-Trigger erstellt Profile automatisch aus Auth-Metadaten.
- [x] Frontend hat Login- und Register-Routen.
- [x] Auth-Store laedt Session und Profil.
- [x] Auth-Store ist gegen endlose Ladezustaende abgesichert.
- [ ] Passwort-Reset-Flow vollstaendig umsetzen und testen.
- [ ] E-Mail-Bestaetigung und produktive Redirect-URLs definieren.
- [ ] Rollenbasierte Redirects und Guards per E2E testen.
- [ ] Account-Deaktivierung und Account-Loeschung umsetzen.

### 4.4 Storage

- [x] Buckets im Schema vorbereitet:
  `avatars`, `offer-images`, `helper-documents`.
- [x] Storage-Policies fuer oeffentliche Avatare und Angebotsbilder vorhanden.
- [x] Private Helper-Dokumente sind auf Owner, Admins und berechtigte Organisationen begrenzt.
- [ ] Frontend-Upload fuer Avatar einbauen.
- [ ] Frontend-Upload fuer Angebotsbilder einbauen.
- [ ] Frontend-Upload fuer Helper-Dokumente einbauen.
- [ ] Dokumentfreigabe im Bewerbungsfluss produktiv anbinden.
- [ ] Dateityp-/Groessenfehler nutzerfreundlich anzeigen.

### 4.5 RPCs, Trigger und Realtime

- [x] `search_offers` fuer Discover/Feed vorhanden.
- [x] `publish_offer`, `accept_application`, `reject_application`, `withdraw_application`,
  `complete_application` vorhanden.
- [x] `create_conversation_for_application` vorhanden.
- [x] Community-RPCs vorhanden.
- [x] Trigger fuer Conversations bei Bewerbungen vorhanden.
- [x] Trigger fuer Message-Side-Effects vorhanden.
- [x] Realtime fuer Messages, Conversations und Notifications aktiviert.
- [ ] RPCs mit SQL-Tests gegen Rollen und Grenzfaelle absichern.
- [ ] Realtime in Frontend-Flows gezielt abonnieren und sauber unsubscriben.
- [ ] Rate-Limiting oder Missbrauchsschutz fuer Messages und Reports bewerten.

## 5. Frontend-Grundlagen

### 5.1 Layout und Navigation

- [x] Public-, Helper-, Org-, Messages- und Profile-Layouts vorhanden.
- [x] Mobile-first App-Shell mit Top-/Bottom-Navigation vorhanden.
- [x] Helper-Navigation enthaelt Community, Rewards, Start, Favoriten, Profil.
- [x] `SageHeader` wird fuer Helper-Screens genutzt.
- [ ] Navigation fuer Admin-Bereich definieren.
- [ ] Desktop-Layout fuer produktive Nutzung weiter glaetten.
- [ ] Aktive Tabs und Deep Links mit E2E pruefen.
- [ ] Header-Unread-Quelle auf allen relevanten Helper-Seiten vereinheitlichen.

### 5.2 Designsystem und Komponenten

- [x] UI-Komponenten vorhanden:
  Buttons, IconButton, Badge, Alert, EmptyState, LoadingSpinner, BottomNavBar,
  TopNavBar, AppShell, SageHeader.
- [x] Offer-Komponenten vorhanden:
  SwipeDeck, SwipeCard, SwipeActionBar, OfferPreviewCard, OfferRow, FilterBar.
- [x] Chat-Komponenten vorhanden:
  ConversationListItem, ChatHeader, MessageBubble, MessageComposer.
- [x] Dashboard-, Profil-, Kalender- und Application-Komponenten sind vorbereitet.
- [x] Discover-Action-Bar in dieser Session sauber ausgerichtet.
- [ ] Visuelle Konsistenz aller Komponenten anhand echter Screenshots pruefen.
- [x] A11y-Warnungen in interaktiven Karten/Listen beheben.
- [ ] Design Tokens, Farbkontraste und Fokuszustaende systematisch auditieren.

## 6. Public App und Onboarding

### 6.1 Landing und Einstieg

- [x] Public Layout vorhanden.
- [x] Root-Route vorhanden.
- [x] Login-Route vorhanden.
- [x] Register-Route vorhanden.
- [ ] Landing-Seite fachlich finalisieren:
  klare Zielgruppen, Nutzen, Einstieg fuer Helper/Organisationen.
- [ ] Rechtliche Seiten finalisieren:
  Impressum, Datenschutz, AGB.
- [ ] Support-/Kontaktweg definieren.

### 6.2 Registrierung

- [x] Rollenmodell fuer Helper und Organisationen ist im Backend angelegt.
- [x] Register-UI ist vorhanden.
- [ ] Registrierung mit vollstaendigem Profil-Onboarding verbinden.
- [ ] Helper-Onboarding:
  Anzeigename, Ort, Bio, Interessen, Verfuegbarkeit, Avatar.
- [ ] Organisations-Onboarding:
  Name, Organisationstyp, Standort, Kontaktperson, Beschreibung, Avatar.
- [ ] Slug-Erzeugung und Duplikatbehandlung in UI testen.
- [ ] Fehlerzustaende fuer bestehende E-Mail, schwaches Passwort und Netzwerkfehler sauber anzeigen.

## 7. Helper Experience

### 7.1 Discover und Swipe

- [x] `/discover` zeigt den Swipe-Feed.
- [x] Angebote werden ueber `search_offers` geladen.
- [x] SwipeDeck, SwipeCard und SwipeActionBar sind integriert.
- [x] Helper kann Angebote ueberspringen.
- [x] Helper kann sich ueber Swipe/Action auf ein Angebot bewerben.
- [x] Helper kann Angebote als Favorit speichern.
- [x] Favoritenstatus wird auf dem Top-Card-Icon angezeigt.
- [x] Karten-Icon oben rechts ist ein Herz.
- [x] Action-Bar-Hinweise sind korrekt positioniert.
- [ ] FilterBar produktiv an `search_offers` anbinden:
  Ort, Datum, Uhrzeit, Kategorie, remote/digital, Angebotstyp.
- [ ] Swipe-Queue nach Aktionen konsistent aktualisieren.
- [ ] Doppelte Bewerbungen sauber verhindern und erklaeren.
- [ ] Undo-Verhalten mit Status/Queue testen.
- [ ] Empty-State nach Ende der Queue optimieren.
- [ ] Mock-Felder aus `mockEnrich.ts` ersetzen:
  Freunde, Entfernung, SOS, Kalender-Fit.

### 7.2 Angebotsdetail

- [x] `/offers/[id]` existiert fuer Helper.
- [x] Detailseite laedt Angebot mit Organisation.
- [x] Favoriten-Toggle im Detail vorhanden.
- [x] Bewerbung aus Detailseite moeglich.
- [x] Bewerbungsstatus wird beruecksichtigt.
- [ ] Detailseite mit echten Angebotsbildern verbinden.
- [ ] Statusabhaengige CTA-Regeln finalisieren:
  published, paused, filled, completed, cancelled, archived.
- [ ] Dokumentanforderungen anzeigen und Freigabeprozess anbinden.
- [ ] Organisation-Profil von Detailseite verlinken.
- [ ] Teilen-/Melden-Aktion ergaenzen.

### 7.3 Bewerbungen und Einsaetze

- [x] Bewerbungen koennen erstellt werden.
- [x] Bewerbungen erzeugen Conversations.
- [x] Bewerbungsstatus ist im Backend modelliert.
- [x] RPCs fuer Withdraw/Accept/Reject/Complete vorhanden.
- [x] Helper-Ansicht fuer aktive Bewerbungen bauen.
- [x] Helper-Ansicht fuer zugesagte Einsaetze bauen.
- [x] Bewerbung zurueckziehen im Frontend anbinden.
- [x] Statushistorie oder Timeline anzeigen.
- [x] Erinnerungen an bevorstehende Einsaetze umsetzen.

### 7.4 Favoriten

- [x] `/favorites` ist aktiv umgesetzt.
- [x] `saved_offers` wird als bestehende Backend-Tabelle genutzt.
- [x] Keine neue Basistabelle fuer Favoriten eingefuehrt.
- [x] Liste zeigt kompakte Angebotskarten.
- [x] Nicht verfuegbare Favoriten sind rot markiert.
- [x] Aktionen sind auf `Oeffnen` und `Entfernen` begrenzt.
- [x] Favoriten-Header nutzt echte Community-Unread-Zahl.
- [x] Favoriten-Seed ist testbar.
- [ ] Organisation-Favoriten bewusst planen oder aus V1 ausklammern.
- [ ] Favoriten in Discover, Detail und Favoritenliste per Realtime oder gezieltem Refetch
  synchron halten.
- [ ] Entfernen-Aktion mit Undo-Toast pruefen oder bewusst nicht einbauen.

### 7.5 Community, Chats und Aktivitaet

- [x] `/community` ist aktiv umgesetzt.
- [x] Community besteht aus Chats und Aktivitaet.
- [x] Chats bleiben bewerbungsgebunden.
- [x] Keine freien Direktnachrichten in V1.
- [x] Conversation-Liste zeigt Gegenpartei, Angebotstitel, letzte Nachricht, Zeit,
  unread count.
- [x] Activity-Feed zeigt Notifications.
- [x] `/messages` nutzt Conversation-Liste.
- [x] `/messages/[id]` zeigt Chat-Detail.
- [x] MessageComposer sendet Nachrichten.
- [x] Neue Nachrichten werden lokal eingefuegt und Realtime-Duplikate per ID verhindert.
- [x] Beim Oeffnen eines Chats wird `mark_conversation_read` ausgefuehrt.
- [x] Fremde Messages im offenen Chat werden automatisch gelesen markiert.
- [x] Community-Liste reagiert auf Realtime-Events.
- [ ] Zwei-Session-Realtime-Test in Playwright automatisieren.
- [ ] Message-Fehlerzustaende und Retry UX verbessern.
- [ ] Notification-Links fuer alle Entity-Typen vereinheitlichen.
- [ ] Notification-Praeferenzen bauen.
- [ ] Moderation/Melden fuer Nachrichten planen.

### 7.6 Kalender

- [x] `/calendar` Route und Kalender-Komponenten sind vorhanden.
- [x] Kalender an echte Bewerbungen und akzeptierte Einsaetze anbinden.
- [ ] Wiederkehrende Angebote korrekt darstellen.
- [ ] Tages-/Monatsansicht mit Statusfarben definieren.
- [x] Reminder aus Notifications und berechneten Einsatzzeitpunkten ableiten.
- [ ] Kein externer Kalenderzugriff in V1, solange Produktumfang das ausschliesst.

### 7.7 Rewards

- [x] `/rewards` existiert als Shell.
- [ ] Rewards-Produktentscheidung treffen:
  Punkte nur Engagement-Motivation oder echte Partner-/Rabattlogik?
- [ ] Backend-Modell definieren:
  Punkte-Events, Level, Rewards, Einloesungen, Missbrauchsschutz.
- [ ] Trigger oder RPCs fuer Punkte bei Bewerbungen/Einsaetzen definieren.
- [ ] Rewards-UI bauen:
  Punktestand, Level, Historie, einloesbare Rewards.
- [ ] Rechtliche und steuerliche Implikationen pruefen, bevor reale Rabatte aktiviert werden.

### 7.8 Helper-Profil

- [x] Profil-Route und Profil-Komponenten sind vorhanden.
- [x] Backend-Tabellen fuer Profile und Helper-Profile sind vorhanden.
- [ ] Profilseite vollstaendig an Supabase anbinden.
- [ ] Avatar-Upload anbinden.
- [ ] Bio, Ort, Skills, Sprachen, Verfuegbarkeit editierbar machen.
- [ ] Bisherige Einsaetze und Bewertungen anzeigen.
- [ ] Dokumentverwaltung in Profil integrieren.
- [ ] Privacy-Hinweise fuer oeffentliche/private Felder anzeigen.

## 8. Organisation Experience

### 8.1 Organisationsdashboard

- [x] Org-Layout ist vorhanden.
- [x] `/dashboard` Route ist vorhanden.
- [x] Dashboard-Service existiert.
- [x] Komponenten fuer Metrics und ActivityFeed sind vorhanden.
- [ ] Dashboard mit echten Kennzahlen finalisieren:
  offene Angebote, neue Bewerbungen, zugesagte Helfer, ungelesene Nachrichten.
- [ ] ActivityFeed an echte Notifications/Audit-Events anbinden.
- [ ] Empty/Error/Loading-Zustaende pruefen.

### 8.2 Angebotsverwaltung

- [x] `/offers` und `/offers/new` fuer Organisationen sind vorhanden.
- [x] Backend-Tabellen und Statusregeln fuer Offers existieren.
- [x] `publish_offer` RPC vorhanden.
- [ ] Angebotsformular vollstaendig gegen Schema validieren.
- [ ] Draft, Publish, Pause, Archive, Cancel, Complete im UI abbilden.
- [ ] Angebotsbilder hochladen.
- [ ] Wiederkehrende Angebote bearbeiten.
- [ ] Kapazitaet und Status `filled` sauber anzeigen.
- [ ] Bearbeiten/Loeschen bestehender Angebote bauen.

### 8.3 Bewerbungsmanagement

- [x] Backend modelliert Bewerbungen und Status.
- [x] RPCs fuer Annahme, Ablehnung und Abschluss existieren.
- [x] ApplicantCard und ApplicationListItem sind vorhanden.
- [ ] Bewerbungsuebersicht pro Angebot bauen.
- [ ] Bewerberprofil anzeigen.
- [ ] Zusagen und Absagen im UI anbinden.
- [ ] Organisation-Notiz und Ablehnungsgrund sauber speichern/anzeigen.
- [ ] Dokumentfreigaben anzeigen.
- [ ] Akzeptierte Helfer fuer Einsatzplanung darstellen.

### 8.4 Kommunikation mit Helfenden

- [x] Conversations entstehen aus Bewerbungen.
- [x] Organisationen sind Teilnehmer der Conversations.
- [x] Nachrichten-RLS erlaubt nur Teilnehmerzugriff.
- [ ] Org-seitige Chat-Navigation und Unread-Zaehlung optimieren.
- [ ] Chat aus Bewerbungsdetail direkt oeffnen.
- [ ] Templates oder Schnellantworten optional bewerten.

### 8.5 Organisationsprofil

- [x] Organisation-Profil-Tabelle existiert.
- [x] Profil-Komponenten sind vorbereitet.
- [ ] Organisationsprofilseite bauen:
  Beschreibung, Typ, Standort, Kontakt, Bewertungen, Angebote.
- [ ] Profil bearbeiten.
- [ ] Avatar/Logo hochladen.
- [ ] Oeffentliche Profilansicht fuer Helper verlinken.

## 9. Bewertungen, Vertrauen und Sicherheit

### 9.1 Ratings

- [x] `ratings` Tabelle vorhanden.
- [x] Bewertung nach abgeschlossenem Einsatz per RLS eingeschraenkt.
- [x] Aggregate `average_rating` und `rating_count` werden neu berechnet.
- [ ] Frontend fuer Bewertung nach Abschluss bauen.
- [ ] Bewertungsformular mit Score und Kommentar.
- [ ] Gegenseitige Bewertung fuer Helper und Organisation klar trennen.
- [ ] Bewertungen auf Profilen und Angebotsdetails anzeigen.
- [ ] Admin-Moderation fuer Bewertungen bauen.

### 9.2 Reports und Moderation

- [x] `reports` Tabelle vorhanden.
- [x] Admin-RLS fuer Reports vorbereitet.
- [ ] Melden-Aktion fuer Profile, Angebote und Nachrichten bauen.
- [ ] Admin-Queue fuer offene Reports bauen.
- [ ] Statuswechsel fuer Reports umsetzen.
- [ ] Audit-Log fuer Moderationsentscheidungen schreiben.

### 9.3 Admin

- [x] Admin-Rolle ist im Backend vorgesehen.
- [x] `admin_audit_log` Tabelle vorhanden.
- [x] Admin-Policies fuer sensible Bereiche existieren.
- [ ] Admin-Layout und Admin-Routen bauen.
- [ ] Nutzerverwaltung:
  lesen, sperren, reaktivieren, loeschen/anonymisieren.
- [ ] Angebotsverwaltung:
  problematische Angebote bearbeiten/depublizieren.
- [ ] Bewertungsmoderation.
- [ ] Report-Management.
- [ ] Audit-Log einsehen.

## 10. Notifications und Reminder

- [x] `notifications` Tabelle vorhanden.
- [x] Notifications-Service im Frontend vorhanden.
- [x] Message-Notifications werden erzeugt.
- [x] Community Activity-Feed zeigt Notifications.
- [x] Unread-Summary speist Header-Badges.
- [ ] Application-Notifications vollstaendig erzeugen:
  Bewerbung eingegangen, angenommen, abgelehnt, zurueckgezogen.
- [x] Einsatz-Reminder fuer Helper-MVP definieren und erzeugen.
- [ ] Notification-Praeferenzen fuer Nutzer bauen.
- [ ] Push/E-Mail erst nach Produktentscheidung und Consent-Modell planen.

## 11. Suche, Matching und Datenqualitaet

- [x] `search_offers` RPC liefert Feed-Daten.
- [x] Discover nutzt echte Angebote aus Supabase.
- [ ] Filter UI vollstaendig anbinden.
- [ ] Kategorien und Skill-Taxonomie finalisieren.
- [ ] Ortssuche normalisieren:
  Stadt, PLZ, Remote, Deutschlandweiter Einsatz.
- [ ] Entfernung/KM nur dann anzeigen, wenn echte Geodaten vorhanden sind.
- [ ] SOS/Kurzfristig als echtes Backend-Feld oder Regel definieren.
- [ ] Empfehlung/Ranking fuer Feed definieren:
  Datum, Ort, Kategorie, Verfuegbarkeit, bereits beworben, Status.

## 12. Datenschutz und Rechtliches

- [ ] Datenschutzseite finalisieren.
- [ ] Impressum finalisieren.
- [ ] AGB/Nutzungsbedingungen finalisieren.
- [ ] Consent fuer Benachrichtigungen und E-Mail-Kommunikation definieren.
- [ ] Datenexport fuer Nutzer bewerten.
- [ ] Konto-Loeschung und Anonymisierung umsetzen.
- [ ] Aufbewahrungsfristen fuer Bewerbungen, Nachrichten, Dokumente und Audit-Logs definieren.

## 13. Tests und Acceptance Criteria

### 13.1 Aktuell verifiziert

- [x] `corepack pnpm run check` im Frontend: 0 Fehler, 0 Warnungen.
- [x] `./scripts/bootstrap-frontend.sh --clean` im Frontend: Install, Check und Build erfolgreich.
- [x] Lokales Schema und Seed erfolgreich geladen.
- [x] Helper sieht eigene Favoriten.
- [x] Fremder Favoriten-Insert wird per RLS blockiert.
- [x] Community- und Message-Flows lokal im Browser geprueft.
- [x] Discover-Action-Bar im Browser gemessen:
  Hinweise sind unter den jeweiligen Buttons ausgerichtet.

### 13.2 Noch aufzubauen

- [ ] SQL-Testdatei fuer RLS:
  Profile, Offers, Applications, Documents, Conversations, Messages, Ratings, Favorites,
  Notifications, Reports.
- [ ] Service-Tests fuer Supabase-Wrapper:
  Offers, Applications, Messages, Notifications, SavedOffers.
- [ ] Playwright-E2E fuer Helper:
  Login, Discover, Favorit speichern, Favorit entfernen, Bewerbung senden, Chat oeffnen.
- [ ] Playwright-E2E fuer Organisation:
  Login, Angebot erstellen, Bewerbung sehen, annehmen, Nachricht senden.
- [ ] Playwright-E2E fuer Admin:
  Login, Report sehen, Nutzer sperren.
- [ ] Visual Regression Screenshots fuer mobile und desktop Viewports.
- [ ] Performance-Sanity:
  initial load, feed query, chat realtime, large lists.

## 14. Deployment und Betrieb

- [x] Frontend kann lokal via `npm run dev` gestartet werden.
- [x] Backend kann lokal ueber Supabase-Schema/Seed reproduziert werden.
- [x] `corepack pnpm run build` pruefen und Build-Fehler beheben.
- [ ] Deployment-Ziel entscheiden:
  Netlify, Vercel oder anderer SvelteKit-kompatibler Hoster.
- [ ] SvelteKit-Adapter fuer Zielumgebung konfigurieren.
- [ ] Supabase-Projekt fuer Staging erstellen.
- [ ] Staging-Environment-Variablen sicher einrichten.
- [ ] Schema/Seed fuer Staging-Prozess definieren:
  kein Produktiv-Seed mit Testpasswoertern.
- [ ] Monitoring und Logging definieren:
  Frontend-Errors, Supabase Logs, Auth-Fehler, RLS-Fehler.
- [ ] Backup-/Restore-Konzept fuer Supabase festlegen.
- [ ] Release-Checkliste erstellen.

## 15. Meilensteine bis zur funktionierenden Web App

### M0 - Aktueller integrierter Prototyp

- [x] Lokale App startet.
- [x] Supabase-Schema ist replayable.
- [x] Seed-Daten decken Helper, Organisationen, Angebote, Bewerbungen, Chats, Favoriten ab.
- [x] Helper kann Discover nutzen.
- [x] Helper kann Favoriten nutzen.
- [x] Helper kann Community/Chats nutzen.
- [x] Grundlegende Org-Routen existieren.
- [x] Profil-, Kalender- und Rewards-Shells existieren.

### M1 - Helper MVP

- [ ] Registrierung/Login produktiv stabil.
- [ ] Helper-Onboarding vollstaendig.
- [ ] Discover-Filter produktiv.
- [ ] Offer Detail vollstaendig.
- [x] Bewerbung senden und zurueckziehen.
- [ ] Favoriten stabil ueber Discover/Detail/Favoritenliste.
- [ ] Community Chat stabil mit Realtime.
- [ ] Aktivitaet/Notifications vollstaendig.
- [ ] Helper-Profil editierbar.
- [x] Kalender zeigt echte Einsaetze.

### M2 - Organisation MVP

- [ ] Organisations-Onboarding vollstaendig.
- [ ] Organisation kann Profil pflegen.
- [ ] Organisation kann Angebote erstellen, bearbeiten, veroeffentlichen, pausieren,
  archivieren.
- [ ] Organisation sieht Bewerbungen pro Angebot.
- [ ] Organisation kann Bewerbungen annehmen oder ablehnen.
- [ ] Organisation kann mit Bewerbern chatten.
- [ ] Organisation kann Einsatz abschliessen.
- [ ] Dashboard zeigt echte Kennzahlen.

### M3 - Vertrauen, Qualitaet, Admin

- [ ] Gegenseitige Bewertungen nach Abschluss.
- [ ] Report-/Melden-Funktion.
- [ ] Admin-Bereich fuer Nutzer, Angebote, Bewertungen und Reports.
- [ ] Audit-Log sichtbar und nutzbar.
- [ ] Datenschutz-, Loesch- und Anonymisierungsfluesse.
- [ ] Dokumentupload und Dokumentfreigabe fuer relevante Angebote.

### M4 - Production Readiness

- [ ] Vollstaendige automatisierte Testabdeckung fuer kritische Flows.
- [ ] RLS-Test-Suite ist verpflichtend.
- [ ] Build und Preview laufen sauber.
- [ ] Staging-Deployment laeuft.
- [ ] Produktiv-Deployment vorbereitet.
- [ ] Monitoring, Backups und Fehlerlogging eingerichtet.
- [ ] Rechtliche Seiten final.
- [ ] Release-Checkliste abgearbeitet.

## 16. Offene Produktentscheidungen

- [ ] Rewards: nur Motivation/Punkte oder echte einloesbare Vorteile?
- [ ] Organisation-Favoriten: V1 auslassen oder Follow-Modell einfuehren?
- [ ] Verifikation: weiterhin keine formale Anbieter-Verifikation oder spaeter ein Verified-Status?
- [ ] Dokumente: Pflichtnachweise in V1 oder erst spaeter?
- [ ] Kalender: rein intern oder spaeter Export/ICS?
- [ ] Notifications: nur In-App oder auch E-Mail/Push?
- [ ] Geodaten: einfache Stadtfilterung oder echte Umkreissuche?
- [ ] Moderation: reaktiv per Reports oder proaktive Admin-Reviews?

## 17. Definition of Done pro Feature

Ein Feature gilt erst als abgeschlossen, wenn alle Punkte erfuellt sind:

- [ ] Fachlicher Scope ist in dieser Roadmap oder einem verlinkten Doc beschrieben.
- [ ] Datenmodell/API-Vertrag ist geprueft oder aktualisiert.
- [ ] Supabase-RLS und Rollenregeln sind implementiert.
- [ ] Frontend nutzt Services statt direkter Datenbanklogik in Komponenten.
- [ ] Loading-, Empty-, Error- und Success-State sind vorhanden.
- [ ] Mobile und Desktop wurden visuell geprueft.
- [ ] `npm run check` hat 0 Fehler.
- [ ] Relevante SQL-/Service-/E2E-Tests sind vorhanden.
- [ ] Seed-Daten erlauben lokale Pruefung des Features.
- [ ] Dokumentation und Roadmap sind aktualisiert.
