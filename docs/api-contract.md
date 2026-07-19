# API Contract – ActNow

> **Historisches Architekturdokument:** Dieser Vertrag beschreibt den früheren Produktentwurf und
> wird von der statischen Portfolio-Demo nicht verwendet.

Status: archivierter Entwurf<br>
Ziel: Dokumentation des früheren Frontend-/Backend-Vertrags.

Dieses Dokument beschreibt den API-Vertrag zwischen Frontend und Backend für die ActNow-App. Das Backend basiert auf Supabase, also Postgres, Supabase Auth, Row Level Security, Storage und optional Realtime.

---

## 1. Grundprinzipien

Das Frontend kommuniziert primär direkt mit Supabase über:

1. Supabase Auth für Registrierung, Login, Logout und Session-Verwaltung.
2. Supabase PostgREST API für CRUD-Zugriffe auf Tabellen.
3. Supabase Storage API für Profilbilder und Dokumente.
4. Supabase Realtime für Chat-Nachrichten, Bewerbungsstatus und relevante Updates.
5. Optional Supabase Edge Functions für sicherheitskritische oder komplexe Aktionen.

Der Großteil der Geschäftslogik wird über Postgres Constraints, Foreign Keys, Enums, Views, RPC Functions und Row Level Security abgesichert.

Das Frontend darf niemals sicherheitskritische Entscheidungen alleine treffen. Jede Berechtigung muss serverseitig über RLS, Policies oder Edge Functions erzwungen werden.

---

## 2. Authentifizierung

### 2.1 Auth Provider

ActNow verwendet Supabase Auth.

Mögliche Auth-Varianten:

- E-Mail + Passwort
- Magic Link, falls später gewünscht
- OAuth, falls später gewünscht

### 2.2 Session Handling

Das Frontend speichert die Supabase Session über den offiziellen Supabase Client.

Jede authentifizierte Anfrage enthält automatisch:

```http
Authorization: Bearer <access_token>
apikey: <supabase_anon_key>
```

### 2.3 User ID

Die zentrale technische User-ID ist:

```ts
auth.uid(): uuid
```

Diese ID referenziert `auth.users.id` und wird in fachlichen Tabellen wie `profiles.user_id` verwendet.

---

## 3. Rollenmodell im API-Kontext

Es gibt drei fachliche Hauptrollen:

| Rolle | Beschreibung |
|---|---|
| `helper` | Ehrenamtliche Helfer, die sich auf Angebote bewerben |
| `organization` | Vereine oder Anbieter, die Angebote einstellen |
| `admin` | Plattform-Administratoren mit erweiterten Rechten |

Ein User besitzt genau ein primäres Profil in `profiles`.

```ts
type UserRole = 'helper' | 'organization' | 'admin';
```

Rollen werden nicht vom Frontend frei gesetzt, außer während des Onboardings und nur innerhalb erlaubter Regeln. Admin-Rechte dürfen niemals durch normale Frontend-Requests vergeben werden.

---

## 4. Allgemeines Datenformat

### 4.1 Datumswerte

Alle Zeitpunkte werden als ISO-8601 Strings übertragen.

```ts
type ISODateTime = string; // Beispiel: "2026-05-29T10:30:00.000Z"
type ISODate = string;     // Beispiel: "2026-05-29"
```

### 4.2 IDs

Alle Primärschlüssel sind UUIDs.

```ts
type UUID = string;
```

### 4.3 Pagination

Listen-Endpunkte verwenden Range-basierte Pagination über Supabase.

Frontend-Beispiel:

```ts
const { data, error, count } = await supabase
  .from('offers')
  .select('*', { count: 'exact' })
  .range(0, 19);
```

Standard:

| Parameter | Beschreibung |
|---|---|
| `limit` | Anzahl Datensätze pro Seite, default 20 |
| `offset` | Startposition |
| `count` | Optional, wenn Gesamtzahl benötigt wird |

### 4.4 Fehlerformat

Supabase liefert Fehler typischerweise in dieser Struktur:

```ts
type ApiError = {
  message: string;
  code?: string;
  details?: string;
  hint?: string;
};
```

Das Frontend übersetzt technische Fehlermeldungen in nutzerfreundliche Texte.

---

## 5. Frontend Client Setup

```ts
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);
```

Das Frontend verwendet ausschließlich den `anon` Key. Der `service_role` Key darf niemals im Frontend verwendet werden.

