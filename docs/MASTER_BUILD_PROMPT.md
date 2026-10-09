# CODEX MASTER BUILD PROMPT
# EventTwin AI | Standalone Flutter SaaS

You are the Lead Software Architect, Senior Flutter Engineer, AI Systems Engineer, Computational Geometry Engineer, and SaaS Product Developer responsible for building a production-ready application called **EventTwin AI**.

Your task is to architect, implement, test, and progressively deliver the actual working application.

Do not stop at planning, documentation, mockups, or scaffolding.

Build functional software, beginning with a working end-to-end MVP and expanding incrementally.

## 1. PRODUCT VISION

**Product Name:** EventTwin AI

**Tagline:** Don't just design the event. Rehearse its success.

EventTwin AI is an AI-powered event design, spatial optimization, and operational simulation platform for:

- Hotels and resorts
- Convention centers
- Arenas and stadiums
- Banquet facilities
- Catering companies
- Wedding and event planners
- Corporate event departments
- Event production companies

The application converts Banquet Event Orders (BEOs) into multiple accurate, editable event floor plans, then simulates guest movement, staffing, service efficiency, room transitions, and event execution.

The defining experience:

**Upload BEO → Extract Requirements → Select Venue → Generate Layouts → Compare Options → Edit Floor Plan → Simulate Event → Optimize → Export Execution Plan**

The platform must be standalone and independently commercializable.

Do not integrate Venue Wrangler or depend on any existing venue management platform.

## 2. REQUIRED TECHNOLOGY STACK

### Frontend
- Flutter, latest compatible stable release
- Dart
- Riverpod for state management
- GoRouter for navigation
- Freezed and JSON serialization
- CustomPainter for interactive 2D floor plans
- Responsive desktop, tablet, and mobile layouts

### Backend
- Supabase PostgreSQL
- Supabase Authentication
- Supabase Storage
- Supabase Realtime
- Row Level Security
- Python FastAPI for computational services
- Durable background job processing

### AI
- Claude API for BEO interpretation and natural-language commands
- Structured JSON outputs
- Document processing and OCR fallback
- Provider abstraction for future AI model changes

### Geometry and Simulation
- Shapely for geometric operations
- OR-Tools for constraint optimization
- SimPy for discrete-event simulation
- NumPy for numerical calculations
- Three.js for future 3D rendering

### Infrastructure
- GitHub Actions
- Docker
- Environment-based configuration
- Stripe for future SaaS billing
- Automated testing

Use current stable, compatible package versions. Verify dependencies before implementation.

## 3. ENGINEERING RULES

1. Build actual working features, not decorative UI.
2. Never create buttons without functioning behavior.
3. Never fabricate API responses in production.
4. Development fixtures are permitted when external credentials are unavailable.
5. Do not hardcode secrets.
6. Implement secure multi-tenant access.
7. Use clean architecture and reusable components.
8. Separate AI reasoning from deterministic calculations.
9. All geometry must use real measurements.
10. Use meters as the internal coordinate system.
11. Support feet and meters in the UI.
12. Persist important user actions.
13. Include error handling and loading states.
14. Write tests for critical functionality.
15. Run available tests before declaring completion.
16. Commit completed, tested milestones when Git access permits.
17. Never claim a feature is complete if it is not functional.
18. Do not claim regulatory compliance based only on software calculations.
19. Never invent room measurements or missing BEO details.
20. Do not introduce unnecessary enterprise complexity into the MVP.

Create and maintain an AGENTS.md file containing the project conventions and development instructions.

## 4. APPLICATION DESIGN

Build a sophisticated, premium SaaS interface.

### Visual direction

Professional architectural design software combined with modern hospitality technology.

Use:
- Warm white and light-gray backgrounds
- Deep navy navigation
- Subtle teal and muted gold accents
- Crisp typography
- Elegant icons
- Professional tables
- Compact contextual controls
- Smooth, purposeful interactions
- Clear visual hierarchy

Avoid:
- Generic AI-generated dashboards
- Excessive gradients
- Unnecessary animations
- Oversized rounded cards
- Crowded interfaces
- Decorative controls without functionality

### Desktop navigation

Dashboard
Events
BEO Library
Venues & Spaces
Floor Plan Studio
Event Simulator
Furniture Library
Operations
Exports
Team
Settings

The floor plan editor must be desktop-first.

