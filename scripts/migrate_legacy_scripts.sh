#!/usr/bin/env bash
set -euo pipefail

mkdir -p scripts/legacy
mv assemble_hussam_core.sh scripts/legacy/ || true
mv deep_system_audit.sh scripts/legacy/ || true
mv preflight.sh scripts/legacy/ || true
mv run.sh scripts/legacy/ || true
mv sovereign_probe.sh scripts/legacy/ || true
mv stress_test.js scripts/legacy/ || true
mv stress_test_saturation.js scripts/legacy/ || true
mv fault_injection_test.js scripts/legacy/ || true

echo "Moved legacy scripts to scripts/legacy/"