---

## 6. Datenobjekte

## 6.1 Profile

Tabelle: `profiles`

Ein Profil beschreibt einen registrierten Nutzer, unabhängig davon ob Helfer, Verein oder Admin.

### TypeScript Contract

```ts
type ProfileStatus = 'active' | 'inactive' | 'suspended' | 'deleted';

type Profile = {
  id: UUID;
  user_id: UUID;
  role: UserRole;
  status: ProfileStatus;
  display_name: string;
  avatar_url: string | null;
  bio: string | null;
  location_name: string | null;
  average_rating: number | null;
  rating_count: number;
  created_at: ISODateTime;
  updated_at: ISODateTime;
};
```

### Frontend darf lesen

- Eigene Profile vollständig
- Öffentliche Profildaten anderer aktiver Nutzer
- Admins dürfen alle Profile lesen

### Frontend darf schreiben

Normale Nutzer dürfen nur ihr eigenes Profil bearbeiten und nur erlaubte Felder ändern.

Erlaubte Felder für Nutzer:

```ts
type UpdateOwnProfileInput = {
  display_name?: string;
  avatar_url?: string | null;
  bio?: string | null;
  location_name?: string | null;
};
```

Nicht direkt durch normale Nutzer änderbar:

- `role`
- `status`
- `average_rating`
- `rating_count`
- `user_id`

### Beispiel: eigenes Profil laden

```ts
const { data, error } = await supabase
  .from('profiles')
  .select('*')
  .eq('user_id', user.id)
  .single();
```

### Beispiel: eigenes Profil aktualisieren

```ts
const { data, error } = await supabase
  .from('profiles')
  .update({
    display_name: 'Max Mustermann',
    bio: 'Ich helfe gerne bei Sportveranstaltungen und sozialen Projekten.'
  })
  .eq('user_id', user.id)
  .select()
  .single();
```

---

## 6.2 Helper Profile Details

Tabelle: `helper_profiles`

Ergänzende Daten für Helfer.

```ts
type HelperProfile = {
  id: UUID;
  profile_id: UUID;
  short_bio: string | null;
  skills: string[];
  availability_note: string | null;
  experience_note: string | null;
  created_at: ISODateTime;
  updated_at: ISODateTime;
};
```

### Beispiel: Helferprofil lesen

```ts
const { data, error } = await supabase
  .from('helper_profiles')
  .select('*, profile:profiles(*)')
  .eq('profile_id', profileId)
  .single();
```

---

## 6.3 Organization Profile Details

Tabelle: `organization_profiles`

Ergänzende Daten für Vereine oder Anbieter.

```ts
type OrganizationProfile = {
  id: UUID;
  profile_id: UUID;
  organization_name: string;
  legal_form: string | null;
  website_url: string | null;
  contact_email: string | null;
  contact_phone: string | null;
  address_text: string | null;
  created_at: ISODateTime;
  updated_at: ISODateTime;
};
```

### Beispiel: Verein mit Bewertung und Angeboten anzeigen

```ts
const { data, error } = await supabase
  .from('organization_profiles')
  .select(`
    *,
    profile:profiles(*),
    offers:offers(id, title, status, starts_at, location_name)
  `)
  .eq('profile_id', organizationProfileId)
  .single();
```

---

## 6.4 Offers

Tabelle: `offers`

Ein Angebot beschreibt eine ehrenamtliche Tätigkeit.

### Status und Typen

```ts
type OfferStatus = 'draft' | 'published' | 'closed' | 'cancelled' | 'completed';
type OfferType = 'one_time' | 'recurring' | 'flexible';
type OfferLocationType = 'onsite' | 'remote' | 'hybrid';
```

### TypeScript Contract

```ts
type Offer = {
  id: UUID;
  organization_profile_id: UUID;
  title: string;
  description: string;
  status: OfferStatus;
  offer_type: OfferType;
  location_type: OfferLocationType;
  location_name: string | null;
  starts_at: ISODateTime | null;
  ends_at: ISODateTime | null;
  recurrence_rule: string | null;
  needed_helpers_count: number | null;
  min_age: number | null;
  required_documents: string[];
  tags: string[];
  created_at: ISODateTime;
  updated_at: ISODateTime;
};
```

### Business-Regeln

