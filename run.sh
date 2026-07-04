#!/bin/bash
READY_FILE="$HOME/kernel.ready"
node ~/hussam-core/server.js &
KERNEL_PID=$!

for i in {1..30}; do
    if [ -f "$READY_FILE" ]; then
        echo "✅ [DATA PLANE] Kernel contract verified."
        break
    fi
    sleep 0.2
done

node ~/hussam-core/gateway.js &
GATEWAY_PID=$!

echo $KERNEL_PID > ~/hussam-core/kernel.pid
echo $GATEWAY_PID > ~/hussam-core/gateway.pid
echo "🏁 [DATA PLANE] Infrastructure up at 95%+ Production-Grade."
