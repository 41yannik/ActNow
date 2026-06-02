# ActNow Data Model

Dieses Dokument beschreibt ein erstes relationales Datenmodell für ActNow mit Supabase/Postgres als Backend. Es basiert auf den bisher definierten Rollen und Kernfunktionen: Helfer, Vereine/Anbieter, Admins, Angebote, Bewerbungen, Dokumentfreigaben, Kommunikation und Bewertungen.

## Grundannahmen

- Authentifizierung läuft über `auth.users` von Supabase.
- Jede registrierte Person/Organisation hat genau ein App-Profil in `profiles`.
- Nutzer können unterschiedliche Profiltypen haben, primär `helper`, `organization` oder `admin`.
- Anbieter können gemeinnützige Vereine, Initiativen oder andere registrierte Anbieter sein. Die genaue Anbieterart wird im Profil modelliert.
- Aktuell ist keine formale Verifikation geplant, das Modell lässt spätere Verifikation aber zu.
- Angebote können einmalig, wiederkehrend, flexibel oder digital sein.
- Matching/Bewerbung erfolgt über `applications`.
- Kommunikation zwischen Helfer und Anbieter wird erst nach Bewerbung beziehungsweise Interesse ermöglicht.
- Bewertungen sind gegenseitig: Helfer bewerten Anbieter und Anbieter bewerten Helfer.
- Dokumente werden von Helfern hochgeladen und können gezielt für einzelne Bewerbungen/Angebote freigegeben werden.

---

## PostgreSQL Extensions

```sql
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";
create extension if not exists "postgis"; -- optional, falls später Geodaten benötigt werden
```

---

## Enum Types

```sql
create type user_role as enum ('helper', 'organization', 'admin');
create type profile_status as enum ('active', 'inactive', 'suspended', 'deleted');
create type organization_type as enum ('club', 'nonprofit', 'initiative', 'public_institution', 'company', 'private_person', 'other');
create type offer_type as enum ('single_event', 'recurring_event', 'flexible_task', 'digital_task');
create type offer_status as enum ('draft', 'published', 'paused', 'filled', 'completed', 'cancelled', 'archived');
create type application_status as enum ('submitted', 'shortlisted', 'accepted', 'rejected', 'withdrawn', 'cancelled', 'completed', 'no_show');
create type document_type as enum ('criminal_record_certificate', 'identity_document', 'qualification', 'certificate', 'other');
create type document_status as enum ('active', 'expired', 'revoked', 'deleted');
create type message_status as enum ('sent', 'read', 'deleted');
create type recurrence_frequency as enum ('daily', 'weekly', 'monthly', 'custom');
```

---

# Tables

## 1. `profiles`

Zentrale Profiltabelle für alle App-Nutzer. Verknüpft mit Supabase Auth.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `user_id` | `uuid` | no | - | Referenz auf `auth.users.id` |
| `role` | `user_role` | no | - | Hauptrolle des Profils |
| `status` | `profile_status` | no | `'active'` | Status des Profils |
| `display_name` | `text` | no | - | Öffentlicher Anzeigename |
| `slug` | `text` | no | - | Öffentliche, eindeutige URL-Kennung |
| `avatar_url` | `text` | yes | - | Profilbild im Supabase Storage |
| `bio` | `text` | yes | - | Kurzbeschreibung/Biografie |
| `city` | `text` | yes | - | Ort/Stadt |
| `postal_code` | `text` | yes | - | PLZ |
| `country_code` | `char(2)` | no | `'DE'` | ISO-Ländercode |
| `phone` | `text` | yes | - | Optional, nicht zwingend öffentlich |
| `website_url` | `text` | yes | - | Website, besonders für Vereine |
| `average_rating` | `numeric(3,2)` | no | `0` | Denormalisierter Bewertungsdurchschnitt |
| `rating_count` | `integer` | no | `0` | Anzahl Bewertungen |
| `created_at` | `timestamptz` | no | `now()` | Erstellzeitpunkt |
| `updated_at` | `timestamptz` | no | `now()` | Änderungszeitpunkt |

### Constraints

```sql
alter table profiles
  add constraint profiles_user_id_unique unique (user_id),
  add constraint profiles_slug_unique unique (slug),
  add constraint profiles_display_name_length check (char_length(display_name) between 2 and 120),
  add constraint profiles_bio_length check (bio is null or char_length(bio) <= 2000),
  add constraint profiles_rating_range check (average_rating >= 0 and average_rating <= 5),
  add constraint profiles_rating_count_nonnegative check (rating_count >= 0),
  add constraint profiles_auth_user_fk foreign key (user_id) references auth.users(id) on delete cascade;
```

### Indexes

```sql
create index profiles_role_idx on profiles(role);
create index profiles_status_idx on profiles(status);
create index profiles_city_idx on profiles(city);
```

