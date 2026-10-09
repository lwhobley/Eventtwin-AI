# EventTwin AI development conventions

## Coding discipline

- State assumptions before implementation and surface unclear requirements early.
- Use the smallest solution that fulfills the current milestone; avoid speculative features and abstractions.
- Change only files needed for the task, preserve existing style, and remove only orphans created by the change.
- Define verifiable success criteria, run the relevant checks, and fix failures before calling a milestone complete.

## Product rules

- Keep this product standalone. Do not import Venue Wrangler code or services.
- Use meters for stored geometry and calculations. Convert at the UI boundary for feet.
- Treat uploaded room drawings as unscaled until a user verifies measurements.
- Distinguish confirmed requirements from inferred or sample data. Never fill missing BEO facts silently.
- Reject infeasible geometry; never show an invalid layout as approved.
- Keep deterministic geometry checks separate from AI interpretation.
- The current local demo stores data only on the device. Do not represent it as authenticated or tenant isolated.
- Before production data is enabled, add Supabase RLS, authorization tests, private document storage, and server-side validation.
- Label simulation results as estimates and state their assumptions.
- Change only files needed for the current milestone; run formatting, tests, and analysis.
