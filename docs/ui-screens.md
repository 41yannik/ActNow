# UI Screens - ActNow

Status: Screen-Inventar fuer Umsetzung, Review und Acceptance Checks. Details werden pro Feature
erweitert, sobald die jeweilige Route produktiv umgesetzt wird.

## Gemeinsame UI-Regeln

- Mobile-first, aber Desktop darf nicht nur gestreckte Mobile-Ansicht sein.
- Interaktive Listen, Karten und Buttons muessen keyboard- und screenreader-tauglich sein.
- Jede datengetriebene Seite braucht Loading-, Empty- und Error-State.
- Header-Unread-Zahlen muessen aus einer echten Datenquelle kommen.
- Design-Shells und Mock-Daten muessen im Code klar markiert oder entfernt werden.

## Public

### `/`

- Einstieg in die App.
- Zeigt den aktuellen Produktfokus und fuehrt zu Login/Register.
- Muss vor Production fachlich finalisiert werden.

### `/login`

- E-Mail-/Passwort-Login.
- Fehlerzustaende sichtbar.
- Nach Login Redirect nach Rolle.

### `/register`

- Rollenauswahl Helper oder Organisation.
- Signup-Metadaten muessen zum Supabase-Signup-Trigger passen.
- Nach Registrierung klarer naechster Schritt zum Profil/Onboarding.

## Helper

### `/discover`

- Swipe-Feed als Hauptscreen.
- Top-Card zeigt Favoritenstatus.
- Action-Bar: zurueck, nein, Favoriten, bewerben.
- Filter muessen an `search_offers` angebunden werden.
- Mock-Felder wie Freunde, Distanz, SOS und Kalender-Fit sind zu ersetzen oder bewusst zu entfernen.

### `/offers/[id]`

- Detailseite mit Angebot, Organisation, Fakten, Anforderungen und CTA.
- Favoriten-Toggle.
- Bewerbung mit Confirmation.
- Statusabhaengige CTA-Regeln.

### `/favorites`

- Liste eigener Favoriten.
- Nicht verfuegbare Angebote bleiben sichtbar und sind rot markiert.
- Aktionen: Oeffnen, Entfernen.
- Header nutzt echte Community-Unread-Zahl.

### `/applications`

- Zentrale Helper-Ansicht fuer Bewerbungen und Einsaetze.
- Tabs: Bewerbungen, Einsaetze, Historie.
- Zeigt Status, Angebot, Organisation, Termin, Ort und aktuelle Statushinweise.
- Zeigt pro Bewerbung/Einsatz eine Timeline aus Einreichung, Statuswechseln und Reminderpunkten.
- Zeigt fuer zugesagte Einsaetze ein Reminder-Panel mit gesendeten, faelligen und geplanten
  Erinnerungen.
- Offene, vorausgewaehlte und zugesagte Bewerbungen koennen zurueckgezogen werden.
- Chat-Aktion oeffnet die bewerbungsgebundene Conversation.
- Seed-Daten fuer `helper1@actnow.test` decken alle sichtbaren Statusgruppen sowie einen
  nahen Einsatz-Reminder ab.

### `/community`

- Tabs fuer Chats und Aktivitaet.
- Chats zeigen Gegenpartei, Angebotstitel, letzte Nachricht, Zeit und unread count.
- Activity zeigt Notifications.
- Realtime-Updates aktualisieren Summary und Listen.

### `/messages`

- Conversation-Liste als Nachrichtenuebersicht.
- Nutzt dieselbe Conversation-Datenquelle wie Community.

### `/messages/[id]`

- Chat-Detail.
- Neue Nachrichten werden sofort angezeigt.
- Fremde Nachrichten werden beim Oeffnen gelesen markiert.
- Fehler beim Senden muessen sichtbar und wiederholbar sein.

### `/profile`

- Helper-Profil mit Stammdaten, Bio, Ort, Skills und Dokumenten.
- Bio und Stadt sind aktuell editierbar.
- Avatar, Skills, Sprachen, Verfuegbarkeit und Dokumentupload fehlen noch fuer M1.

### `/calendar`

- Route und UI-Komponenten existieren.
- Zeigt echte akzeptierte und abgeschlossene Einsaetze aus Bewerbungen.

### `/rewards`

- Aktuell Shell.
- Produktentscheidung erforderlich, bevor Backend und echte UI gebaut werden.

## Organisation

### `/dashboard`

- Organisationsuebersicht mit echten Kennzahlen.
- ActivityFeed muss an echte Notifications oder Audit-Events angebunden werden.

### `/offers`

- Liste eigener Angebote.
- Status und Kapazitaet muessen klar sichtbar sein.

### `/offers/new`

- Formular fuer neue Angebote.
- Validiert gegen Frontend-Schema und Supabase-Schema.
- Publish-Flow nutzt `publish_offer`.

### `/offers/[id]/applications`

- Bewerbungsuebersicht pro Angebot.
- Annahme/Ablehnung und Chat-Einstieg muessen fuer M2 produktiv werden.

## Admin

- Noch keine produktiven Admin-Routen.
- M3 braucht Nutzerverwaltung, Reports, Bewertungsmoderation und Audit-Log-Ansicht.