---

## 2. `helper_profiles`

Rollenspezifische Zusatzdaten für Helfer.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `profile_id` | `uuid` | no | - | PK/FK zu `profiles.id` |
| `date_of_birth` | `date` | yes | - | Optional, falls Altersprüfung später nötig wird |
| `skills` | `text[]` | no | `'{}'` | Fähigkeiten/Interessen |
| `languages` | `text[]` | no | `'{}'` | Sprachen |
| `availability_note` | `text` | yes | - | Freitext zur Verfügbarkeit |
| `has_drivers_license` | `boolean` | no | `false` | Führerschein vorhanden |
| `has_car` | `boolean` | no | `false` | Eigenes Auto vorhanden |
| `emergency_contact_name` | `text` | yes | - | Optional, nur intern/sensibel |
| `emergency_contact_phone` | `text` | yes | - | Optional, nur intern/sensibel |
| `created_at` | `timestamptz` | no | `now()` | Erstellzeitpunkt |
| `updated_at` | `timestamptz` | no | `now()` | Änderungszeitpunkt |

### Constraints

```sql
alter table helper_profiles
  add constraint helper_profiles_pk primary key (profile_id),
  add constraint helper_profiles_profile_fk foreign key (profile_id) references profiles(id) on delete cascade,
  add constraint helper_profiles_availability_note_length check (availability_note is null or char_length(availability_note) <= 1000);
```

---

## 3. `organization_profiles`

Rollenspezifische Zusatzdaten für Vereine/Anbieter.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `profile_id` | `uuid` | no | - | PK/FK zu `profiles.id` |
| `organization_type` | `organization_type` | no | `'club'` | Art des Anbieters |
| `legal_name` | `text` | yes | - | Rechtlicher Name, falls vorhanden |
| `registration_number` | `text` | yes | - | Vereinsregister-/Registernummer, optional |
| `tax_id` | `text` | yes | - | Optional, eher intern |
| `contact_person_name` | `text` | yes | - | Ansprechpartner |
| `contact_email` | `text` | yes | - | Kontaktadresse |
| `contact_phone` | `text` | yes | - | Telefonnummer |
| `is_verified` | `boolean` | no | `false` | Für spätere Verifikation |
| `verified_at` | `timestamptz` | yes | - | Verifikationszeitpunkt |
| `created_at` | `timestamptz` | no | `now()` | Erstellzeitpunkt |
| `updated_at` | `timestamptz` | no | `now()` | Änderungszeitpunkt |

### Constraints

```sql
alter table organization_profiles
  add constraint organization_profiles_pk primary key (profile_id),
  add constraint organization_profiles_profile_fk foreign key (profile_id) references profiles(id) on delete cascade,
  add constraint organization_verified_consistency check (
    (is_verified = false and verified_at is null) or
    (is_verified = true and verified_at is not null)
  );
```

---

## 4. `offers`

Angebote/Einsätze, die von Anbietern erstellt werden.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `organization_profile_id` | `uuid` | no | - | Anbieterprofil |
| `title` | `text` | no | - | Titel des Angebots |
| `description` | `text` | no | - | Beschreibung |
| `offer_type` | `offer_type` | no | - | Angebotsart |
| `status` | `offer_status` | no | `'draft'` | Veröffentlichungsstatus |
| `category` | `text` | yes | - | Kategorie, z. B. Sport, Soziales, Umwelt |
| `skills_required` | `text[]` | no | `'{}'` | Benötigte Fähigkeiten |
| `min_age` | `integer` | yes | - | Mindestalter, optional |
| `max_helpers` | `integer` | yes | - | Benötigte Anzahl Helfer |
| `accepted_helpers_count` | `integer` | no | `0` | Denormalisierte Anzahl Zusagen |
| `location_name` | `text` | yes | - | Ortsbezeichnung |
| `street` | `text` | yes | - | Straße, optional |
| `postal_code` | `text` | yes | - | PLZ |
| `city` | `text` | yes | - | Stadt |
| `country_code` | `char(2)` | no | `'DE'` | ISO-Ländercode |
| `is_remote` | `boolean` | no | `false` | Digitales/remote Angebot |
| `starts_at` | `timestamptz` | yes | - | Startzeit bei festen Terminen |
| `ends_at` | `timestamptz` | yes | - | Endzeit bei festen Terminen |
| `application_deadline` | `timestamptz` | yes | - | Bewerbungsfrist |
| `is_binding` | `boolean` | no | `true` | Anmeldung hat verbindlichen Charakter |
| `requires_documents` | `boolean` | no | `false` | Dokumente erforderlich? |
| `published_at` | `timestamptz` | yes | - | Veröffentlichungszeitpunkt |
| `completed_at` | `timestamptz` | yes | - | Abschlusszeitpunkt |
| `cancelled_at` | `timestamptz` | yes | - | Stornozeitpunkt |
| `created_at` | `timestamptz` | no | `now()` | Erstellzeitpunkt |
| `updated_at` | `timestamptz` | no | `now()` | Änderungszeitpunkt |