Mobile users should be able to upload BEOs, review designs, inspect simulations, approve plans, and access operational instructions.

## 5. ORGANIZATIONS AND AUTHENTICATION

Implement:

- User registration
- Login/logout
- Password recovery
- Organization creation
- Organization invitations
- Team membership
- Role-based permissions
- User profiles

Roles:
- Owner
- Administrator
- Event Manager
- Designer
- Operations Manager
- Viewer

Organizations must have completely isolated data.

Implement Supabase RLS policies and authorization tests.

## 6. VENUE AND ROOM BUILDER

Users must be able to create venues containing multiple event spaces.

Each space should support:

- Room name
- Room dimensions
- Irregular polygon boundaries
- Columns
- Doors
- Emergency exits
- Door swing areas
- Permanent bars
- Fixed stages
- Windows
- Movable partitions
- Restricted areas
- Equipment access points

Create an interactive room geometry editor.

Allow users to:

- Draw room boundaries
- Enter exact measurements
- Add architectural features
- Move and resize elements
- Set room scale
- Upload existing floor plan drawings
- Calibrate imported drawings
- Save reusable room templates

Do not assume uploaded drawings have an accurate scale.

Require measurement verification before using a room for validated layouts.

## 7. AI BEO INTELLIGENCE

Create a BEO upload and interpretation engine.

Accept:
- PDF
- DOCX
- JPG
- PNG
- Pasted text
- Manual event entry

Extract:

Event name
Event date
Start and end times
Venue
Room
Expected guest count
Guaranteed guest count
Event type
Seating configuration
Tables and chairs
Stage requirements
Dance floor
Buffet stations
Bars
Registration stations
AV requirements
Service stations
Special instructions
Accessibility requirements
Event timeline
Room setup and breakdown instructions

Display the original BEO beside the extracted information.

Each extracted field should include:
- Value
- Confidence indicator
- Source reference when available
- User-editable confirmation status

Distinguish explicit requirements from assumptions.

Never silently invent missing information.

Users must confirm critical requirements before generating layouts.

Save immutable BEO versions.

## 8. AUTOMATIC FLOOR PLAN GENERATOR

This is a critical application feature.

The system must automatically generate three to five distinct floor plan configurations using:

- Verified room geometry
- Confirmed BEO requirements
- Furniture dimensions
- Guest counts
- Service requirements
- Operational constraints

### Layout strategies

Generate layouts optimized for:

A. Maximum feasible seating

B. Guest experience and circulation

C. Banquet service efficiency

D. Presentation visibility

E. Balanced overall performance

### Supported objects

Round banquet tables
Rectangular tables
Cocktail tables
Chairs
Theater seating
Classroom seating
Buffet stations
Bars
Stages
Dance floors
Registration stations
AV stations
Service stations
Decorative areas

Every object must have accurate dimensions and coordinates.

### Hard constraints

- Furniture cannot overlap.
- Objects cannot extend beyond permitted room boundaries.
- Required exits must remain unobstructed.
- Fixed architectural elements must be respected.
- Configured clearance requirements must be enforced.
- Seating calculations must be accurate.

If the requested setup cannot fit, explain the conflict.

Do not fabricate a valid layout.

### Generation engine

Implement deterministic geometry validation.

Use constraint optimization to generate candidate layouts.

Score feasible layouts using:

- Guest circulation
- Service efficiency
- Sightlines
- Space utilization
- Setup complexity
- Aesthetic balance

Return genuinely different options.

Store generation parameters and validation results.

## 9. INTERACTIVE FLOOR PLAN STUDIO

Build a fully interactive 2D editor using Flutter CustomPainter.

### Editor layout

Left panel:
Furniture and object library

Center:
Zoomable floor plan canvas

Right panel:
Object properties and dimensions

Bottom panel:
Validation warnings and layout statistics

Top toolbar:
Save, undo, redo, regenerate, compare, simulate, export

### Functionality

- Drag and drop
- Resize
- Rotate
- Duplicate
- Delete
- Multi-select
- Group objects
- Lock objects
- Snap to grid
- Alignment guides
- Distance measurements
- Undo/redo
- Auto-save
- Version history
- Furniture labels
- Table numbering

Recalculate relevant measurements after edits.

Provide immediate collision warnings.

Run authoritative backend validation before final approval.

## 10. EVENT SIMULATION ENGINE

This is the primary competitive differentiator.

