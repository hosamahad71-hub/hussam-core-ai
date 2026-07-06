# HUS PLATFORM CONSTITUTION
# ======================================================================
# Sovereign Engineering Constitution for Hussam Core AI (Amazon Yemen)
# Version: 3.3
# Status: ABSOLUTE MANDATORY CONSTRAINT
# ======================================================================

## ARTICLE 01: SINGLE SOURCE OF TRUTH (SSOT)
1. Everything defined under the `HUS/` directory constitutes the absolute technical and architectural truth of the platform.
2. If any instruction, framework opinion, or AI suggestion contradicts the HUS specification, HUS wins unconditionally.
3. This supremacy applies across all target stacks: Laravel (Backend), PostgreSQL (Database), and Flutter (Frontend).

## ARTICLE 02: BOUNDED CONTEXT & NAMESPACE ISOLATION
1. Every domain context (including Identity, Accounting, Clinical, and Logistics) must possess a strictly isolated Namespace in the backend.
2. Direct cross-domain model invocations are completely prohibited.
3. Interaction between separate bounded contexts must occur exclusively through approved integration Contracts or Domain Events.

## ARTICLE 03: TENANT ISOLATION CORE
1. Every database table created within operational contexts must strictly implement a `tenant_id` field of type `UUID`.
2. The `tenant_id` must explicitly reference the master tenants table to enforce total data isolation between clients.
3. This rule applies globally, with the sole exception of system-wide configuration tables or static cosmic configurations.

## ARTICLE 04: ZERO-GUESSWORK & DETERMINISTIC WORKFLOW
1. Code generation engines and AI compilers are explicitly barred from guessing database schemas, table fields, migrations, or application logic.
2. All executable artifacts must be derived literally and deterministically from the canonical database specifications.
3. Development must follow a strict "Backend-First" sequence, requiring backend controllers, schemas, and validation structures to be finalized before generating Dart repositories or Flutter user interfaces.

## ARTICLE 05: VALUE OBJECT ANONYMITY
1. Value Objects defined within the specification language are prohibited from containing any unique identifier field (`id`).
2. Value Objects must remain structurally anonymous and be identified solely by their constituent values.

## ARTICLE 06: IMMUTABLE FINANCIAL LEDGER & IDEMPOTENCY
1. All financial and ledger transactions must be processed via an unalterable, double-entry financial ledger strategy to safeguard account balances against tampering.
2. Technical and financial operation logs (`ai_logs`) must ensure strict idempotency using a unique `request_id` coupled with `insertOrIgnore` database queries to prevent record duplication.

## ARTICLE 07: SPECIFICATION VERSIONING
1. The official specification language version is strictly locked at `spec_version: 3.3`.
2. If the compiler encounters an evaluation manifest indicating a lower version or omitting the version header entirely, execution must instantly halt with an `ARCHITECTURAL_COMPILATION_ERROR`.