- Nur Organisationen dürfen Angebote erstellen.
- Nur Besitzer der Organisation oder Admins dürfen Angebote bearbeiten.
- Nur `published` Angebote erscheinen in der öffentlichen Suche.
- `draft` Angebote sind nur für die Organisation selbst und Admins sichtbar.
- Ein abgeschlossenes Angebot kann bewertet werden.
- `starts_at` und `ends_at` sind bei `one_time` Angeboten erforderlich.
- `recurrence_rule` ist bei `recurring` Angeboten erforderlich.
- Flexible Angebote dürfen kein fixes Startdatum benötigen.

### Beispiel: veröffentlichte Angebote laden

```ts
const { data, error } = await supabase
  .from('offers')
  .select(`
    *,
    organization:organization_profiles(
      id,
      organization_name,
      profile:profiles(id, avatar_url, average_rating, rating_count)
    )
  `)
  .eq('status', 'published')
  .order('starts_at', { ascending: true })
  .range(0, 19);
```

### Beispiel: Angebot erstellen

```ts
type CreateOfferInput = {
  title: string;
  description: string;
  offer_type: OfferType;
  location_type: OfferLocationType;
  location_name?: string | null;
  starts_at?: ISODateTime | null;
  ends_at?: ISODateTime | null;
  recurrence_rule?: string | null;
  needed_helpers_count?: number | null;
  min_age?: number | null;
  required_documents?: string[];
  tags?: string[];
};

const { data, error } = await supabase
  .from('offers')
  .insert({
    organization_profile_id: organizationProfileId,
    title: 'Hilfe beim Sommerfest',
    description: 'Wir suchen Unterstützung beim Aufbau und bei der Essensausgabe.',
    status: 'draft',
    offer_type: 'one_time',
    location_type: 'onsite',
    location_name: 'Berlin',
    starts_at: '2026-07-18T08:00:00.000Z',
    ends_at: '2026-07-18T16:00:00.000Z',
    needed_helpers_count: 8,
    tags: ['event', 'aufbau', 'soziales']
  })
  .select()
  .single();
```

### Beispiel: Angebot veröffentlichen

```ts
const { data, error } = await supabase
  .from('offers')
  .update({ status: 'published' })
  .eq('id', offerId)
  .select()
  .single();
```

---

## 6.5 Offer Search / Swipe Feed

Für den Tinder-Style Feed sollte das Frontend eine optimierte View oder RPC Function verwenden.

Empfohlen:

```sql
public.search_offers(
  p_location_name text default null,
  p_available_from timestamptz default null,
  p_available_to timestamptz default null,
  p_tags text[] default null,
  p_limit int default 20,
  p_offset int default 0
)
```

### TypeScript Contract

```ts
type SearchOffersInput = {
  location_name?: string | null;
  available_from?: ISODateTime | null;
  available_to?: ISODateTime | null;
  tags?: string[] | null;
  limit?: number;
  offset?: number;
};

type SearchOfferResult = Offer & {
  organization_name: string;
  organization_avatar_url: string | null;
  organization_average_rating: number | null;
  has_applied: boolean;
};
```

### Beispiel: Angebote für Swipe Feed laden

```ts
const { data, error } = await supabase.rpc('search_offers', {
  p_location_name: 'Berlin',
  p_available_from: '2026-07-01T00:00:00.000Z',
  p_available_to: '2026-07-31T23:59:59.999Z',
  p_tags: ['event'],
  p_limit: 20,
  p_offset: 0
});
```

---

## 6.6 Applications

Tabelle: `applications`

Eine Bewerbung verbindet einen Helfer mit einem Angebot.

### Status

```ts
type ApplicationStatus =
  | 'submitted'
  | 'under_review'
  | 'accepted'
  | 'rejected'
  | 'withdrawn'
  | 'cancelled'
  | 'completed';
```

### TypeScript Contract

```ts
type Application = {
  id: UUID;
  offer_id: UUID;
  helper_profile_id: UUID;
  status: ApplicationStatus;
  message: string | null;
  selected_document_ids: UUID[];
  created_at: ISODateTime;
  updated_at: ISODateTime;
};
```

### Business-Regeln

- Ein Helfer darf sich pro Angebot nur einmal bewerben.
- Nur Helfer dürfen Bewerbungen erstellen.
- Organisationen sehen Bewerbungen auf ihre eigenen Angebote.
- Helfer sehen ihre eigenen Bewerbungen.
- Helfer dürfen eine Bewerbung zurückziehen, solange sie noch nicht abgeschlossen ist.
- Organisationen dürfen Bewerbungen annehmen oder ablehnen.
- Angenommene Bewerbungen haben verbindlichen Charakter.

