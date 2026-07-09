======================================================================
# HUS COMPILER PROTOCOL: SEMANTIC VALIDATOR
# Version: 3.3
# Status: Official Sovereign Specification
# Execution Mode: DETERMINISTIC | STATELESS | ZERO_ASSUMPTIONS
# ======================================================================

## 1. OPERATIONAL MANDATE

The Semantic Validator is the iron-clad enforcement gate of the HUS Compiler Pipeline. It ingests the Abstract Syntax Tree (AST) produced by `HUS/99_COMPILER_PROTOCOL/01_PARSER.md` and subjects it to an exhaustive, non-negotiable architectural compliance audit. 

Its sole objective is to protect the Hussam platform constitution against any structural decay, premium guesswork, or architectural drift before code generation begins.

---

## 2. SYSTEM BOUNDS & INPUT/OUTPUT

- **Input:** Pure Abstract Syntax Tree (AST) representation of the HUS DSL files.
- **State:** Completely Stateless (`TEMPERATURE = 0`). No caching of past compliance states across sessions.
- **Output:** Verified AST with Semantic Attestation Metadata OR Immediate Pipeline Termination with explicit HUS error codes.

---

## 3. SEMANTIC VALIDATION MATRIX (THE CORE LAWS)

The validator must mechanically iterate over every node in the AST and enforce the following four absolute platform laws:

### 3.1 Law of Absolute Tenant Isolation (tenant_id Rule)
- **Constraint:** Every AST node identified as an `operational entity` or nested within a `bounded_context` MUST contain a declared field `tenant_id` of data type `uuid`.
- **Exception:** Global configuration matrices or core system tables explicitly marked as `SYSTEM_GLOBAL`.
- **Violation Action:** If an entity fails this check, the compiler must halt instantly and throw:
  `[ERROR CODE]: HUS_ERR_VALIDATOR_MISSING_TENANT_ID`
  `[VIOLATION]: Entity missing required tenant_id UUID separation token.`

### 3.2 Law of Value Object Anonymity (Value Object Rule)
- **Constraint:** Any AST node explicitly defined under `ValueObjectDefinition` is strictly FORBIDDEN from containing a field named `id`, `uuid`, `primary_key`, or acting as a standalone unique identifier. Value Objects must represent purely anonymous, immutable values.
- **Violation Action:** Any detection of identity properties within a Value Object triggers immediate termination:
  `[ERROR CODE]: HUS_ERR_VALIDATOR_VALUE_OBJECT_HAS_ID`
  `[VIOLATION]: Value Object contains identity/primary key token violating anonymity rules.`

### 3.3 Law of Absolute Namespace Isolation (Cross-Domain Rule)
- **Constraint:** Direct field-to-field or structural references between entities belonging to different bounded contexts (e.g., `Clinical` calling `Accounting` tables directly) are completely PROHIBITED. Integration must be declared exclusively via `Contracts` or `Domain Events`.
- **Violation Action:** Detection of cross-namespace field leaking triggers:
  `[ERROR CODE]: HUS_ERR_VALIDATOR_NAMESPACE_LEAK`
  `[VIOLATION]: Cross-domain structural violation. Modifying models across boundaries without a Contract or Event declaration.`

### 3.4 Law of Immutable Ledger Strategy (Financial Safety Rule)
- **Constraint:** Any domain context tagged as `Financial` or dealing with core transactional entries MUST enforce double-entry book-keeping rules at the specification level (must possess balanced credit/debit schema definitions and immutable append-only constraints).
- **Violation Action:** Malformed ledger structures trigger:
  `[ERROR CODE]: HUS_ERR_VALIDATOR_INVALID_LEDGER_STRUCTURE`
  `[VIOLATION]: Financial transactions must adhere strictly to double-entry ledger specification format.`

---

## 4. COMPILER FAILURE MODES & ERROR EMISSION

- **Zero-Tolerance Policy:** The validator is not allowed to fix errors, guess intentions, or proceed past a single violation.
- **Output Format:** Upon discovering any violation, the validator must dump a standardized diagnostic log to stderr:

```
# ======================================================================
HUS ARCHITECTURAL COMPILER ERROR
# [ERROR CODE] : <HUS_ERR_VALIDATOR_X>
[FILE PATH]  : <Path to the source specification file>
[AST NODE]   : <Identifier of the offending entity/module>
[VIOLATION]  : <Strict textual explanation of the constitutional breach>
```

---

## 5. PIPELINE SEQUENCING

Upon passing 100% of the validation matrices with zero errors, the Validator appends a `semantic_verified: true` attestation token to the AST metadata block. 

The pipeline transitions mechanically to the next step:
📄 **`HUS/99_COMPILER_PROTOCOL/03_RESOLVER.md`**

Any attempt to bypass this validation layer or modify the pipeline order defaults to an absolute execution block with error code `HUS_ERR_CRITICAL_PIPELINE_BREACH`.

