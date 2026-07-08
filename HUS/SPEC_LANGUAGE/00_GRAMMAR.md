
```markdown
# ======================================================================
# HUS SPECIFICATION LANGUAGE GRAMMAR
# Hussam Unified Specification (HUS DSL)
# Version: 3.3
# Status: Official & Core Enforced
# ======================================================================

## 1. LEXICAL TOKENS
T_SPEC_VERSION     ::= "spec_version:" [0-9]+ "." [0-9]+
T_DOMAIN           ::= "domain"
T_CONTEXT          ::= "bounded_context"
T_AGGREGATE        ::= "aggregate"
T_ENTITY           ::= "entity"
T_VALUE_OBJECT     ::= "value_object"
T_CONTRACT         ::= "contract"
T_EVENT            ::= "domain_event"
T_IDENTIFIER       ::= [a-zA-M_][a-zA-Z0-9_]*
T_UUID             ::= "uuid"
T_TYPE             ::= "string" | "integer" | "decimal" | "boolean" | "timestamp" | T_UUID

---

## 2. ROOT PRODUCTION RULES
HUS_Specification ::= Header DefinitionList

Header            ::= T_SPEC_VERSION LayerConstraints
LayerConstraints  ::= "mode: DETERMINISTIC" "state: STATELESS"

DefinitionList    ::= Definition | Definition DefinitionList
Definition        ::= DomainDefinition 
                    | ContextDefinition 
                    | AggregateDefinition 
                    | EntityDefinition 
                    | ValueObjectDefinition

---

## 3. SYNTAX & STRUCTURAL DEFINITIONS

### 3.1 Header Verification Syntax
Every specification file MUST start with the exact version string matching the compiler state.

```
spec_version: 3.3
mode: DETERMINISTIC
state: STATELESS
```

### 3.2 Domain & Bounded Context Definition
```ebnf
DomainDefinition  ::= T_DOMAIN T_IDENTIFIER "{" ContextList "}"
ContextList       ::= ContextDefinition | ContextDefinition ContextList
ContextDefinition ::= T_CONTEXT T_IDENTIFIER "{" BlockContent "}"

```
### 3.3 Aggregate & Entity Definition
```ebnf
AggregateDefinition ::= T_AGGREGATE T_IDENTIFIER "{" EntityList "}"
EntityList          ::= EntityDefinition | EntityDefinition EntityList
EntityDefinition    ::= T_ENTITY T_IDENTIFIER "{" FieldList "}"
FieldList           ::= Field | Field FieldList
Field               ::= T_IDENTIFIER ":" T_TYPE

```
### 3.4 Value Object Definition
```ebnf
ValueObjectDefinition ::= T_VALUE_OBJECT T_IDENTIFIER "{" VOFieldList "}"
VOFieldList           ::= VOField | VOField VOFieldList
VOField               ::= T_IDENTIFIER ":" T_TYPE

```
## 4. COMPILER-LEVEL ARCHITECTURAL ENFORCEMENT LAWS
### 4.1 Tenant Isolation Grammar Constraint (قانون حقل المستأجر الحتمي)
 * Every entity tagged or nested within an operational bounded_context must implicitly or explicitly parse the tenant_id: uuid token.
 * If the compiler identifies an operational entity lacking this identifier, it must halt parsing immediately with error code:
   HUS_ERR_GRAMMAR_MISSING_TENANT_ID
### 4.2 Value Object Anonymity Grammar Constraint (حظر المعرف الفريد في كائنات القيم)
 * The production rule for ValueObjectDefinition strictly forbids the use of token id or any field type defined as primary_key or uuid acting as a standalone unique identifier.
 * Any violation triggers an absolute compiler blockage:
   HUS_ERR_GRAMMAR_VALUE_OBJECT_HAS_ID
### 4.3 Namespace Isolation Grammar Constraint (قواعد عزل مساحات الأسماء)
 * The grammar prohibits direct field references between models belonging to different domain structures.
 * Cross-domain relationships must only parse through contract or event identifiers.
## 5. COMPILATION PIPELINE NEXT STEP
Once this grammar file is loaded and validated, the compiler pipeline transitions to HUS/SPEC_LANGUAGE/01_SCHEMA.md to map the structural syntax rules.
```

---
احفظ الملف الآن، وأنا في انتظار كلمتك لصبّ الملف التالي مباشرة `HUS/SPEC_LANGUAGE/01_SCHEMA.md`.

```

