# EventTwin AI

Standalone Flutter application for measured event-space planning. The repository supports Supabase email authentication and organization-scoped venues, rooms, and event drafts. The floor-plan editor remains an explicitly selected local demonstration.

The full product brief is in [docs/MASTER_BUILD_PROMPT.md](docs/MASTER_BUILD_PROMPT.md).

## Run

Requires Flutter 3.47.5 or a compatible stable release.

### Supabase mode

1. Copy `supabase.local.json.example` to `supabase.local.json` and enter the project's **publishable** key locally. This file is ignored by Git. Never use a service-role key in the Flutter app.
2. The migrations in `supabase/migrations` are applied to the EventTwin Supabase project. For another project, apply them in version order before signing up.
3. Run:

```powershell
flutter run -d chrome --dart-define-from-file=supabase.local.json
```

The configured URL defaults to the supplied EventTwin project. Email sign-up, sign-in, password reset, organization creation, and RLS-protected venue, room, and event draft operations are available.

### Local demonstration mode

```powershell
flutter run -d chrome --dart-define=EVENTTWIN_LOCAL_DEMO=true
```

Local data is stored in browser or device preferences. It has no cloud authentication or tenant isolation. Do not enter confidential BEOs in this demonstration.

## Local floor-plan demonstration

1. Create a venue and enter a rectangular room's verified width and depth in feet.
2. Create an event, paste BEO text or use the clearly labeled sample, and extract explicit `Event:` and `Guests:` lines. Enter missing fields manually.
3. Review and confirm the requirements. The sample BEO describes a 120-guest corporate dinner. There is no AI or document extraction yet.
4. Generate three distinct round-table arrangements. The engine uses meters internally, a 1.8 m table diameter, 0.9 m surrounding clearance, and ten seats per table.
5. Drag a table, review collision and boundary warnings, save the valid edit, and export a dimensioned planning PDF.

The engine rejects layouts it cannot fit. Its current validation covers table clearances and rectangular room boundaries only. Exits, columns, other furniture, circulation paths, accessibility rules, and regulatory compliance require later work. Exported plans are labeled planning drafts.

## Verify

```powershell
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed lib test
```

The transactional SQL test in `supabase/tests/tenant_isolation.sql` checks owner and viewer access under simulated authenticated users. Run it with a privileged SQL connection; it rolls back its fixture data.

## Scope and limitations

The migrations define profiles, organizations, memberships, venues, spaces, events, and floor plans with role-based RLS. They were applied to the supplied EventTwin Supabase project on October 9, 2026. Floor-plan approval is blocked in the database until authoritative server validation is built. The Flutter cloud workspace exposes organization creation and venue, room, and event draft operations. Floor-plan generation/editor and PDF export remain in local demo mode; cloud layouts, private BEO document storage, invitation flows, and broader RLS authorization tests are not connected yet. The app does not yet include irregular room geometry, fixed features, AI document processing, authoritative server validation, optimization, or simulation. Claude API, Python services, Stripe, and Three.js are not connected yet.
