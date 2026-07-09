======================================================================
# HUS SOVEREIGN SPECIFICATION COMPILER
# PHASE 99 — COMPILER PROTOCOL: REFERENCE & DEPENDENCY RESOLVER
# Version: 3.3 | Status: MANDATORY | Mode: DETERMINISTIC
# ======================================================================

## 1. SYSTEM IDENTITY & PURPOSE
The HUS Resolver is the stateless execution layer responsible for traversing the validated Abstract Syntax Tree (AST) to resolve all symbolic references, verify dependency directions, and enforce explicit architectural boundaries between Bounded Contexts. It guarantees that no implicit or hidden dependencies exist between decoupled domain modules.

---

## 2. RESOLUTION RULES & CONSTRAINTS

### 2.1 Namespace & Dependency Resolution
- The Resolver MUST scan all domain definitions to map their absolute namespaces (`App\Domains\<DomainName>`).
- Cross-domain model references are STRICTLY PROHIBITED from resolving directly. 
- If Domain `A` requires data or behavior from Domain `B`, the Resolver MUST only resolve this relationship if it is defined through an explicit Integration Contract (`App\Contracts\<Context>`) or a Domain Event (`App\Events\<EventName>`).

### 2.2 Tenant Scope Resolution
- Every resolved query, relational mapping, or context execution path MUST explicitly bind to the resolved `tenant_id: uuid` context scope.
- Global tables or systemic metadata are the only entities exempted from tenant resolution. Any operational entity resolved without a deterministic tenant scope verification step will instantly trigger a compilation failure.

### 2.3 Value Object Anonymity Rule
- During property resolution, the Resolver MUST audit all structures marked as `ValueObject`.
- The Resolver MUST verify that no field within the `ValueObject` structure resolves to a primary key (`id`, `uuid`, or `auto_incrementing_int`). Value Objects must remain structurally anonymous and completely defined by their structural attributes alone.

---

## 3. COMPILER-LEVEL ENFORCEMENT LAWS & ERRORS

If the Resolver encounters any violation of the architectural constraints during reference traversal, it MUST abort the compilation process immediately and output the standard architectural error format:


```
# ======================================================================
HUS ARCHITECTURAL COMPILER ERROR: RESOLVER BLOCKAGE
# [ERROR CODE]  : <HUS_ERR_RESOLVER_X>
[FILE PATH]   : <Path to the offending HUS specification file>
[AST NODE]    : <Identifier of the offending Domain/Entity/Reference>
[VIOLATION]   : <Detailed mechanical explanation of the boundary leak>
```

### Absolute Error Matrix:
1. `HUS_ERR_RESOLVER_UNRESOLVED_REFERENCE`: Triggered when an entity references a type, property, contract, or event that does not exist within the parsed input space.
2. `HUS_ERR_RESOLVER_ILLEGAL_DIRECT_COUPLING`: Triggered when a direct model-to-model reference is identified across different domain namespaces instead of utilizing a Contract or Domain Event.
3. `HUS_ERR_RESOLVER_TENANT_CONTEXT_LEAK`: Triggered when an operational reference resolution path bypasses the mandatory `tenant_id` scope alignment.
4. `HUS_ERR_RESOLVER_VALUE_OBJECT_IDENTIFIER_FOUND`: Triggered when an identity field or key resolves inside a structure explicitly declared as a Value Object.

---

## 4. PIPELINE SEQUENCING

The output of this Resolver is a fully linked and validated reference graph. The compiler transitions mechanically to the contract injection layer:
`HUS/99_COMPILER_PROTOCOL/04_CONTRACT_INJECTOR.md`. Any mutation or bypassing of this resolution phase violates the HUS platform constitution.

```
