# ActNow – historische Backend-Dokumentation

> Dieses Verzeichnis wird von der statischen Portfolio-Demo weder gebaut noch veröffentlicht oder
> zur Laufzeit kontaktiert. Es dokumentiert ausschließlich die frühere Backend-Ausarbeitung des
> Masterprojekts.

Die Demo unter `actnow.yannik-h-huber.de` liest ihre fiktiven Beispieldaten aus typisierten
TypeScript-Fixtures in `frontend/src/lib/demo/`. Sie benötigt keine Supabase-Instanz, keine
Umgebungsvariablen, keine Zugangsdaten und keine Hintergrund-Workflows.

## Archivinhalt

- `migrations/`: historische Tabellen, Enums, Trigger, RLS-Regeln, RPCs und Storage-Policies
- `seed.sql`: historische Entwicklungsdaten ohne gemeinsam nutzbares Demo-Kennwort
- `tests/rls_smoke.sql`: frühere RLS-Prüfungen
- `config.toml`: Konfiguration zur optionalen lokalen Rekonstruktion der damaligen Architektur
- `../docs/schema.sql`: eingefrorene Schema-Referenz vor Einführung der Migrationen

Die Dateien dürfen nicht als Konfiguration der Portfolio-Demo verstanden werden. Insbesondere
werden keine Seed-Konten für Besucher bereitgestellt und es existiert kein Login in der Demo.

## Optionale historische Rekonstruktion

Wer die alte Backend-Architektur zu Dokumentations- oder Forschungszwecken lokal nachvollziehen
möchte, kann bei installiertem Supabase CLI und laufendem Docker den Archiv-Stack starten:

```bash
./scripts/setup-backend.sh
```

Dieser Ablauf ist kein Bestandteil des Frontend-Builds oder des GitHub-Pages-Deployments. Die
Seed-Nutzer besitzen absichtlich kein bekanntes gemeinsames Kennwort.

Schemaänderungen an diesem Archiv erfolgen ausschließlich durch zusätzliche Dateien unter
`migrations/`; bereits vorhandene Migrationen bleiben als Projekthistorie unverändert.
