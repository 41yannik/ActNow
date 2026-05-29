# Repository instructions for GitHub Copilot

Before implementing, editing, refactoring, or deleting code, always read and follow the project specification files in `/docs`.

The canonical project files are:

- [Problem statement](../docs/problem-statement.md)
- [User roles](../docs/user-roles.md)
- [Core user stories](../docs/user-stories.md)
- [Technical requirements](../docs/technical-requirements.md)
- [Data model](../docs/data-model.md)
- [API contract](../docs/api-contract.md)
- [UI screens](../docs/ui-screens.md)
- [Acceptance criteria](../docs/acceptance-criteria.md)
- [Deployment assumptions](../docs/deployment.md)

These files are the source of truth for the application.

When working on this repository:

1. Do not invent features that are not described in the requirements or user stories.
2. Do not create database tables, columns, API behavior, or UI flows that contradict the data model or API contract.
3. Do not weaken permissions, authentication, authorization, or Supabase RLS policies.
4. If a requested change conflicts with the docs, explain the conflict before changing code.
5. If the docs are incomplete, ask a clarifying question or propose an update to the relevant doc before implementing.
6. Always update the relevant docs when implementation changes behavior.
7. Always add or update tests when behavior changes.
8. Prefer small, reviewable changes over large rewrites.

For Supabase:

- Database schema changes must not be implemented as migrations during early development. Instead, update `docs/schema.sql` as the single-source-of-truth for the database schema
- Seed data must remain consistent with `docs/data-model.md`.

For frontend work:

- Build reusable components before feature-specific screens.
- UI screens must follow `docs/ui-screens.md`.
- Frontend data access must follow `docs/api-contract.md`.
- Include loading, empty, error, and success states where relevant.

For deployment:

- Deployment changes must follow `docs/deployment-assumptions.md`.
- Do not hardcode secrets.
- Keep `.env.example` updated.
- Docker builds must be reproducible.