Build a discrete-event simulation engine using Python and SimPy.

The simulation must model event operations using configurable assumptions.

### Simulation inputs

- Guest count
- Arrival distribution
- Event schedule
- Room geometry
- Table positions
- Bar locations
- Buffet locations
- Service station positions
- Staffing levels
- Service durations
- Walking speeds
- Queue behavior
- Event format

### Simulated activity

Guest arrivals
Registration queues
Guest movement
Bar service
Buffet service
Plated dinner operations
Staff travel
Station utilization
Event transitions
Room breakdown

### Outputs

- Estimated guest travel distances
- Estimated queue lengths
- Estimated wait times
- Congestion heatmaps
- Station utilization
- Staff workload estimates
- Operational bottlenecks
- Comparison between layout alternatives

### Important

Simulation results must be clearly labeled as estimates.

Use documented assumptions.

Do not present predictions as guaranteed outcomes.

Allow users to adjust assumptions and rerun simulations.

The first working simulation should focus on guest arrival and buffet or bar queues.

Expand to more sophisticated service models afterward.

## 11. SIMULATION VISUALIZATION

Create an animated 2D simulation interface.

Show:
- Guest movement
- Service station activity
- Queue formation
- Congestion areas
- Simulation clock
- Event timeline
- Live simulation statistics

Users must be able to:
- Start
- Pause
- Resume
- Reset
- Adjust playback speed
- Switch between layout options

Simulation playback should be based on calculated simulation results, not random animations.

## 12. AI OPTIMIZATION ASSISTANT

Add a natural-language assistant inside the Floor Plan Studio.

Example requests:

"Move the buffet stations closer to the service entrance."

"Create a layout with better guest circulation."

"Increase seating to 250 guests."

"Reduce congestion around the bars."

"Add a second registration station."

"Keep the same seating count but reduce service travel."

Translate user instructions into structured edit operations.

Validate proposed changes before applying them.

Allow users to preview and undo changes.

Explain when requests are physically infeasible.

## 13. ROOM FLIP ENGINE

Create a module that compares two consecutive event layouts in the same space.

Generate:

- Furniture removal list
- Furniture addition list
- Furniture relocation instructions
- Setup sequence
- Task dependencies
- Estimated labor requirements
- Estimated transition duration

Use configurable labor and task-duration assumptions.

Identify when a requested room flip may not fit the available transition window.

Do not claim exact labor requirements without supporting data.

## 14. EQUIPMENT AND OPERATIONS

For each approved floor plan, generate:

- Table counts
- Chair counts
- Linen requirements
- Stage components
- Bar equipment
- Buffet equipment
- Setup equipment
- Area-specific setup instructions
- Room reset instructions

Create an operations view designed for banquet captains and setup teams.

Do not build a complete inventory management platform.

Only track the equipment requirements and optional available quantities necessary to evaluate an event setup.

## 15. 3D EVENT DIGITAL TWIN

After the 2D editor and simulation engine are functional, implement 3D visualization.

Use Three.js.

The 3D scene must use the same saved coordinates and geometry as the 2D floor plan.

Support:
- Orbit camera
- Top-down view
- Guest perspective
- Stage perspective
- Furniture models
- Room walls
- Lighting
- Basic materials
- Animated guest movement
- Screenshot export

Do not use AI-generated pictures as substitutes for dimensionally accurate 3D geometry.

Prioritize performance over photorealism.

## 16. AI SETUP VERIFICATION

Implement this after the core application is stable.

Allow staff to upload photographs of the completed event setup.

Use computer vision to identify visible furniture and compare it against the approved floor plan.

Flag possible discrepancies, such as:
- Missing tables
- Incorrect table placement
- Missing chairs
- Obstructed visible pathways
- Unexpected furniture

Results must be presented as suggestions requiring human confirmation.

A single photograph cannot verify an entire room.

Support multiple images and clear confidence indicators.

## 17. OPERATIONAL LEARNING

Build a future-ready event outcomes module.

Allow managers to record:

- Actual setup time
- Actual breakdown time
- Actual service times
- Staffing used
- Guest congestion issues
- Equipment shortages
- Service delays
- Manager observations

Compare actual results against simulated estimates.

Store anonymized or appropriately permissioned operational metrics.

Use historical results to improve future simulation assumptions.

Do not implement opaque self-training that changes production recommendations without validation.

