======================================================================
# HUS INPUT MANIFEST PROTOCOL
# Hussam Sovereign Specification Compiler - Input Manifest Engine
# Version: 3.3
# Status: Official
======================================================================

## 1. PURPOSE
This document governs the structural schema, validation constraints, and execution-time requirements for the HUS Compilation Input Manifest. The Input Manifest is the deterministic entry point configuration that dictates to the HUS Sovereign Compiler which domain specifications to ingest, which generation target pipelines to activate, and the exact multi-tenant isolation contexts to embed.

---

## 2. MANIFEST SPECIFICATION SCHEMA (JSON/YAML STRUCTURE)
Every HUS compiler execution must be initiated with an `input_manifest` file conforming strictly to the following schema definition:

```json
{
  "manifest_version": "3.3",
  "execution_context": {
    "environment": "production | staging | local",
    "tenant_id": "UUID_V4_STRING",
    "namespace_root": "App\\Domains"
  },
  "compilation_units": {
    "root_path": "HUS/DOMAIN_MODEL/",
    "active_contexts": [
      "Identity",
      "Accounting",
      "Logistics",
      "Clinical"
    ]
  },
  "generation_targets": [
    {
      "target_name": "laravel",
      "output_path": "backend/app/Domains/",
      "options": {
        "auth_middleware": "auth:sanctum",
        "strict_types": true
      }
    },
    {
      "target_name": "flutter",
      "output_path": "frontend/lib/domains/",
      "options": {
        "state_management": "bloc",
        "null_safety": true
      }
    }
  ]
}

```
## 3. COMPILER-LEVEL VALIDATION LAWS
### 3.1 Version Match Enforcement Law
 * The compiler MUST parse the manifest_version token first.
 * If manifest_version does not identically match the compiler runtime engine version (currently 3.3), compilation must halt instantly with error HUS_ERR_MANIFEST_VERSION_MISMATCH.
### 3.2 Tenant Isolation Context Injection Law
 * The manifest MUST explicitly declare a valid tenant_id formatted as a UUID v4.
 * This token acts as the operational root context. The compiler will mechanically inject this tenant_id constraint into all downstream generation pipelines (SQL Migrations, Eloquent Global Scopes, Flutter Request Interceptors).
 * Failure to provide a valid UUID v4 triggers an immutable abort: HUS_ERR_MANIFEST_MISSING_TENANT_CONTEXT.
### 3.3 Target Verification Law
 * Every activated block inside generation_targets must correspond to an official HUS compiler generator module found under HUS/99_COMPILER_PROTOCOL/05_GENERATOR.md.
 * Unrecognized target names (e.g., guessing unauthorized frameworks) trigger: HUS_ERR_MANIFEST_UNSUPPORTED_TARGET.
## 4. PIPELINE SEQUENCING & TRANSITION
 1. **Input Source**: The manifest is loaded during **STEP 06** of the absolute compilation execution pipeline, immediately after the Abstract Syntax Tree (AST) has passed complete semantic validation via HUS/99_COMPILER_PROTOCOL/02_VALIDATOR.md.
 2. **Execution Bind**: The parsed context from this manifest is tightly bound to the AST, modifying the compiler's internal state machine for target-specific generation.
 3. **Pipeline Advance**: Once validated, the compiler advances mechanically and unconditionally to the Contract Injection Layer governed by HUS/99_COMPILER_PROTOCOL/04_CONTRACT_INJECTOR.md.
## 5. OFFICIAL COMPILER ERROR CODES
Every violation of the Input Manifest protocol must halt the pipeline completely and print the following unchangeable block format:
# ======================================================================
HUS ARCHITECTURAL COMPILER ERROR: MANIFEST BREAKAGE
# [ERROR CODE]  : <HUS_ERR_MANIFEST_X>
[FILE PATH]   : HUS/99_COMPILER_PROTOCOL/06_INPUT_MANIFEST.md
[VIOLATION]   : <Detailed message describing the structural or contextual breach>
### ERROR REGISTRY:
 * HUS_ERR_MANIFEST_MALFORMED_SYNTAX: Triggered if the file fails structural JSON/YAML parsing.
 * HUS_ERR_MANIFEST_VERSION_MISMATCH: Triggered if the manifest version deviates from specification version 3.3.
 * HUS_ERR_MANIFEST_MISSING_TENANT_CONTEXT: Triggered if the foundational tenant_id UUID token is omitted or invalid.
 * HUS_ERR_MANIFEST_UNSUPPORTED_TARGET: Triggered if an unmapped code generation target is declared.
