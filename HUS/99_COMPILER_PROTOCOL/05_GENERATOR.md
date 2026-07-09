======================================================================
# HUS CODE GENERATION PROTOCOL
# Phase 99 — Compiler Protocol / STEP 05
# Version: 3.3 | Status: IMMUTABLE
# ======================================================================

## 1. PURPOSE & MANDATE
This protocol governs the deterministic translation of the Contract-Injected Abstract Syntax Tree (AST) into concrete, target-specific executable source code (Laravel Backend & Flutter Frontend). The generation layer is strictly a "dumb mapper"—it is forbidden from introducing logic, optimizations, or structural variations not explicitly authorized by the verified AST.

---

## 2. INPUT & OUTPUT SPECIFICATION
* **Absolute Input:** Contract-Injected AST verified by `HUS/99_COMPILER_PROTOCOL/04_CONTRACT_INJECTOR.md`.
* **Primary Output:** Target Artifact Bundles (SQL Migrations, Laravel Controllers/Models, Flutter BLoC/Repositories).

---

## 3. TARGET-SPECIFIC GENERATION LAWS

### 3.1 Backend Generation Rules (Laravel & PostgreSQL)
1. **Tenant Enforcement:** Every operational table migration generated MUST include the column `tenant_id UUID NOT NULL` linked via foreign key to the global tenants system, backed by a composite index `PRIMARY KEY (id, tenant_id)`.
2. **Namespace Segregation:** Code files must be partitioned into strict domain paths:
   * `App\Domains\<DomainName>\Models\`
   * `App\Domains\<DomainName>\Http\Controllers\`
3. **Idempotency Integration:** Financial and transactional endpoints must automatically embed a request-deduplication check against `ai_logs` via the incoming `request_id` header using `insertOrIgnore`.

### 3.2 Frontend Generation Rules (Flutter & Dart)
1. **Value Object Immutability:** Generated Value Objects must utilize `@immutable` annotations and lack any standalone internal `id` field.
2. **BLoC State Rigidity:** States generated for feature components must explicitly subclass a sealed base state structure to prevent unexpected application state drift.

---

## 4. PIPELINE SEQUENCING & TRANSITION
1. **Execution Block:** The code generation layer fires unconditionally after contract injection confirmation.
2. **Next Sequence:** Upon successful writing of all target streams without validation leakage, the compiler engine transitions mechanically to **HUS/99_COMPILER_PROTOCOL/06_INPUT_MANIFEST.md**.

---

## 5. GENERATOR-LEVEL ERROR BLOCKAGE SCHEMAS
Any structural deviation or compliance leakage during the code emit process will instantly drop a fatal compilation blockage.


```
# ======================================================================
HUS ARCHITECTURAL COMPILER ERROR: GENERATION COLLAPSE
[ERROR CODE]  : <HUS_ERR_GENERATOR_X>
[FILE PATH]   : [Target Artifact Stream Context]
[AST NODE]    : <The offending Domain/Model/Entity Component>
[VIOLATION]   : <Explanation of generation divergence or constraint breach>
```

### OFFICIAL COMPILER GENERATOR ERROR CODES:
* `HUS_ERR_GENERATOR_CREATIVE_DRIFT`: Triggered if the generator attempts to emit fields, methods, or logic frames not specified in the input AST.
* `HUS_ERR_GENERATOR_TENANT_STRIP`: Fatal blockage triggered if a generated operational database migration drops the mandatory `tenant_id` structural rule.
* `HUS_ERR_GENERATOR_TARGET_MISMATCH`: Triggered if the selected target mapping strategy fails to comply with the structural boundaries of the language specs.
