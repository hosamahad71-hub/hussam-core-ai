# Scripts cleanup and usage

This project historically contained multiple top-level scripts. To reduce noise and centralize automation we moved legacy scripts to scripts/legacy and kept bootstrap_full.sh at the root for bootstrapping.

Kept at root:
- bootstrap_full.sh  -> main bootstrap for dev and staging

Moved to scripts/legacy:
- assemble_hussam_core.sh
- deep_system_audit.sh
- preflight.sh
- run.sh
- sovereign_probe.sh
- stress_test.js
- stress_test_saturation.js
- fault_injection_test.js

Usage:
- Use scripts/bootstrap_full.sh for environment bootstrapping.
- Legacy scripts are available for reference under scripts/legacy/ and should be reviewed before reuse.
