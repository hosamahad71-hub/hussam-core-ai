#!/bin/bash
echo "🛑 [CONTROL PLANE] Initiating zero-leak environmental cleanup..."
pkill -15 -f "node .*hussam" 2>/dev/null
sleep 1.5
rm -f "$HOME/hussam.sock"
rm -f "$HOME/kernel.ready"
echo "✨ [CONTROL PLANE] Baseline sanitized."