### Beispiel: Bewerbung erstellen

```ts
const { data, error } = await supabase
  .from('applications')
  .insert({
    offer_id: offerId,
    helper_profile_id: helperProfileId,
    message: 'Ich habe an dem Tag Zeit und helfe gerne beim Aufbau.',
    selected_document_ids: [documentId]
  })
  .select()
  .single();
```

### Beispiel: Bewerbungen für ein Angebot laden

```ts
const { data, error } = await supabase
  .from('applications')
  .select(`
    *,
    helper:helper_profiles(
      id,
      skills,
      profile:profiles(id, display_name, avatar_url, average_rating, rating_count, bio)
    )
  `)
  .eq('offer_id', offerId)
  .order('created_at', { ascending: false });
```

### Beispiel: Bewerbung annehmen

```ts
const { data, error } = await supabase
  .from('applications')
  .update({ status: 'accepted' })
  .eq('id', applicationId)
  .select()
  .single();
```

Für spätere Versionen sollte diese Statusänderung eventuell über eine RPC Function laufen, damit Kapazitätsgrenzen atomar geprüft werden können.

---

## 6.7 Documents

Tabelle: `documents`  
Storage Bucket: `user-documents`

Helfer können Dokumente hinterlegen und ausgewählte Dokumente mit Bewerbungen teilen.

### TypeScript Contract

```ts
type DocumentVisibility = 'private' | 'shared_with_application';

type UserDocument = {
  id: UUID;
  owner_profile_id: UUID;
  title: string;
  file_path: string;
  mime_type: string;
  size_bytes: number;
  visibility: DocumentVisibility;
  created_at: ISODateTime;
  updated_at: ISODateTime;
};
```

### Business-Regeln

- Dokumente sind standardmäßig privat.
- Organisationen dürfen Dokumente nur sehen, wenn sie mit einer Bewerbung auf ein eigenes Angebot geteilt wurden.
- Storage-Pfade müssen über RLS/Storage Policies geschützt sein.
- Dokumente dürfen nicht öffentlich abrufbar sein.

### Beispiel: Dokument hochladen

```ts
const filePath = `${user.id}/${crypto.randomUUID()}-${file.name}`;

const { data: uploadData, error: uploadError } = await supabase.storage
  .from('user-documents')
  .upload(filePath, file, {
    cacheControl: '3600',
    upsert: false
  });
```

### Beispiel: Dokument-Metadaten speichern

```ts
const { data, error } = await supabase
  .from('documents')
  .insert({
    owner_profile_id: profileId,
    title: file.name,
    file_path: filePath,
    mime_type: file.type,
    size_bytes: file.size,
    visibility: 'private'
  })
  .select()
  .single();
```

### Beispiel: signierte URL erzeugen

```ts
const { data, error } = await supabase.storage
  .from('user-documents')
  .createSignedUrl(filePath, 60);
```

---

## 6.8 Ratings

Tabelle: `ratings`

Bewertungen können nach einem abgeschlossenen Angebot in beide Richtungen abgegeben werden.

```ts
type RatingTargetType = 'helper' | 'organization';

type Rating = {
  id: UUID;
  offer_id: UUID;
  application_id: UUID;
  reviewer_profile_id: UUID;
  target_profile_id: UUID;
  target_type: RatingTargetType;
  stars: number;
  comment: string | null;
  created_at: ISODateTime;
  updated_at: ISODateTime;
};
```

### Business-Regeln

- Bewertungen sind nur nach abgeschlossenem Einsatz möglich.
- Pro Richtung darf nur eine Bewertung pro Bewerbung existieren.
- `stars` muss zwischen 1 und 5 liegen.
- Durchschnittsbewertungen in `profiles.average_rating` werden serverseitig berechnet oder über Trigger aktualisiert.

### Beispiel: Bewertung erstellen

```ts
const { data, error } = await supabase
  .from('ratings')
  .insert({
    offer_id: offerId,
    application_id: applicationId,
    reviewer_profile_id: myProfileId,
    target_profile_id: targetProfileId,
    target_type: 'organization',
    stars: 5,
    comment: 'Sehr gut organisiert und freundliches Team.'
  })
  .select()
  .single();
```

---

## 6.9 Messages / Chat

Tabelle: `conversations`  
Tabelle: `messages`

