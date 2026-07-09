# ======================================================================
# HUS CENTRAL COMPILER ERROR REGISTRY & UNIFIED REPORTING PROTOCOL
# Version: 3.3
# Status: Official Architectural Instruction
# ======================================================================

## 1. PURPOSE
This specification defines the ultimate central registry for all compilation, syntax, and architectural errors across the HUS Sovereign Specification Pipeline. It standardizes the terminal output format, guarantees absolute structural block stability, and maps every permitted error code to ensure that no non-deterministic execution or AI-driven guesswork occurs during compilation failures.

---

## 2. UNIFIED ERROR OUTPUT SCHEMA
Every layer of the compiler, from grammar parsing to target artifact generation, MUST utilize this exact block format when throwing a fatal stoppage. No character, padding, or spacing variation is allowed.

================ central error output block start ================
======================================================================
HUS ARCHITECTURAL COMPILER ERROR: CENTRAL PIPELINE HALT

[ERROR CODE]      : <CENTRAL_REGISTERED_CODE>
[PIPELINE STAGE]  : <STEP_01_TO_STEP_09>
[FILE PATH]       : <Path to the offending specification file>
[AST NODE/ENTITY] : <Identifier of the offending Domain/Entity/Aggregate/ValueObject/Contract>
[VIOLATION DETAIL]: <Human-readable rigid technical reason for the constitutional breach>
======================================================================
================= central error output block end =================

---

## 3. MASTER ERROR CODE REGISTRY

### 3.1 Phase 01 — Foundation & Boot Errors
* **`HUS_ERR_BOOT_CONSTITUTION_MISSING`**
  - *Trigger Condition*: The critical single source of truth `HUS/00_PLATFORM_CONSTITUTION.md` cannot be located or loaded at STEP 01.
  - *Pipeline Action*: Absolute execution abort.
* **`HUS_ERR_BOOT_INDEX_MALFORMED`**
  - *Trigger Condition*: The structural configuration or loading sequence defined in `HUS/INDEX.md` is altered, corrupted, or missing metadata.

### 3.2 Phase 02 — Language & Grammar Errors
* **`HUS_ERR_GRAMMAR_MISSING_TENANT_ID`**
  - *Trigger Condition*: An operational entity tagged or nested within an active operational bounded context lacks the mandatory `tenant_id: uuid` token constraint.
* **`HUS_ERR_GRAMMAR_VALUE_OBJECT_HAS_ID`**
  - *Trigger Condition*: A Value Object definition breaks anonymity laws by including an explicit identifier (`id`, `uuid`, or `primary_key`).
* **`HUS_ERR_GRAMMAR_NAMESPACE_LEAK`**
  - *Trigger Condition*: Direct field references or coupling attempted across unlinked domain structures without explicit contract or event boundaries.

### 3.3 Phase 99 — Compiler Pipeline Stage Errors
* **`HUS_ERR_PARSER_AST_MALFORMED`**
  - *Trigger Condition*: Syntax architecture or formatting rules deviate from `01_SCHEMA.md` during parsing.
* **`HUS_ERR_VALIDATOR_CONSTITUTION_BREACH`**
  - *Trigger Condition*: Parsed AST nodes directly contradict structural rules or foundational guardrails established by the platform constitution.
* **`HUS_ERR_RESOLVER_UNRESOLVED_REFERENCE`**
  - *Trigger Condition*: Broken entity references, missing domains, or invalid cross-domain dependencies discovered during link evaluation.
* **`HUS_ERR_INJECTOR_DIRECT_CROSS_DOMAIN_LEAK`**
  - *Trigger Condition*: An entity attempts to directly couple with external domain models instead of utilizing an isolated interface contract layer.
* **`HUS_ERR_INJECTOR_CONTRACT_VIOLATES_ANONYMITY`**
  - *Trigger Condition*: A Value Object passed via a cross-boundary contract interface exposes an explicit unique primary identifier.
* **`HUS_ERR_INJECTOR_MISSING_TENANT_PROPAGATION`**
  - *Trigger Condition*: A contract method signature drops or omits the context propagation rule for `tenant_id`.
* **`HUS_ERR_MANIFEST_MALFORMED_SYNTAX`**
  - *Trigger Condition*: JSON/YAML structural parsing failure within `HUS/99_COMPILER_PROTOCOL/06_INPUT_MANIFEST.md`.
* **`HUS_ERR_MANIFEST_VERSION_MISMATCH`**
  - *Trigger Condition*: The target manifest specification version deviates from the compiler runtime version (3.3).
* **`HUS_ERR_MANIFEST_MISSING_TENANT_CONTEXT`**
  - *Trigger Condition*: Foundational tenant context UUID token is omitted or invalid inside the processing manifest.
* **`HUS_ERR_MANIFEST_UNSUPPORTED_TARGET`**
  - *Trigger Condition*: Code generation target requested is unmapped or lacks a valid architecture configuration.

---

## 4. COMPILER TERMINATION LAWS

### 4.1 Zero-Warning Enforcement Law
Warnings do not exist in the HUS compiler runtime environment. Any constraint anomaly, metadata gap, or technical variance MUST be upgraded to an absolute fatal error code and cause an instantaneous halt.

### 4.2 Terminal Hard Abort Law
Upon identifying any registered error code from Section 3, the engine MUST print the Unified Error Block to `stderr` and immediately terminate the process with **`Exit Code 1`**. 

### 4.3 No-Guesswork Anti-Recovery Law
The compiler is strictly forbidden from attempting auto-linting corrections, placeholder generation, or fallback assumptions. Non-compliant specification trees must result in mechanical blockages.

