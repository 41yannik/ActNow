# Technical Requirements

## 1. Technologie-Stack

Die Anwendung wird mit einem modernen, webbasierten Technologie-Stack umgesetzt.

### Backend

Als Backend wird **Supabase** verwendet.

Supabase stellt folgende Kernfunktionen bereit:

* PostgreSQL-Datenbank
* Authentifizierung und Nutzerverwaltung
* Row Level Security für rollenbasierte Zugriffe
* File Storage für Profilbilder und Dokumente
* Realtime-Funktionalität für spätere Erweiterungen, z. B. Chat oder Live-Updates

Das Backend soll möglichst stark über Supabase-native Funktionen abgebildet werden, um den eigenen Backend-Code gering zu halten.

### Frontend

Das Frontend wird mit **SvelteKit** umgesetzt.

SvelteKit dient als zentrale Anwendungsschicht für:

* Seitenrouting
* UI-Komponenten
* serverseitige und clientseitige Datenabfragen
* Formulare
* Authentifizierungsflüsse
* Kommunikation mit Supabase

### Programmiersprache

Die Anwendung wird durchgehend mit **TypeScript** entwickelt.

TypeScript ist verpflichtend für:

* Frontend-Komponenten
* Supabase-Client-Code
* API-Interfaces
* Datenmodelle
* Validierungslogik
* Utility- und Service-Funktionen

Ziel ist eine typsichere Kommunikation zwischen Frontend und Backend.

---

## 2. Architekturprinzipien

## Starke Modularisierung im Frontend

Das Frontend muss stark modular aufgebaut sein.

Die Anwendung soll nicht als monolithische Sammlung von Seiten entstehen, sondern in klar getrennte Module und Verantwortlichkeiten aufgeteilt werden.

Beispiele für Module:

* Authentifizierung
* Nutzerprofile
* Vereinsprofile
* Angebote
* Bewerbungen
* Bewertungen
* Dokumentenverwaltung
* Messaging
* Admin-Bereich

Jedes Modul soll möglichst eigenständig strukturiert sein und eigene Komponenten, Services, Typen und Validierungen enthalten.

---

## 3. Frontend-Struktur

Die SvelteKit-Anwendung soll eine klare Ordnerstruktur verwenden.

Empfohlene Struktur:

```text
src/
  lib/
    components/
      ui/
      forms/
      layout/
    features/
      auth/
      profiles/
      organizations/
      offers/
      applications/
      reviews/
      documents/
      messaging/
      admin/
    services/
      supabase/
      api/
    types/
    utils/
    validation/
  routes/
    app/
    admin/
    auth/
```

Die Ordner unter `features/` bilden die fachlichen Module der Anwendung ab.

Gemeinsam genutzte UI-Komponenten liegen unter `components/`.

Supabase-spezifische Logik wird unter `services/supabase/` gekapselt.

---

## 4. Kommunikation zwischen Frontend und Backend

Die Kommunikation mit dem Backend erfolgt über den Supabase Client.

Das Frontend darf nicht direkt unstrukturiert Datenbankzugriffe in beliebigen Komponenten ausführen.

Stattdessen sollen Datenzugriffe über klar definierte Service-Funktionen erfolgen.

Beispiel:

```ts
// services/supabase/offers.ts

export async function getOpenOffers() {
  // Supabase query
}

export async function applyForOffer(offerId: string, userId: string) {
  // Supabase mutation
}
```

Dadurch bleibt die Anwendung wartbar, testbar und leichter erweiterbar.

---

## 5. Typisierung

Alle zentralen Datenstrukturen müssen als TypeScript-Typen definiert werden.

Dazu gehören insbesondere:

* Profile
* Rollen
* Vereine
* Angebote
* Bewerbungen
* Bewertungen
* Dokumente
* Nachrichten
* Admin-Operationen

Die Typen sollen nach Möglichkeit aus dem Supabase-Datenbankschema generiert oder eng daran ausgerichtet werden.

Ziel ist, dass Datenbankmodell, API-Verträge und Frontend-Code konsistent bleiben.

---

## 6. Validierung

Eingaben müssen sowohl im Frontend als auch im Backend validiert werden.

Frontend-Validierung dient der Nutzerfreundlichkeit.

