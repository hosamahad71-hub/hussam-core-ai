======================================================================
# HUS SOVEREIGN SPECIFICATION COMPILER
# Phase 99 — Compiler Protocol: 05_GENERATOR.md
# Version: 3.3
# Status: Mandated
# Execution Mode: DETERMINISTIC | ZERO-ASSUMPTIONS
# ======================================================================

## 1. PURPOSE
This protocol defines the strict architectural laws governing the generation layer of the HUS Compiler. It dictates how the Contract-Injected Abstract Syntax Tree (AST) is mechanically mapped and translated into concrete target source code (Laravel Backend, Flutter Frontend, PostgreSQL DDL) without introducing external drift, implicit assumptions, or structural deviations.

---

## 2. INPUT & BOUNDARY PARAMETERS
- **Absolute Input:** The fully resolved, validated, and contract-injected AST produced exclusively by `04_CONTRACT_INJECTOR.md`.
- **Target Profiles:** Loaded strictly from the target configuration manifest. No default or implicit framework assumptions are permitted.
- **State Preservation:** The generator operates in a completely stateless loop. It is strictly forbidden from optimizing or modifying business logic during translation.

---

## 3. TARGET CODE GENERATION MATRIX LAWS

### 3.1 Backend Target (Laravel Ecosystem)
- **Model Isolation:** Every generated Eloquent Model belonging to an operational domain MUST explicitly incorporate the `tenant_id` UUID field within its `$fillable` array or enforce a global tenant scope.
- **Mass Assignment Guarding:** Code generation MUST explicitly lock models against mass assignment vulnerabilities (`protected $guarded = ['id'];` or strictly defined `$fillable`).
- **Controller Immutability:** Generated controllers (e.g., `TransactionController`) must implement exact request validation classes (`FormRequest`) derived mechanically from the AST Schema. Custom inline modifications by the engine are rejected.

### 3.2 Frontend Target (Flutter Ecosystem)
- **Data Layer Invariance:** Generated Dart data models MUST be strictly immutable (`@immutable` or using final fields).
- **Serialization Safety:** Every model MUST generate deterministic `fromJson` and `toJson` methods. Missing schema fields must trigger immediate compilation failure rather than defaulting to dynamic or nullable types unless explicitly specified.
- **State Management:** BLoC states and events must map 1:1 with the Domain Events and Integration Contracts defined in the AST.

### 3.3 Database DDL Target (PostgreSQL)
- **Tenant Indexing:** Every table generated under an operational domain context MUST feature a composite index combining `tenant_id` and the primary or foreign keys to ensure optimized isolation.
- **Idempotency Logging:** The generator must inject schema structures for tracking `request_id` within the `ai_logs` structure for every data-mutating transaction.

---

## 4. COMPILER-LEVEL GENERATION BLOCKAGE RULES

Any violation of these structural mapping laws will instantly abort the compilation pipeline and throw a fatal generation error block:


```
# ======================================================================
HUS ARCHITECTURAL COMPILER ERROR: GENERATOR BLOCKAGE
[ERROR CODE]  : <HUS_ERR_GENERATOR_X>
[FILE PATH]   : [AST NODE / TARGET PATH]
[VIOLATION]   : <Clear definition of the translation drift>
```

### OFFICIAL GENERATOR ERROR CODES:
- `HUS_ERR_GENERATOR_TENANT_ID_DROPPED`: Triggered if the generator attempts to write a database migration or backend model for an operational context without emitting the mandatory `tenant_id: uuid` field.
- `HUS_ERR_GENERATOR_VALUE_OBJECT_MUTABILITY`: Triggered if the generator emits code that allows a Value Object to expose a unique identification key (`id`) or mutate its internal state after instantiation.
- `HUS_ERR_GENERATOR_UNAUTHORIZED_FRAMEWORK_DRIFT`: Triggered if the engine injects arbitrary framework-specific design patterns, external library helpers, or structural assumptions not defined in the source HUS specifications.

---

## 5. PIPELINE SEQUENCING

The output of this generator consists of the verified, uncompiled source code artifacts written directly to the target environment directories. Upon completion of file emission, the compiler pipeline advances mechanically and unconditionally to the loading of execution manifests in **HUS/99_COMPILER_PROTOCOL/06_INPUT_MANIFEST.md**.