## 18. DATABASE

Design a normalized Supabase schema covering:

organizations
profiles
organization_members
venues
spaces
space_geometry_versions
space_features
furniture_catalog
events
event_spaces
beo_documents
beo_versions
event_requirements
layout_generation_jobs
floorplans
floorplan_versions
floorplan_objects
layout_validations
simulation_scenarios
simulation_jobs
simulation_results
simulation_metrics
room_flip_plans
equipment_requirements
event_outcomes
exports
subscriptions
audit_logs

Add appropriate indexes, foreign keys, constraints, timestamps, and RLS policies.

Use private storage for sensitive documents.

Maintain immutable approved layout versions.

## 19. EXPORTS

Support:

- Dimensioned floor plan PDF
- High-resolution PNG
- SVG
- Equipment list CSV
- Room setup instructions PDF
- Simulation comparison report
- Client presentation PDF

Include event details, layout version, and validation status.

## 20. SUBSCRIPTION ARCHITECTURE

Prepare for standalone SaaS commercialization.

Plans:
- Starter
- Professional
- Business
- Enterprise

Support configurable usage limits.

Build the billing architecture so Stripe can be activated without redesigning the application.

Do not make live Stripe integration a blocker for the initial MVP.

## 21. DEVELOPMENT PHASES

Implement in this order.

### Phase 1: Foundation
Flutter application, authentication, organizations, navigation, Supabase schema, venues, events, and furniture catalog.

### Phase 2: Room Geometry
Interactive room builder, accurate dimensions, fixed features, reusable room templates, and geometry validation.

### Phase 3: BEO Intelligence
Document upload, AI extraction, human confirmation, structured requirements, and BEO versioning.

### Phase 4: Layout Generation
Deterministic geometry engine, optimization service, three distinct layout options, scoring, and comparison.

### Phase 5: Floor Plan Editor
Interactive editing, snapping, collision detection, undo/redo, persistence, and PDF export.

### Phase 6: Event Simulation
SimPy simulation service, arrival and service models, congestion analysis, and animated playback.

### Phase 7: AI Optimization
Natural-language editing, layout recommendations, and simulation-informed optimization.

### Phase 8: Advanced Features
Room flips, 3D digital twin, setup verification, and operational learning.

### Phase 9: SaaS Commercialization
Stripe, subscriptions, collaboration, permissions, monitoring, security hardening, and production deployment.

## 22. FIRST EXECUTION INSTRUCTIONS

Begin immediately.

First inspect the repository and determine whether an existing project must be preserved.

If the repository is empty, initialize the project.

Verify the local Flutter, Dart, Python, Docker, and Git environments.

Create the repository structure and foundational documentation.

Then implement Phase 1.

Do not wait for additional instructions unless an essential external credential, destructive action, or product decision requires user approval.

Use reasonable defaults for noncritical choices.

When credentials are unavailable, use local development fixtures and document the configuration required for production.

At the end of each phase:

1. Run relevant tests.
2. Fix failures.
3. Run formatting and static analysis.
4. Verify application startup where the environment supports it.
5. Summarize implemented functionality.
6. List unresolved issues.
7. Commit the milestone if repository permissions allow.
8. Continue to the next phase when feasible.

Do not stop merely because the initial scaffold compiles.

## 23. INITIAL ACCEPTANCE TEST

The first major milestone is a fully working demonstration of this workflow:

1. User signs into EventTwin AI.
2. User creates a venue.
3. User defines a room measuring 80 × 60 feet.
4. User uploads a sample corporate banquet BEO.
5. The system extracts requirements.
6. User reviews and confirms the requirements.
7. The system generates three distinct floor plans.
8. User compares the configurations.
9. User edits a table position.
10. The application validates the change.
11. User saves the updated plan.
12. User exports a dimensioned PDF.

Use clearly labeled sample data for the demonstration.

The room dimensions above are demonstration values only.

The system must not pretend that a physically impossible event setup is feasible.

After this workflow is functioning, proceed to the event simulation engine.

## FINAL DIRECTIVE

You are building a commercial software product, not a proof-of-concept slideshow.

Prioritize:
- Functional completeness
- Accurate geometry
- Operational usefulness
- Reliability
- Clean user experience
- Maintainable architecture
- Security
- Testability

Make architectural decisions that support future growth without overengineering the initial MVP.

Begin implementation now.