### Constraints

```sql
alter table offers
  add constraint offers_pk primary key (id),
  add constraint offers_organization_fk foreign key (organization_profile_id) references organization_profiles(profile_id) on delete cascade,
  add constraint offers_title_length check (char_length(title) between 5 and 160),
  add constraint offers_description_length check (char_length(description) between 20 and 5000),
  add constraint offers_min_age_range check (min_age is null or min_age between 0 and 120),
  add constraint offers_max_helpers_positive check (max_helpers is null or max_helpers > 0),
  add constraint offers_accepted_helpers_nonnegative check (accepted_helpers_count >= 0),
  add constraint offers_accepted_not_above_max check (max_helpers is null or accepted_helpers_count <= max_helpers),
  add constraint offers_time_order check (starts_at is null or ends_at is null or ends_at > starts_at),
  add constraint offers_deadline_before_start check (application_deadline is null or starts_at is null or application_deadline <= starts_at),
  add constraint offers_remote_location_check check (
    is_remote = true or city is not null
  ),
  add constraint offers_published_consistency check (
    (status = 'published' and published_at is not null) or status <> 'published'
  );
```

### Indexes

```sql
create index offers_organization_idx on offers(organization_profile_id);
create index offers_status_idx on offers(status);
create index offers_offer_type_idx on offers(offer_type);
create index offers_city_idx on offers(city);
create index offers_starts_at_idx on offers(starts_at);
create index offers_published_at_idx on offers(published_at desc);
create index offers_skills_required_gin_idx on offers using gin(skills_required);
```

---

## 5. `offer_recurrences`

Für wiederkehrende Angebote. Wird nur genutzt, wenn `offers.offer_type = 'recurring_event'`.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `offer_id` | `uuid` | no | - | Zugehöriges Angebot |
| `frequency` | `recurrence_frequency` | no | - | Wiederholungsfrequenz |
| `interval` | `integer` | no | `1` | Alle n Tage/Wochen/Monate |
| `by_weekday` | `integer[]` | yes | - | Wochentage 1-7, optional |
| `repeat_until` | `date` | yes | - | Ende der Wiederholung |
| `rrule` | `text` | yes | - | Optional für komplexe Wiederholungen |
| `created_at` | `timestamptz` | no | `now()` | Erstellzeitpunkt |

### Constraints

```sql
alter table offer_recurrences
  add constraint offer_recurrences_pk primary key (id),
  add constraint offer_recurrences_offer_fk foreign key (offer_id) references offers(id) on delete cascade,
  add constraint offer_recurrences_offer_unique unique (offer_id),
  add constraint offer_recurrences_interval_positive check (interval > 0),
  add constraint offer_recurrences_weekday_range check (
    by_weekday is null or by_weekday <@ array[1,2,3,4,5,6,7]
  );
```

---

## 6. `applications`

Bewerbungen von Helfern auf Angebote.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `offer_id` | `uuid` | no | - | Angebot |
| `helper_profile_id` | `uuid` | no | - | Helferprofil |
| `status` | `application_status` | no | `'submitted'` | Bewerbungsstatus |
| `motivation_text` | `text` | yes | - | Optionales Bewerbungsschreiben |
| `organization_note` | `text` | yes | - | Interne Notiz des Anbieters |
| `helper_message` | `text` | yes | - | Kurze Nachricht des Helfers |
| `submitted_at` | `timestamptz` | no | `now()` | Bewerbungszeitpunkt |
| `accepted_at` | `timestamptz` | yes | - | Zusagezeitpunkt |
| `rejected_at` | `timestamptz` | yes | - | Absagezeitpunkt |
| `withdrawn_at` | `timestamptz` | yes | - | Rückzugszeitpunkt |
| `completed_at` | `timestamptz` | yes | - | Abschlusszeitpunkt |
| `created_at` | `timestamptz` | no | `now()` | Erstellzeitpunkt |
| `updated_at` | `timestamptz` | no | `now()` | Änderungszeitpunkt |

### Constraints

```sql
alter table applications
  add constraint applications_pk primary key (id),
  add constraint applications_offer_fk foreign key (offer_id) references offers(id) on delete cascade,
  add constraint applications_helper_fk foreign key (helper_profile_id) references helper_profiles(profile_id) on delete cascade,
  add constraint applications_unique_helper_offer unique (offer_id, helper_profile_id),
  add constraint applications_motivation_length check (motivation_text is null or char_length(motivation_text) <= 2000),
  add constraint applications_helper_message_length check (helper_message is null or char_length(helper_message) <= 1000),
  add constraint applications_organization_note_length check (organization_note is null or char_length(organization_note) <= 2000),
  add constraint applications_status_timestamp_consistency check (
    (status = 'accepted' and accepted_at is not null) or
    (status = 'rejected' and rejected_at is not null) or
    (status = 'withdrawn' and withdrawn_at is not null) or
    (status = 'completed' and completed_at is not null) or
    status in ('submitted', 'shortlisted', 'cancelled', 'no_show')
  );
```

