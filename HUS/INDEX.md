# ======================================================================
# HUS INDEX
# Hussam Unified Specification (HUS DSL)
# Version: 3.3
# Status: Official
# ======================================================================

## PURPOSE

This file defines the official loading order of the HUS specification.

Every compiler, AI agent, parser, validator, generator, reviewer, or engineering tool MUST follow this order before performing any analysis or generation.

Changing the loading order is considered an architectural breaking change.

---

# PHASE 01 — FOUNDATION

1.
HUS/00_PLATFORM_CONSTITUTION.md

Purpose:

Defines the constitutional laws governing the entire platform.

Output:

Architectural constraints.

---

2.
HUS/01_CORE_CONCEPTS.md

Purpose:

Defines the official semantic meaning of every HUS concept.

Output:

Semantic Dictionary.

---

# PHASE 02 — LANGUAGE

3.
HUS/SPEC_LANGUAGE/00_GRAMMAR.md

Purpose:

Defines HUS grammar.

Output:

Grammar Rules.

---

4.
HUS/SPEC_LANGUAGE/01_SCHEMA.md

Purpose:

Defines structural syntax.

Output:

Schema Rules.

---

5.
HUS/SPEC_LANGUAGE/02_KEYWORDS.md

Purpose:

Defines reserved keywords.

Output:

Language Vocabulary.

---

6.
HUS/SPEC_LANGUAGE/03_VALIDATION_RULES.md

Purpose:

Defines compile-time validation.

Output:

Validation Rules.

---

7.
HUS/SPEC_LANGUAGE/04_VERSIONING.md

Purpose:

Defines specification compatibility.

Output:

Version Compatibility.

---

# PHASE 03 — COMPILER

8.
HUS/COMPILER_PROTOCOL/00_BOOT.md

Purpose:

Compiler startup sequence.

---

9.
HUS/COMPILER_PROTOCOL/01_LEXER.md

Purpose:

Lexical analysis.

---

10.
HUS/COMPILER_PROTOCOL/02_PARSER.md

Purpose:

Syntax parsing.

---

11.
HUS/COMPILER_PROTOCOL/03_AST.md

Purpose:

Abstract Syntax Tree construction.

---

12.
HUS/COMPILER_PROTOCOL/04_VALIDATOR.md

Purpose:

Semantic validation.

---

13.
HUS/COMPILER_PROTOCOL/05_RESOLVER.md

Purpose:

Reference resolution.

---

14.
HUS/COMPILER_PROTOCOL/06_CONTRACT_INJECTOR.md

Purpose:

Automatic contract injection.

---

15.
HUS/COMPILER_PROTOCOL/07_GENERATOR.md

Purpose:

Artifact generation.

---

16.
HUS/COMPILER_PROTOCOL/08_ERRORS.md

Purpose:

Compiler diagnostics.

---

17.
HUS/COMPILER_PROTOCOL/09_STOP_CONDITIONS.md

Purpose:

Mandatory halt conditions.

---

18.
HUS/COMPILER_PROTOCOL/10_INPUT_MANIFEST.md

Purpose:

Compilation manifest.

---

# PHASE 04 — TARGETS

19.

HUS/TARGETS/

Purpose:

Defines supported target technologies.

Examples:

Laravel

Flutter

Go

Rust

.NET

Spring

NestJS

React

Vue

---

# PHASE 05 — GENERATORS

20.

HUS/GENERATORS/

Purpose:

Contains implementation-specific generators.

Generators MUST NOT modify HUS specifications.

Generators MUST consume HUS specifications.

---

# PHASE 06 — AI SUPPORT

21.

HUS/AI_CONTEXT.md

Purpose:

Repository boot context.

---

22.

HUS/AI_CAPABILITIES.md

Purpose:

AI operational contract.

---

23.

HUS/COMPILER_CONFORMANCE.md

Purpose:

Compiler compliance verification.

---

## EXECUTION LAW

Every implementation MUST follow this loading order exactly.

Skipping any phase is prohibited.

Changing any phase order requires a major specification version.

END OF INDEX
