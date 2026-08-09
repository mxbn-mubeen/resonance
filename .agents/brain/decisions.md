# Decisions

- Decision: Enforce Dart 3.3.0 environment compatibility
- Reason: User explicitly requested avoiding syntax from newer Dart versions (like `.firstOrNull`) as their environment setup prevents upgrading.
- Alternatives considered: Updating SDK constraint to allow newer features, but rejected due to environment constraints.
- Affected modules: Entire codebase
- Date: 2026-08-09
