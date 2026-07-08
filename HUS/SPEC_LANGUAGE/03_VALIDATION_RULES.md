spec_version: 3.3
mode: DETERMINISTIC
state: STATELESS

# HUS COMPILER VALIDATION RULES SPECIFICATION

## 1. PURPOSE
This document defines the strict semantic and structural validation rules enforced by the HUS Compiler Validator during Step 05 of the compilation pipeline. Any violation of these rules must cause an immediate compilation halt and emit the corresponding technical error code.

## 2. CORE VALIDATION RULES

### 2.1 Rule 01: Tenant Isolation Validation (قاعدة التحقق من عزل المستأجر الحتمي)
- **Constraint:** The validator must inspect every operational entity and database table defined within any domain context.
- **Requirement:** Each operational structure must explicitly contain a `tenant_id` field defined strictly as type `uuid`.
- **Exception:** Global configuration metadata tables or system-wide immutable static lists.
- **Violation Action:** Halt compilation immediately without generating any artifacts.
- **Error Code:** HUS_ERR_VALIDATION_MISSING_TENANT_ID

### 2.2 Rule 02: Value Object Anonymity Validation (قاعدة التحقق من تجريد كائنات القيم)
- **Constraint:** The validator must analyze all data structures tagged or classified as a `ValueObject`.
- **Requirement:** No `ValueObject` is permitted to possess a distinct identifier field named `id`, or any attribute designated as a primary key or standalone `uuid` acting as a unique key.
- **Violation Action:** Absolute compiler blockage and immediate termination.
- **Error Code:** HUS_ERR_VALIDATION_VALUE_OBJECT_HAS_ID

### 2.3 Rule 03: Namespace Isolation Validation (قاعدة التحقق من عزل مساحات الأسماء)
- **Constraint:** The validator must track all cross-model dependencies and relationship definitions across domains.
- **Requirement:** Direct coupling, model references, or foreign key mapping between entities belonging to different `BoundedContext` boundaries is strictly prohibited. Communication must occur exclusively via `Contracts` or `Domain Events`.
- **Violation Action:** Halt compilation immediately to prevent architectural leakage.
- **Error Code:** HUS_ERR_VALIDATION_NAMESPACE_LEAK

### 2.4 Rule 04: Immutable Financial Ledger Integrity (قاعدة سلامة الدفتر المالي الحتمي)
- **Constraint:** The validator must verify all accounting, ledger, and financial transaction components.
- **Requirement:** Every financial schema must strictly implement double-entry balancing rules (debit and credit integrity) and be explicitly marked as immutable. Modifying or deleting existing entries is blocked; corrections must parse through offsetting ledger entries.
- **Violation Action:** Halt compilation immediately.
- **Error Code:** HUS_ERR_VALIDATION_INVALID_LEDGER_STRUCTURE

### 2.5 Rule 05: Idempotency Core Enforcement (قاعدة حتمية ومقاومة التكرار)
- **Constraint:** The validator must inspect sync contexts, external API mappings, and asynchronous operation logs (`ai_logs`).
- **Requirement:** All synchronization and logging operations must incorporate a mandatory unique `request_id` and utilize idempotent persistence logic leveraging `insertOrIgnore` queries.
- **Violation Action:** Halt compilation immediately.
- **Error Code:** HUS_ERR_VALIDATION_MISSING_IDEMPOTENCY_TOKEN

## 3. VALIDATION PIPELINE TRANSITION
Once all validation rules yield a successful conformance state, the compiler validation layer returns code `HUS_VAL_SUCCESS` and safely hands execution over to `HUS/SPEC_LANGUAGE/04_VERSIONING.md`.