Kommunikation findet zwischen Organisation und Helfer statt, sobald eine Bewerbung existiert oder die Organisation den Helfer in Betracht zieht.

### Conversation

```ts
type Conversation = {
  id: UUID;
  application_id: UUID;
  offer_id: UUID;
  helper_profile_id: UUID;
  organization_profile_id: UUID;
  created_at: ISODateTime;
  updated_at: ISODateTime;
};
```

### Message

```ts
type Message = {
  id: UUID;
  conversation_id: UUID;
  sender_profile_id: UUID;
  body: string;
  read_at: ISODateTime | null;
  created_at: ISODateTime;
};
```

### Business-Regeln

- Nur Teilnehmer einer Conversation dürfen Nachrichten lesen.
- Nur Teilnehmer einer Conversation dürfen Nachrichten schreiben.
- Admins können im Moderationsfall Zugriff erhalten, falls rechtlich/produktseitig gewünscht.

### Beispiel: Nachrichten laden

```ts
const { data, error } = await supabase
  .from('messages')
  .select('*, sender:profiles(id, display_name, avatar_url)')
  .eq('conversation_id', conversationId)
  .order('created_at', { ascending: true });
```

### Beispiel: Nachricht senden

```ts
const { data, error } = await supabase
  .from('messages')
  .insert({
    conversation_id: conversationId,
    sender_profile_id: myProfileId,
    body: 'Hallo, ich hätte Interesse und bin am Samstag verfügbar.'
  })
  .select()
  .single();
```

### Realtime Subscription

```ts
const channel = supabase
  .channel(`conversation:${conversationId}`)
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'messages',
      filter: `conversation_id=eq.${conversationId}`
    },
    payload => {
      console.log('Neue Nachricht', payload.new);
    }
  )
  .subscribe();
```

---

## 6.10 Favorites / Saved Offers

Tabelle: `saved_offers`

Helfer können Angebote merken.

```ts
type SavedOffer = {
  id: UUID;
  helper_profile_id: UUID;
  offer_id: UUID;
  created_at: ISODateTime;
};
```

### Beispiel: Angebot merken

```ts
const { data, error } = await supabase
  .from('saved_offers')
  .insert({
    helper_profile_id: helperProfileId,
    offer_id: offerId
  })
  .select()
  .single();
```

### Beispiel: gemerkte Angebote laden

```ts
const { data, error } = await supabase
  .from('saved_offers')
  .select('*, offer:offers(*)')
  .eq('helper_profile_id', helperProfileId)
  .order('created_at', { ascending: false });
```

---

## 7. Storage Contract

## 7.1 Buckets

| Bucket | Zweck | Öffentlich? |
|---|---|---|
| `avatars` | Profilbilder für Helfer und Vereine | Ja oder signed, je nach Produktentscheidung |
| `user-documents` | Private Dokumente wie Führungszeugnisse | Nein |
| `offer-images` | Bilder zu Angeboten | Optional öffentlich |

## 7.2 Profilbild hochladen

```ts
const filePath = `${user.id}/avatar-${Date.now()}.jpg`;

const { data, error } = await supabase.storage
  .from('avatars')
  .upload(filePath, file, { upsert: true });
```

Danach wird `profiles.avatar_url` aktualisiert.

```ts
const { data: publicUrl } = supabase.storage
  .from('avatars')
  .getPublicUrl(filePath);

await supabase
  .from('profiles')
  .update({ avatar_url: publicUrl.publicUrl })
  .eq('user_id', user.id);
```

---

## 8. Realtime Contract

Realtime wird zunächst für folgende Bereiche verwendet:

| Bereich | Event | Zweck |
|---|---|---|
| Messages | `INSERT` | Neue Chat-Nachrichten anzeigen |
| Applications | `UPDATE` | Statusänderungen anzeigen |
| Offers | `UPDATE` | Angebot geschlossen/storniert/aktualisiert |

### Beispiel: Bewerbungsstatus abonnieren

```ts
const channel = supabase
  .channel(`application:${applicationId}`)
  .on(
    'postgres_changes',
    {
      event: 'UPDATE',
      schema: 'public',
      table: 'applications',
      filter: `id=eq.${applicationId}`
    },
    payload => {
      console.log('Status geändert', payload.new.status);
    }
  )
  .subscribe();
```

---

## 9. Edge Functions / RPC Functions