### Indexes

```sql
create index applications_offer_idx on applications(offer_id);
create index applications_helper_idx on applications(helper_profile_id);
create index applications_status_idx on applications(status);
create index applications_submitted_at_idx on applications(submitted_at desc);
```

---

## 7. `helper_documents`

Von Helfern hinterlegte Dokumente, z. B. Führungszeugnis oder Qualifikationsnachweise.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `helper_profile_id` | `uuid` | no | - | Besitzer des Dokuments |
| `document_type` | `document_type` | no | - | Dokumentart |
| `status` | `document_status` | no | `'active'` | Dokumentstatus |
| `title` | `text` | no | - | Anzeigename |
| `description` | `text` | yes | - | Optionaler Hinweis |
| `storage_bucket` | `text` | no | - | Supabase Storage Bucket |
| `storage_path` | `text` | no | - | Pfad im Storage |
| `mime_type` | `text` | no | - | MIME-Type |
| `file_size_bytes` | `bigint` | no | - | Dateigröße |
| `issued_at` | `date` | yes | - | Ausstellungsdatum |
| `expires_at` | `date` | yes | - | Ablaufdatum |
| `created_at` | `timestamptz` | no | `now()` | Erstellzeitpunkt |
| `updated_at` | `timestamptz` | no | `now()` | Änderungszeitpunkt |

### Constraints

```sql
alter table helper_documents
  add constraint helper_documents_pk primary key (id),
  add constraint helper_documents_helper_fk foreign key (helper_profile_id) references helper_profiles(profile_id) on delete cascade,
  add constraint helper_documents_title_length check (char_length(title) between 2 and 160),
  add constraint helper_documents_file_size_positive check (file_size_bytes > 0),
  add constraint helper_documents_file_size_max check (file_size_bytes <= 20971520), -- 20 MB
  add constraint helper_documents_expiry_after_issue check (issued_at is null or expires_at is null or expires_at >= issued_at),
  add constraint helper_documents_storage_unique unique (storage_bucket, storage_path);
```

### Indexes

```sql
create index helper_documents_helper_idx on helper_documents(helper_profile_id);
create index helper_documents_type_idx on helper_documents(document_type);
create index helper_documents_status_idx on helper_documents(status);
```

---

## 8. `application_document_shares`

Gezielte Freigabe von Helferdokumenten für eine konkrete Bewerbung.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `application_id` | `uuid` | no | - | Bewerbung |
| `document_id` | `uuid` | no | - | Freigegebenes Dokument |
| `shared_at` | `timestamptz` | no | `now()` | Freigabezeitpunkt |
| `revoked_at` | `timestamptz` | yes | - | Widerrufszeitpunkt |
| `created_at` | `timestamptz` | no | `now()` | Erstellzeitpunkt |

### Constraints

```sql
alter table application_document_shares
  add constraint application_document_shares_pk primary key (id),
  add constraint application_document_shares_application_fk foreign key (application_id) references applications(id) on delete cascade,
  add constraint application_document_shares_document_fk foreign key (document_id) references helper_documents(id) on delete cascade,
  add constraint application_document_shares_unique unique (application_id, document_id),
  add constraint application_document_shares_revoke_after_share check (revoked_at is null or revoked_at >= shared_at);
```

### Wichtig

Zusätzlich sollte per Trigger oder Application Logic geprüft werden, dass das freigegebene Dokument demselben Helfer gehört wie die Bewerbung.

---

## 9. `conversations`

Chat-Konversationen zwischen Helfer und Anbieter, typischerweise bezogen auf eine Bewerbung.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `application_id` | `uuid` | no | - | Zugehörige Bewerbung |
| `offer_id` | `uuid` | no | - | Redundanz für einfachere Queries |
| `helper_profile_id` | `uuid` | no | - | Helfer |
| `organization_profile_id` | `uuid` | no | - | Anbieter |
| `last_message_at` | `timestamptz` | yes | - | Letzte Aktivität |
| `created_at` | `timestamptz` | no | `now()` | Erstellzeitpunkt |
| `updated_at` | `timestamptz` | no | `now()` | Änderungszeitpunkt |

### Constraints

