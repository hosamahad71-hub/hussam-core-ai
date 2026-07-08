# ======================================================================
# HUS DSL STRUCTURAL SCHEMA DEFINITION
# Path: HUS/SPEC_LANGUAGE/01_SCHEMA.md
# Version: 3.3
# Mode: DETERMINISTIC | State: STATELESS
# ======================================================================

meta:
  spec_version: 3.3
  compiler_mode: DETERMINISTIC
  validation_state: STATELESS

# 1. CORE BOUNDED CONTEXT SCHEMA
# ----------------------------------------------------------------------
bounded_context_schema:
  type: object
  properties:
    name: { type: string, required: true }
    namespace: { type: string, required: true, pattern: "^App\\Domains\\[A-Za-z]+$" }
    domain_owner: { type: string, required: true }
    isolation_level: { type: string, enum: [ STRICT, CONTRACT_ONLY ], default: STRICT }
  constraints:
    - rule: HUS_SCHEMA_NAMESPACE_UNIQUE
      enforcement: "The compiler validates that no two bounded contexts share or leak the same PHP/Dart namespace."

# 2. OPERATIONAL ENTITY SCHEMA (TENANT-LOCKED)
# ----------------------------------------------------------------------
entity_schema:
  type: object
  properties:
    id: { type: uuid, primary_key: true, required: true }
    tenant_id: { type: uuid, foreign_key: true, required: true }
    timestamps:
      created_at: { type: timestamp, required: true }
      updated_at: { type: timestamp, required: true }
  constraints:
    - rule: HUS_ERR_SCHEMA_MISSING_TENANT_ID
      enforcement: "If type == OPERATIONAL and tenant_id token is omitted, compilation halts with absolute severity."

# 3. VALUE OBJECT SCHEMA (ANONYMOUS STRUCUTRE)
# ----------------------------------------------------------------------
value_object_schema:
  type: object
  forbidden_properties:
    - id
    - uuid
    - primary_key
    - tenant_id
  constraints:
    - rule: HUS_ERR_SCHEMA_VALUE_OBJECT_HAS_ID
      enforcement: "Any structural definition under ValueObject containing identity key tokens will instantly fail structural verification."

# 4. IMMUTABLE FINANCIAL LEDGER SCHEMA
# ----------------------------------------------------------------------
financial_ledger_schema:
  type: object
  properties:
    entry_id: { type: uuid, primary_key: true, required: true }
    account_id: { type: uuid, required: true }
    debit: { type: decimal, precision: 18, scale: 4, required: true }
    credit: { type: decimal, precision: 18, scale: 4, required: true }
    balance_snapshot: { type: decimal, precision: 18, scale: 4, required: true }
    request_id: { type: uuid, unique: true, required: true }
  constraints:
    - rule: HUS_SCHEMA_LEDGER_IMMUTABILITY
      enforcement: "Database schemas generated from this contract block must drop or reject any UPDATE/DELETE trigger definitions on the backend target."

# 5. IDEMPOTENCY CORE & AI LOGS SCHEMA
# ----------------------------------------------------------------------
idempotency_schema:
  target_table: ai_logs
  properties:
    request_id: { type: uuid, primary_key: true, required: true }
    payload_hash: { type: string, length: 64, required: true }
    execution_status: { type: string, enum: [ PENDING, SUCCESS, FAILED ], required: true }
  database_mechanics:
    insertion: "insertOrIgnore"
    index: "UNIQUE(request_id, payload_hash)"

# ======================================================================
# END OF SCHEMA SPECIFICATION
# Pipeline transitions directly to: HUS/SPEC_LANGUAGE/02_KEYWORDS.md
# ======================================================================

