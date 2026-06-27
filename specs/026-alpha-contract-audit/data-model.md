# Data Model: Alpha Contract and State Audit

## AlphaGate

- `gate_id`: stable identifier, e.g. `ALPHA-ENDGAME-KAMI`
- `description`: measurable condition
- `owner_spec`: numbered spec path
- `priority`: roadmap order
- `status`: `Not Started`, `In Progress`, `Blocked`, `Verified`
- `evidence`: links to tests, command output, manual notes, or files

## AuditFinding

- `finding_id`: stable audit row id
- `gate_id`: related AlphaGate
- `result`: `Proven`, `Incomplete`, `Contradicted`, `Unverified`
- `notes`: concise explanation
- `next_action`: task or owning spec

## SpecTrackerRow

- `priority`: integer order
- `roadmap_phase`: phase label
- `spec_path`: path under `specs/`
- `spec_status`: status of Speckit artifacts
- `alpha_status`: implementation status for the alpha gate
- `exit_gate`: short completion statement
