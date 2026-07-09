======================================================================
# HUS COMPILER PROTOCOL: CONTRACT INJECTOR SPECIFICATION
# Version: 3.3
# Execution Mode: DETERMINISTIC | State: STATELESS
# ======================================================================

## 1. PROTOCOL OVERVIEW
The Contract Injector is the execution layer responsible for enforcing the "Namespace Isolation Rule" and transforming cross-domain syntax references into decoupled, formal structural contracts (Interfaces) or asynchronous Domain Events. It operates directly upon the resolved Abstract Syntax Tree (AST) received from 03_RESOLVER.md and prepares it for the compilation target generator (05_GENERATOR.md).

Direct coupling between different bounded contexts is structurally prohibited. All cross-context communications must be intercepted and wrapped inside a strictly typed contract or emitted via a distributed event schema.

---

## 2. CORE INJECTION COMMANDS & LAWS

### 2.1 Namespace Isolation & Interception Law
- **Mechanism**: The compiler must scan the AST for any relational field or action invocation where Source_Domain != Target_Domain.
- **Enforcement**: Direct model instantiation or direct database foreign key associations across different namespaces (e.g., Clinical querying Accounting models directly) are completely blocked.
- **Transformation**: The Injector automatically rewrites the interaction block into a standardized Contract representation or an event subscriber schema.

### 2.2 Value Object Anonymity Rule Enforcement
- **Mechanism**: When a contract passes data structures across domains, any Value Object embedded within the contract payload must be strictly anonymous.
- **Enforcement**: The Injector validates that no unique identifiers (id, uuid, primary_key) are present within the data payload transferred by the contract. Any entity being passed must be explicitly transformed into a read-only Data Transfer Object (DTO) or a Value Object matching this constraint.

### 2.3 Tenant Context Propagation Law
- **Mechanism**: Every cross-domain contract interface call must explicitly or implicitly map and forward the tenant_id context.
- **Enforcement**: Cross-domain calls cannot drop or obfuscate the active tenant_id. The Injector injects the tenant_id: uuid tracking parameter automatically into all generated backend contract method signatures and event headers to guarantee 100% tenant isolation at runtime.

---

## 3. AST INTERCEPTION AND REWRITE RULES
When the Injector processes a cross-domain declaration node, it must apply the following structural mutation rules to the intermediate AST representation:

```json
{
  "node_type": "CrossDomainReference",
  "source_namespace": "App\\Domains\\Clinical",
  "target_namespace": "App\\Domains\\Accounting",
  "action": "FetchLedgerBalance",
  "injection_strategy": "ContractInterface",
  "enforced_contract": "App\\Contracts\\Accounting\\LedgerQueryContractInterface",
  "tenant_forwarding": "REQUIRED"
}

```
## 4. PIPELINE SEQUENCING
 1. **Input Source**: Resolved and syntactically secure AST from HUS/99_COMPILER_PROTOCOL/03_RESOLVER.md.
 2. **Internal Processing**: Identification of cross-boundary links -> Isolation checks -> Injection of abstract interfaces and events schemas into the AST model.
 3. **Output Destination**: Contract-Injected AST model.
 4. **Pipeline Transition**: The compiler pipeline advances mechanically and unconditionally to HUS/99_COMPILER_PROTOCOL/05_GENERATOR.md. Any mutation of the pipeline order results in a fatal compilation failure.
## 5. COMPILER ERROR HANDLING & BLOCKAGE SCHEMAS
Any violation of the contract injection guidelines will completely abort the pipeline execution and throw an immutable compiler error block.
# ======================================================================
HUS ARCHITECTURAL COMPILER ERROR: CONTRACT INJECTION BREAKAGE
# [ERROR CODE]  : <HUS_ERR_INJECTOR_X>
[FILE PATH]   : [AST NODE]    : <Identifier of the offending Cross-Domain Node / Payload>
[VIOLATION]   : <Detailed description of the architectural boundary breach>
### OFFICIAL ERROR CODES:
 * HUS_ERR_INJECTOR_DIRECT_CROSS_DOMAIN_LEAK: Triggered if an entity attempts to couple with an external domain model directly without an isolated contract layer.
 * HUS_ERR_INJECTOR_CONTRACT_VIOLATES_ANONYMITY: Triggered if a Value Object passed through a contract interface contains an explicit unique identifier (id).
 * HUS_ERR_INJECTOR_MISSING_TENANT_PROPAGATION: Triggered if a contract method signature drops or fails to secure the mandatory tenant_id context propagation rule.