```sql
alter table conversations
  add constraint conversations_pk primary key (id),
  add constraint conversations_application_fk foreign key (application_id) references applications(id) on delete cascade,
  add constraint conversations_offer_fk foreign key (offer_id) references offers(id) on delete cascade,
  add constraint conversations_helper_fk foreign key (helper_profile_id) references helper_profiles(profile_id) on delete cascade,
  add constraint conversations_organization_fk foreign key (organization_profile_id) references organization_profiles(profile_id) on delete cascade,
  add constraint conversations_application_unique unique (application_id);
```

---

## 10. `messages`

Nachrichten innerhalb einer Konversation.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `conversation_id` | `uuid` | no | - | Konversation |
| `sender_profile_id` | `uuid` | no | - | Absender |
| `body` | `text` | no | - | Nachrichtentext |
| `status` | `message_status` | no | `'sent'` | Nachrichtenstatus |
| `read_at` | `timestamptz` | yes | - | Gelesen-Zeitpunkt |
| `created_at` | `timestamptz` | no | `now()` | Sendezeitpunkt |
| `updated_at` | `timestamptz` | no | `now()` | Änderungszeitpunkt |

### Constraints

```sql
alter table messages
  add constraint messages_pk primary key (id),
  add constraint messages_conversation_fk foreign key (conversation_id) references conversations(id) on delete cascade,
  add constraint messages_sender_fk foreign key (sender_profile_id) references profiles(id) on delete cascade,
  add constraint messages_body_length check (char_length(body) between 1 and 5000),
  add constraint messages_read_consistency check (
    (status = 'read' and read_at is not null) or status <> 'read'
  );
```

### Indexes

```sql
create index messages_conversation_created_idx on messages(conversation_id, created_at asc);
create index messages_sender_idx on messages(sender_profile_id);
```

---

## 11. `ratings`

Gegenseitige Bewertungen nach einem abgeschlossenen Angebot.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `application_id` | `uuid` | no | - | Bezug zur Teilnahme/Bewerbung |
| `offer_id` | `uuid` | no | - | Angebot |
| `rater_profile_id` | `uuid` | no | - | Bewertende Person/Organisation |
| `rated_profile_id` | `uuid` | no | - | Bewertetes Profil |
| `score` | `integer` | no | - | 1 bis 5 Sterne |
| `comment` | `text` | yes | - | Optionaler Kommentar |
| `is_public` | `boolean` | no | `true` | Öffentlich sichtbar? |
| `created_at` | `timestamptz` | no | `now()` | Erstellzeitpunkt |
| `updated_at` | `timestamptz` | no | `now()` | Änderungszeitpunkt |

### Constraints

```sql
alter table ratings
  add constraint ratings_pk primary key (id),
  add constraint ratings_application_fk foreign key (application_id) references applications(id) on delete cascade,
  add constraint ratings_offer_fk foreign key (offer_id) references offers(id) on delete cascade,
  add constraint ratings_rater_fk foreign key (rater_profile_id) references profiles(id) on delete cascade,
  add constraint ratings_rated_fk foreign key (rated_profile_id) references profiles(id) on delete cascade,
  add constraint ratings_score_range check (score between 1 and 5),
  add constraint ratings_no_self_rating check (rater_profile_id <> rated_profile_id),
  add constraint ratings_comment_length check (comment is null or char_length(comment) <= 2000),
  add constraint ratings_unique_per_direction unique (application_id, rater_profile_id, rated_profile_id);
```

### Indexes

```sql
create index ratings_rated_profile_idx on ratings(rated_profile_id);
create index ratings_rater_profile_idx on ratings(rater_profile_id);
create index ratings_offer_idx on ratings(offer_id);
```

---

## 12. `offer_history_items`

Öffentliche Historie früherer Angebote eines Vereins. Diese kann auch aus `offers` abgeleitet werden; eine separate Tabelle ist optional, wenn historische Snapshots benötigt werden.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `offer_id` | `uuid` | no | - | Ursprüngliches Angebot |
| `organization_profile_id` | `uuid` | no | - | Anbieter |
| `title_snapshot` | `text` | no | - | Titel zum Zeitpunkt des Abschlusses |
| `city_snapshot` | `text` | yes | - | Ort zum Zeitpunkt des Abschlusses |
| `starts_at_snapshot` | `timestamptz` | yes | - | Startzeit-Snapshot |
| `completed_at` | `timestamptz` | no | - | Abschlusszeitpunkt |
| `helper_count` | `integer` | no | `0` | Anzahl angenommener/abgeschlossener Helfer |
| `created_at` | `timestamptz` | no | `now()` | Erstellzeitpunkt |

### Constraints

```sql
alter table offer_history_items
  add constraint offer_history_items_pk primary key (id),
  add constraint offer_history_items_offer_fk foreign key (offer_id) references offers(id) on delete cascade,
  add constraint offer_history_items_organization_fk foreign key (organization_profile_id) references organization_profiles(profile_id) on delete cascade,
  add constraint offer_history_items_offer_unique unique (offer_id),
  add constraint offer_history_items_helper_count_nonnegative check (helper_count >= 0);
```