Direkte Tabellenzugriffe reichen für einfache CRUD-Fälle aus. Für komplexere Aktionen sollten RPC Functions oder Edge Functions verwendet werden.

## 9.1 Empfohlene RPC Functions

### `search_offers`

Für Feed, Filter und Swipe-Ansicht.

### `accept_application`

Nimmt eine Bewerbung atomar an und prüft dabei:

- Gehört das Angebot zur Organisation?
- Ist das Angebot noch offen?
- Ist die maximale Helferzahl noch nicht erreicht?
- Ist die Bewerbung im korrekten Status?

```ts
const { data, error } = await supabase.rpc('accept_application', {
  p_application_id: applicationId
});
```

### `reject_application`

Lehnt eine Bewerbung ab.

```ts
const { data, error } = await supabase.rpc('reject_application', {
  p_application_id: applicationId,
  p_reason: 'Leider sind bereits alle Plätze vergeben.'
});
```

### `complete_application`

Markiert einen Einsatz als abgeschlossen.

```ts
const { data, error } = await supabase.rpc('complete_application', {
  p_application_id: applicationId
});
```

### `create_conversation_for_application`

Erzeugt oder lädt eine Conversation zu einer Bewerbung.

```ts
const { data, error } = await supabase.rpc('create_conversation_for_application', {
  p_application_id: applicationId
});
```

---

## 10. Berechtigungen / RLS Contract

Das Frontend darf sich auf folgende Regeln verlassen. Die eigentliche Durchsetzung passiert serverseitig.

## 10.1 Profiles

| Aktion | Erlaubt für |
|---|---|
| Eigenes Profil lesen | Besitzer |
| Öffentliches aktives Profil lesen | Authentifizierte Nutzer |
| Eigenes Profil bearbeiten | Besitzer |
| Rolle ändern | Admin |
| Status ändern | Admin |

## 10.2 Offers

| Aktion | Erlaubt für |
|---|---|
| Veröffentlichte Angebote lesen | Authentifizierte Nutzer |
| Eigene Drafts lesen | Besitzer-Organisation |
| Angebot erstellen | Organisation |
| Angebot bearbeiten | Besitzer-Organisation |
| Angebot löschen/stornieren | Besitzer-Organisation oder Admin |

## 10.3 Applications

| Aktion | Erlaubt für |
|---|---|
| Bewerbung erstellen | Helfer |
| Eigene Bewerbung lesen | Bewerbender Helfer |
| Bewerbungen auf eigenes Angebot lesen | Besitzer-Organisation |
| Bewerbung annehmen/ablehnen | Besitzer-Organisation |
| Bewerbung zurückziehen | Bewerbender Helfer |

## 10.4 Documents

| Aktion | Erlaubt für |
|---|---|
| Eigenes Dokument hochladen | Besitzer |
| Eigenes Dokument lesen | Besitzer |
| Geteiltes Dokument lesen | Organisation des betreffenden Angebots |
| Dokument löschen | Besitzer |

## 10.5 Messages

| Aktion | Erlaubt für |
|---|---|
| Conversation lesen | Teilnehmer |
| Nachricht senden | Teilnehmer |
| Nachricht lesen | Teilnehmer |

---

## 11. Status-Transitions

## 11.1 OfferStatus

```txt
draft -> published
published -> closed
published -> cancelled
published -> completed
closed -> completed
```

Nicht erlaubt:

```txt
completed -> published
cancelled -> published
```

## 11.2 ApplicationStatus

```txt
submitted -> under_review
submitted -> accepted
submitted -> rejected
submitted -> withdrawn
under_review -> accepted
under_review -> rejected
under_review -> withdrawn
accepted -> cancelled
accepted -> completed
```

Nicht erlaubt:

```txt
rejected -> accepted
withdrawn -> accepted
completed -> withdrawn
```

## 11.3 ProfileStatus

```txt
active -> inactive
active -> suspended
inactive -> active
suspended -> active
active -> deleted
inactive -> deleted
suspended -> deleted
```

`deleted` ist ein terminaler Status und soll nicht zurück auf `active` wechseln.

---

## 12. Frontend Screens und benötigte API Calls

## 12.1 Onboarding

Benötigte Calls:

1. Auth Signup/Login
2. `profiles.insert` oder Trigger-basiertes Profil erzeugen
3. `helper_profiles.insert` oder `organization_profiles.insert`
4. Optional Avatar Upload

