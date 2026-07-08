# ======================================================================
# HUS CORE CONCEPTS SPECIFICATION
# Version: 3.3
# Status: Official & Binding
# ======================================================================
## 1. SEMANTIC DICTIONARY (القاموس الدلالي الحاكم)
This document establishes the absolute architectural meaning of core concepts within Hussam Core AI. Any generated code (Laravel, Flutter, Go, etc.) that violates these structural models will trigger an immediate compiler block.
---
### A. Domain (النطاق/القطاع الحاد)
* **Definition**: A high-level, independent business capability of the platform (e.g., Identity, Accounting, Clinical, Logistics).
* **Rule**: Every Domain is completely decoupled at the database and code level. Direct cross-domain database joins are strictly prohibited.
### B. Namespace Isolation (عزل مساحات الأسماء)
* **Definition**: The logical and structural boundary encapsulating a single Domain's logic.
* **Code Target (Laravel)**: Isolated under `App\Domains\{DomainName}`.
* **Constraint**: No Controller or Service inside `App\Domains\Clinical` may directly instantiate or call a Model from `App\Domains\Accounting`. Communication must pass exclusively through **Contracts (Interfaces)** or **Domain Events**.
### C. Tenant (المستأجر)
* **Definition**: The organizational or sovereign entity utilizing the system.
* **The Single-Field Tenant Law (tenant_id Rule)**: Every operational table within the system MUST contain a unified column:
    * `tenant_id`: UUID (Foreign Key targeting the global tenants registry).
* **Exception**: Global system configurations or immutable static constants.
### D. Aggregate Root (جذر التجميع)
* **Definition**: A cluster of domain objects (Entities and Value Objects) that can be treated as a single unit for data changes. External objects can only hold references to the Aggregate Root.
* **Rule**: All database transactions and persistence mechanisms operate solely through the Aggregate Root to guarantee transactional consistency boundaries.
### E. Entity (الكيان التشغيلي)
* **Definition**: A domain object defined by its unique identity rather than its attributes.
* **Rule**: Must possess a unique structural identifier (`id` as UUIDv4) and its lifecycle is managed directly by its parent Aggregate Root.
### F. Value Object (كائن القيم المجرد)
* **Definition**: An object that measures, quantifies, or describes a characteristic of the domain, possessing no conceptual identity.
* **The Anonymity Rule (قانون التجريد)**: Value Objects MUST NOT contain any unique identifier field (No `id`, no `uuid`). Equality is determined exclusively by the structural comparison of all its internal attributes combined.
### G. Immutable Financial Ledger Strategy (دفتر القيد المزدوج الصارم)
* **Definition**: The mandatory computational model for financial accounts. 
* **Rule**: Balances are never updated using raw `UPDATE` SQL commands. Every financial transaction is an absolute, permanent, double-entry append-only record (Debit/Credit). Historical rows are structurally immutable.
### H. Idempotency Core & Sync Strategy (نواة المزامنة الذكية)
* **Definition**: The mechanism guaranteeing that local/remote operations can be executed multiple times without changing the final result.
* **Rule**: The `ai_logs` and transaction tables enforce uniqueness using a mandatory `request_id` context. Data entry pipelines must use deterministic operations like `insertOrIgnore` or strict conflict resolution constraints to block duplicates.
---
## 2. ARCHITECTURAL BOUNDARIES MATRIX

| Concept | Multi-Tenant Isolated? | Identity Type | Database Mutability | Communication Mode |
| :--- | :--- | :--- | :--- | :--- |
| **Aggregate Root** | Yes (`tenant_id`) | UUIDv4 | Mutable / Strict Versioning | Contracts / Events |
| **Entity** | Inherited | UUIDv4 | Mutable via Root | Local Context Only |
| **Value Object** | Inherited | **None (Anonymous)** | **Strictly Immutable** | Embedded Value |
| **Ledger Row** | Yes (`tenant_id`) | UUIDv4 | **Strictly Append-Only** | Domain Event Trigger |
