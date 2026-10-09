# EventTwin AI

Standalone Flutter application for measured event-space planning. Supabase mode supports email authentication and organization-scoped venues, rooms, events, and versioned floor-plan drafts. A separate local demonstration remains available.

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

The configured URL defaults to the supplied EventTwin project. Email sign-up, sign-in, password reset, and organization-scoped venue, room, event, and floor-plan draft operations are available.

For a cloud floor plan, create a venue and a room, verify its measurements, create an event, and confirm the entered requirements against the source. Open **Floor plans** on that event. Generate three options, select a saved version, drag a table, and save the edit as a new version. Saved versions can be exported as planning PDFs. The database checks round-table capacity, boundaries, and clearances when each version is inserted; invalid drafts are rejected.

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

The transactional SQL tests in `supabase/tests` check tenant access and floor-plan validation under simulated authenticated users. Run them with a privileged SQL connection; both roll back their fixture data.

## Scope and limitations

The migrations define profiles, organizations, memberships, venues, spaces, events, and floor plans with role-based RLS. They were applied to the supplied EventTwin Supabase project on October 9, 2026. The server validates round-table draft geometry, but floor-plan approval stays blocked until exits, fixed features, and other required constraints are modeled. Cloud floor plans are immutable versions. Private BEO document storage, invitation flows, and broader authorization tests remain to be built. The app does not yet include irregular room geometry, fixed features, AI document processing, full operational optimization, or simulation. Claude API, Python services, Stripe, and Three.js are not connected yet.