Backend-Validierung bzw. Datenbank-Constraints dienen der Sicherheit und Datenintegrität.

Typische Validierungen:

* Pflichtfelder
* gültige E-Mail-Adressen
* maximale Textlängen
* erlaubte Rollen
* erlaubte Statuswerte
* gültige Bewerbungsstatus
* zulässige Dateitypen und Dateigrößen

---

## 7. Authentifizierung und Rollen

Die Authentifizierung erfolgt über Supabase Auth.

Die Anwendung benötigt mindestens folgende Rollen:

* Helfer
* Verein
* Admin

Die Zugriffsrechte werden über Supabase Row Level Security abgesichert.

Das Frontend darf Rollen nicht nur clientseitig prüfen. Sicherheitsrelevante Zugriffsbeschränkungen müssen im Backend bzw. in Supabase durchgesetzt werden.

---

## 8. Storage

Profilbilder und Dokumente werden über Supabase Storage verwaltet.

Dokumente von Helfern dürfen nicht pauschal öffentlich abrufbar sein.

Der Zugriff auf sensible Dokumente muss rollen- und kontextabhängig gesteuert werden, z. B. nur für Vereine, denen ein Helfer die Dokumente im Rahmen einer Bewerbung freigegeben hat.

---

## 9. Fehlerbehandlung

Die Anwendung benötigt eine einheitliche Fehlerbehandlung.

Fehler sollen nutzerfreundlich angezeigt werden, ohne interne technische Details offenzulegen.

Beispiele:

* fehlende Berechtigung
* ungültige Eingaben
* Netzwerkfehler
* fehlgeschlagene Datei-Uploads
* nicht mehr verfügbare Angebote
* fehlgeschlagene Bewerbung

Technische Fehler sollen intern klar nachvollziehbar bleiben.

---

## 10. Performance

Die Anwendung soll auf schnelle Ladezeiten ausgelegt sein.

Wichtige Anforderungen:

* Pagination für lange Listen
* Filterung serverseitig über Supabase Queries
* Lazy Loading für größere Bereiche
* Optimierung von Bildern
* keine unnötigen Datenbankabfragen in Komponenten
* Wiederverwendung gemeinsamer Datenservices

---

## 11. Sicherheit

Die Anwendung muss grundlegende Sicherheitsanforderungen erfüllen.

Dazu gehören:

* Supabase Row Level Security für alle relevanten Tabellen
* keine sensiblen Daten im Client speichern
* sichere Behandlung von Uploads
* Prüfung von Dateitypen und Dateigrößen
* Schutz vor unberechtigtem Zugriff auf private Dokumente
* serverseitige Prüfung kritischer Aktionen
* klare Trennung von Nutzer-, Vereins- und Adminrechten

---

## 12. Erweiterbarkeit

Die technische Architektur soll zukünftige Erweiterungen ermöglichen.

Mögliche spätere Erweiterungen:

* In-App-Chat
* Push-Benachrichtigungen
* Realtime-Updates
* Verifizierung von Vereinen
* Moderationsfunktionen
* Kalenderintegration
* bessere Matching-Algorithmen
* mobile App auf Basis derselben Backend-Struktur

Die initiale Architektur soll diese Erweiterungen nicht blockieren.

---

## 13. Entwicklungsstandards

Für die Entwicklung gelten folgende Standards:

* TypeScript strict mode
* konsistente Formatierung
* modulare Komponenten
* sprechende Dateinamen
* keine direkte Business-Logik in UI-Komponenten
* klare Trennung von UI, Datenzugriff und Geschäftslogik
* wiederverwendbare Typen und Services
* dokumentierte zentrale Entscheidungen

---

## 14. Zielbild

Das technische Ziel ist eine wartbare, sichere und skalierbare Webanwendung.

Supabase übernimmt Backend, Datenbank, Authentifizierung und Storage.

SvelteKit bildet das Frontend und die Anwendungsschicht.

TypeScript stellt sicher, dass Datenmodelle, Services und UI zuverlässig zusammenarbeiten.

Die starke Modularisierung im Frontend sorgt dafür, dass die Anwendung auch bei wachsendem Funktionsumfang verständlich und erweiterbar bleibt.