## 12.2 Helfer Home / Swipe Feed

Benötigte Calls:

1. `search_offers` RPC
2. `saved_offers.select`
3. `applications.select` zur Prüfung, ob bereits beworben

## 12.3 Angebotsdetail

Benötigte Calls:

1. `offers.select` mit Organisation
2. `applications.select` für eigenen Bewerbungsstatus
3. `ratings.select` für Bewertungen des Vereins

## 12.4 Bewerbung absenden

Benötigte Calls:

1. `documents.select` für auswählbare Dokumente
2. `applications.insert`
3. Optional `create_conversation_for_application` RPC

## 12.5 Organisation Dashboard

Benötigte Calls:

1. Eigene `organization_profiles.select`
2. Eigene `offers.select`
3. `applications.select` für Bewerbungen auf eigene Angebote
4. Realtime auf `applications`

## 12.6 Chat

Benötigte Calls:

1. `conversations.select`
2. `messages.select`
3. `messages.insert`
4. Realtime auf `messages`

## 12.7 Bewertungen

Benötigte Calls:

1. `applications.select` abgeschlossene Einsätze
2. `ratings.insert`
3. `ratings.select`

---

## 13. Validierung im Frontend

Das Frontend validiert frühzeitig für bessere UX, aber Backend bleibt führend.

### Offer Validation

```ts
type OfferValidationRules = {
  title: {
    required: true;
    minLength: 5;
    maxLength: 120;
  };
  description: {
    required: true;
    minLength: 20;
    maxLength: 5000;
  };
  needed_helpers_count: {
    min: 1;
    max: 500;
  };
  min_age: {
    min: 0;
    max: 120;
  };
};
```

### Rating Validation

```ts
type RatingValidationRules = {
  stars: {
    required: true;
    min: 1;
    max: 5;
  };
  comment: {
    maxLength: 2000;
  };
};
```

---

## 14. Sicherheitsanforderungen

1. Das Frontend verwendet niemals den Supabase `service_role` Key.
2. Alle Tabellen mit Nutzerdaten haben Row Level Security aktiviert.
3. Private Dokumente liegen ausschließlich in nicht-öffentlichen Storage Buckets.
4. Dokumentzugriff erfolgt über signierte URLs mit kurzer Gültigkeit.
5. Admin-Rechte werden nur serverseitig vergeben.
6. Statuswechsel werden über Constraints, Trigger oder RPC Functions abgesichert.
7. Bewertungen können nicht beliebig erstellt werden, sondern nur für abgeschlossene Einsätze.
8. Chat-Zugriffe sind auf Conversation-Teilnehmer begrenzt.

---

## 15. Versionierung des API Contracts

Dieses Dokument wird versioniert. Änderungen, die Frontend-Code brechen können, benötigen eine neue Contract-Version.

```ts
type ApiContractVersion = 'v1';
```

Breaking Changes sind zum Beispiel:

- Umbenennung von Tabellen oder Spalten
- Änderung von Enum-Werten
- Entfernen von Response-Feldern
- Änderung von Status-Transitions
- Änderung der RLS-Semantik

Nicht-breaking Changes sind zum Beispiel:

- Neue optionale Felder
- Neue Views
- Neue RPC Functions
- Zusätzliche Response-Felder

---

## 16. Offene Entscheidungen

Folgende Punkte sollten noch final entschieden werden:

1. Sollen Profilbilder öffentlich oder nur über signed URLs abrufbar sein?
2. Gibt es eine Verifikation für Vereine in einer späteren Version?
3. Darf ein Helfer mehrere Rollen haben, zum Beispiel Helfer und Vereinsadmin?
4. Sollen flexible Angebote Bewerbungen ohne konkreten Termin erlauben?
5. Sollen Organisationen Helfer direkt anschreiben dürfen oder erst nach Bewerbung?
6. Sollen Admins Chat-Nachrichten lesen dürfen?
7. Wird Moderation/Melden von Nutzern oder Angeboten direkt in v1 benötigt?
8. Werden Push Notifications über Supabase Edge Functions angebunden?

---

## 17. Minimaler v1 Scope

Für eine erste Version reichen diese API-Bausteine:

1. Auth
2. Profile
3. Helper Profile
4. Organization Profile
5. Offers
6. Offer Search / Swipe Feed
7. Applications
8. Documents
9. Messages
10. Ratings
11. Saved Offers
12. Realtime für Messages und Application Status