---

## 13. `saved_offers`

Von Helfern gespeicherte/gelikte Angebote, z. B. für Swipe-UX oder Merkliste.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `helper_profile_id` | `uuid` | no | - | Helfer |
| `offer_id` | `uuid` | no | - | Angebot |
| `created_at` | `timestamptz` | no | `now()` | Speicherzeitpunkt |

### Constraints

```sql
alter table saved_offers
  add constraint saved_offers_pk primary key (id),
  add constraint saved_offers_helper_fk foreign key (helper_profile_id) references helper_profiles(profile_id) on delete cascade,
  add constraint saved_offers_offer_fk foreign key (offer_id) references offers(id) on delete cascade,
  add constraint saved_offers_unique unique (helper_profile_id, offer_id);
```

---

## 14. `offer_swipes`

Optionale Tabelle für Tinder-Style-Swiping. Trennt reine Swipe-Interaktion von verbindlicher Bewerbung.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `helper_profile_id` | `uuid` | no | - | Helfer |
| `offer_id` | `uuid` | no | - | Angebot |
| `direction` | `text` | no | - | `left`, `right`, `skip` |
| `created_at` | `timestamptz` | no | `now()` | Swipe-Zeitpunkt |

### Constraints

```sql
alter table offer_swipes
  add constraint offer_swipes_pk primary key (id),
  add constraint offer_swipes_helper_fk foreign key (helper_profile_id) references helper_profiles(profile_id) on delete cascade,
  add constraint offer_swipes_offer_fk foreign key (offer_id) references offers(id) on delete cascade,
  add constraint offer_swipes_unique unique (helper_profile_id, offer_id),
  add constraint offer_swipes_direction_check check (direction in ('left', 'right', 'skip'));
```

---

## 15. `notifications`

In-App-Benachrichtigungen.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `recipient_profile_id` | `uuid` | no | - | Empfänger |
| `type` | `text` | no | - | Notification-Typ |
| `title` | `text` | no | - | Titel |
| `body` | `text` | yes | - | Nachricht |
| `entity_type` | `text` | yes | - | z. B. `offer`, `application`, `message` |
| `entity_id` | `uuid` | yes | - | ID der referenzierten Entität |
| `read_at` | `timestamptz` | yes | - | Gelesen-Zeitpunkt |
| `created_at` | `timestamptz` | no | `now()` | Erstellzeitpunkt |

### Constraints

```sql
alter table notifications
  add constraint notifications_pk primary key (id),
  add constraint notifications_recipient_fk foreign key (recipient_profile_id) references profiles(id) on delete cascade,
  add constraint notifications_title_length check (char_length(title) between 1 and 160),
  add constraint notifications_body_length check (body is null or char_length(body) <= 1000);
```

### Indexes

```sql
create index notifications_recipient_created_idx on notifications(recipient_profile_id, created_at desc);
create index notifications_unread_idx on notifications(recipient_profile_id) where read_at is null;
```

---

## 16. `admin_audit_log`

Audit-Trail für Admin-Aktionen und kritische Änderungen.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `actor_profile_id` | `uuid` | yes | - | Admin oder Systemakteur |
| `action` | `text` | no | - | Aktion, z. B. `profile.suspend` |
| `entity_type` | `text` | no | - | Betroffene Tabelle/Entität |
| `entity_id` | `uuid` | yes | - | Betroffene ID |
| `old_values` | `jsonb` | yes | - | Vorheriger Zustand |
| `new_values` | `jsonb` | yes | - | Neuer Zustand |
| `ip_address` | `inet` | yes | - | Optional |
| `user_agent` | `text` | yes | - | Optional |
| `created_at` | `timestamptz` | no | `now()` | Zeitpunkt |

### Constraints

```sql
alter table admin_audit_log
  add constraint admin_audit_log_pk primary key (id),
  add constraint admin_audit_log_actor_fk foreign key (actor_profile_id) references profiles(id) on delete set null,
  add constraint admin_audit_log_action_length check (char_length(action) between 3 and 120),
  add constraint admin_audit_log_entity_type_length check (char_length(entity_type) between 2 and 120);
```

---

## 17. `reports`

Meldungen von Nutzern, z. B. unangemessene Inhalte, problematische Nachrichten oder No-Shows.

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `reporter_profile_id` | `uuid` | no | - | Meldende Person |
| `reported_profile_id` | `uuid` | yes | - | Gemeldetes Profil |
| `entity_type` | `text` | yes | - | Gemeldete Entität |
| `entity_id` | `uuid` | yes | - | ID der Entität |
| `reason` | `text` | no | - | Grund |
| `details` | `text` | yes | - | Beschreibung |
| `status` | `text` | no | `'open'` | `open`, `in_review`, `resolved`, `dismissed` |
| `resolved_by_profile_id` | `uuid` | yes | - | Admin |
| `resolved_at` | `timestamptz` | yes | - | Abschlusszeitpunkt |
| `created_at` | `timestamptz` | no | `now()` | Erstellzeitpunkt |
| `updated_at` | `timestamptz` | no | `now()` | Änderungszeitpunkt |

