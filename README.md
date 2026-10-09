# EventTwin AI

Standalone Flutter application for measured event-space planning. This repository currently contains an **early local demonstration**, not a production SaaS deployment.

The full product brief is in [docs/MASTER_BUILD_PROMPT.md](docs/MASTER_BUILD_PROMPT.md).

## Run

Requires Flutter 3.47.5 or a compatible stable release.

```powershell
flutter pub get
flutter run -d chrome
```

The amber banner identifies local mode. Data is stored in browser or device preferences. It has no cloud authentication, collaboration, or tenant isolation. Do not enter confidential BEOs in this demonstration.

## Current workflow

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

## Next milestones

Connect Supabase Auth and a tenant-isolated schema before storing real user data. Then add verified irregular room geometry and fixed features, BEO document processing with explicit source references and confirmation, authoritative server validation, optimization, and simulation. Claude API, Python services, Stripe, and Three.js are not connected yet.
