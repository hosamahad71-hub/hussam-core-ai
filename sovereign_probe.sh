#!/data/data/com.termux/files/usr/bin/bash

echo "================= [PROBE: SOVEREIGN SYSTEM DIAGNOSTIC] ================="
echo "🎯 TARGET: TERMUX ENVIRONMENT"
echo "🕒 TIMESTAMP: $(date)"
echo ""

echo "🧠 1. PROCESS CONTROL PLANE (The Controllers)"
echo "----------------------------------------------"
echo ">> Searching for PM2, Node, and PHP orphans..."
ps aux | grep -E "pm2|node|php|gateway|server|postgres" | grep -v grep | awk '{print $1, $2, $9, $11}'

echo ""
echo "🌐 2. NETWORK & SOCKET INTEGRITY"
echo "----------------------------------------------"
echo ">> Checking for active unix sockets and ports..."
ls -l ~/hussam.sock 2>/dev/null || echo "❌ No hussam.sock found"
# محاولة فحص المنافذ بطريقة توافق التريمكس
if command -v ss >/dev/null 2>&1; then
    ss -lntp
else
    netstat -tulnp 2>/dev/null || echo "⚠️ netstat/ss not fully accessible"
fi

echo ""
echo "📁 3. FS SOVEREIGNTY (File Integrity)"
echo "----------------------------------------------"
echo ">> Checking PID files and kernel locks..."
ls -l ~/hussam-core/*.pid 2>/dev/null
echo ">> Latest log entries (tail of system files):"
tail -n 5 ~/hussam-core/gateway.js 2>/dev/null | head -n 1 # نموذج فقط للتحقق

echo ""
echo "💾 4. RESOURCE HARDNESS (Memory/Disk)"
echo "----------------------------------------------"
echo ">> System Load & Memory:"
free -h 2>/dev/null || echo "⚠️ Free command missing"
echo ">> Disk Space:"
df -h ~ | grep -E "Filesystem|/data"

echo ""
echo "🔥 5. CPU/KERNEL PRESSURE"
echo "----------------------------------------------"
# فحص سريع لنسبة استخدام الـ CPU الكلية
top -b -n 1 | grep "CPU" | head -n 1

echo ""
echo "================= [END PROBE] ================="