### Constraints

```sql
alter table reports
  add constraint reports_pk primary key (id),
  add constraint reports_reporter_fk foreign key (reporter_profile_id) references profiles(id) on delete cascade,
  add constraint reports_reported_profile_fk foreign key (reported_profile_id) references profiles(id) on delete set null,
  add constraint reports_resolved_by_fk foreign key (resolved_by_profile_id) references profiles(id) on delete set null,
  add constraint reports_status_check check (status in ('open', 'in_review', 'resolved', 'dismissed')),
  add constraint reports_reason_length check (char_length(reason) between 3 and 160),
  add constraint reports_details_length check (details is null or char_length(details) <= 3000),
  add constraint reports_resolution_consistency check (
    (status in ('resolved', 'dismissed') and resolved_at is not null) or
    (status in ('open', 'in_review'))
  );
```

---

# Storage Buckets

## `avatars`

Für Profilbilder von Helfern und Organisationen.

Empfohlene Regeln:

- Maximale Dateigröße: 5 MB
- Erlaubte MIME-Types: `image/jpeg`, `image/png`, `image/webp`
- Pfadstruktur: `profiles/{profile_id}/avatar.{ext}`

## `helper-documents`

Für sensible Helferdokumente.

Empfohlene Regeln:

- Privater Bucket, niemals öffentlich.
- Zugriff nur für Dokumentbesitzer, explizit freigegebene Organisationen und Admins.
- Maximale Dateigröße: 20 MB
- Erlaubte MIME-Types: `application/pdf`, `image/jpeg`, `image/png`
- Pfadstruktur: `helpers/{helper_profile_id}/documents/{document_id}.{ext}`

---

# Row Level Security Hinweise

Alle App-Tabellen sollten RLS aktiviert haben.

```sql
alter table profiles enable row level security;
alter table helper_profiles enable row level security;
alter table organization_profiles enable row level security;
alter table offers enable row level security;
alter table applications enable row level security;
alter table helper_documents enable row level security;
alter table application_document_shares enable row level security;
alter table conversations enable row level security;
alter table messages enable row level security;
alter table ratings enable row level security;
```

## Grobe Policy-Regeln

### Profile

- Jeder kann aktive öffentliche Profile lesen.
- Nutzer dürfen ihr eigenes Profil lesen und bearbeiten.
- Admins dürfen alle Profile lesen und bearbeiten.
- Sensible Felder wie Telefon, Notfallkontakt, interne Notizen sollten nicht über öffentliche Views ausgeliefert werden.

### Angebote

- Jeder eingeloggte Nutzer kann veröffentlichte Angebote lesen.
- Organisationen können eigene Angebote erstellen, bearbeiten und archivieren.
- Admins können alle Angebote bearbeiten.

### Bewerbungen

- Helfer sehen ihre eigenen Bewerbungen.
- Organisationen sehen Bewerbungen auf ihre eigenen Angebote.
- Admins sehen alle Bewerbungen.
- Ein Helfer darf sich nur einmal auf dasselbe Angebot bewerben.

### Dokumente

- Helfer sehen und verwalten nur eigene Dokumente.
- Organisationen sehen nur Dokumente, die für eine Bewerbung auf eines ihrer Angebote freigegeben wurden und nicht widerrufen sind.
- Admins sehen alle Dokument-Metadaten; tatsächlicher Dateizugriff sollte besonders streng geregelt werden.

### Nachrichten

- Zugriff nur für Teilnehmer der jeweiligen Konversation.
- Adminzugriff nur für Moderation/Audit und idealerweise gesondert protokolliert.

### Bewertungen

- Nutzer können nur nach abgeschlossenen Einsätzen bewerten.
- Jede Bewertungsrichtung pro Bewerbung ist nur einmal erlaubt.
- Öffentliche Anzeige nur für `is_public = true`.

---

# Empfohlene Views

## `public_profiles_view`

Öffentliche Profildaten ohne sensible Felder.

Enthält z. B.:

- `id`
- `role`
- `display_name`
- `slug`
- `avatar_url`
- `bio`
- `city`
- `average_rating`
- `rating_count`
- bei Organisationen: `organization_type`, `is_verified`

## `published_offers_view`

Nur sichtbare Angebote.

Filter:

```sql
where status = 'published'
```

Optional zusätzlich:

```sql
and (application_deadline is null or application_deadline >= now())
and (starts_at is null or starts_at >= now())
```

## `organization_rating_summary_view`

Bewertungsübersicht je Anbieter.

Felder:

- `organization_profile_id`
- `average_rating`
- `rating_count`
- `last_rating_at`

## `helper_rating_summary_view`

Bewertungsübersicht je Helfer.

Felder:

- `helper_profile_id`
- `average_rating`
- `rating_count`
- `completed_applications_count`
- `no_show_count`

---

# Trigger und Business Logic

## `updated_at` automatisch setzen

Für fast alle Tabellen mit `updated_at` sollte ein generischer Trigger verwendet werden.

```sql
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;
```

## Rating-Durchschnitt aktualisieren

Nach Insert/Update/Delete auf `ratings`:

- Durchschnitt und Anzahl für `rated_profile_id` neu berechnen.
- `profiles.average_rating` und `profiles.rating_count` aktualisieren.

## Accepted Helpers Count aktualisieren

Nach Änderung von `applications.status`:

- Anzahl `accepted` pro `offer_id` neu berechnen.
- `offers.accepted_helpers_count` aktualisieren.
- Optional Status auf `filled` setzen, wenn `accepted_helpers_count >= max_helpers`.

## Conversation automatisch erstellen

Nach Bewerbung oder nach Status `shortlisted`/`accepted`:

- Falls Kommunikation erst nach Interesse erlaubt ist, Conversation erst bei `shortlisted` oder `accepted` erstellen.
- Falls Kommunikation direkt nach Bewerbung erlaubt ist, Conversation beim Insert in `applications` erstellen.

## Dokumentfreigabe validieren

Vor Insert in `application_document_shares` prüfen:

- Dokument gehört dem Helfer der Bewerbung.
- Dokumentstatus ist `active`.
- Dokument ist nicht abgelaufen.

---

# Offene Design-Entscheidungen

1. **Ein Profil pro Account oder mehrere Profile pro Account?**  
   Dieses Modell geht von einem Profil pro Supabase-User aus. Falls ein Nutzer mehrere Organisationen verwalten soll, braucht es zusätzlich `organization_memberships`.

2. **Dürfen auch Privatpersonen Angebote einstellen?**  
   Das Modell erlaubt dies über `organization_type = 'private_person'`, obwohl die Rolle technisch `organization` bleibt.

3. **Wie verbindlich ist eine Bewerbung?**  
   `offers.is_binding` modelliert dies auf Angebotsebene. Zusätzliche AGB-/Bestätigungsschritte könnten in `applications` ergänzt werden.

4. **Brauchen wir Geokoordinaten?**  
   Aktuell wird nach Ortsname gefiltert. Für Umkreissuche sollte später `location geography(Point, 4326)` in `offers` ergänzt werden.

5. **Wer darf Bewertungen löschen oder ausblenden?**  
   Aktuell über `is_public` und Admin-Rechte lösbar. Für Moderation kann eine zusätzliche Tabelle `rating_moderation_actions` ergänzt werden.

6. **Wie detailliert sollen Verfügbarkeiten der Helfer modelliert werden?**  
   Aktuell nur als Freitext. Für Matching nach festen Zeitfenstern wäre eine zusätzliche Tabelle `helper_availability_slots` sinnvoll.

---

# Optional: Erweiterung für Organisationsteams

Falls mehrere Nutzer denselben Verein verwalten sollen:

## `organization_memberships`

| Column | Type | Nullable | Default | Beschreibung |
|---|---:|:---:|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | Primärschlüssel |
| `organization_profile_id` | `uuid` | no | - | Organisation |
| `member_profile_id` | `uuid` | no | - | Nutzerprofil |
| `role` | `text` | no | `'member'` | `owner`, `admin`, `member` |
| `created_at` | `timestamptz` | no | `now()` | Erstellzeitpunkt |

### Constraints

```sql
alter table organization_memberships
  add constraint organization_memberships_pk primary key (id),
  add constraint organization_memberships_org_fk foreign key (organization_profile_id) references organization_profiles(profile_id) on delete cascade,
  add constraint organization_memberships_member_fk foreign key (member_profile_id) references profiles(id) on delete cascade,
  add constraint organization_memberships_unique unique (organization_profile_id, member_profile_id),
  add constraint organization_memberships_role_check check (role in ('owner', 'admin', 'member'));
```

---

# Minimaler MVP-Tabellensatz

Für einen ersten MVP reichen wahrscheinlich diese Tabellen:

1. `profiles`
2. `helper_profiles`
3. `organization_profiles`
4. `offers`
5. `applications`
6. `helper_documents`
7. `application_document_shares`
8. `conversations`
9. `messages`
10. `ratings`
11. `notifications`
12. `admin_audit_log`
13. `saved_offers`

Die Tabellen `offer_swipes`, `offer_history_items`, `reports` und `organization_memberships` können bei Bedarf im zweiten Schritt ergänzt werden.
