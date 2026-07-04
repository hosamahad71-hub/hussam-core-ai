#!/data/data/com.termux/files/usr/bin/bash

echo "================= [DEEP SYSTEM AUDIT] ================="
echo "🎯 TARGET: CLEAN-STATE VERIFICATION"
echo "🕒 TIMESTAMP: $(date)"
echo ""

echo "🧠 1. VERIFY PROCESS ABSENCE (No Ghosts)"
echo "----------------------------------------"
# التأكد أن أي Node أو PHP قد اختفى فعلياً
node_count=$(pgrep -f "node" | wc -l)
php_count=$(pgrep -f "php" | wc -l)
echo ">> Active Node count: $node_count"
echo ">> Active PHP count: $php_count"

echo ""
echo "🌐 2. NETWORK & SOCKET SECURITY"
echo "----------------------------------------"
# التأكد أن السوكيت قد حذف تماماً
if [ -e ~/hussam.sock ]; then
    echo "❌ CRITICAL: hussam.sock still exists!"
else
    echo "✅ hussam.sock removed (Socket clean)"
fi

echo ""
echo "📁 3. FS INTEGRITY (PID Locks)"
echo "----------------------------------------"
pid_files=$(ls ~/hussam-core/*.pid 2>/dev/null | wc -l)
if [ "$pid_files" -eq 0 ]; then
    echo "✅ PID files clean"
else
    echo "⚠️ PID files found: $pid_files (Manual intervention needed)"
    ls -l ~/hussam-core/*.pid
fi

echo ""
echo "💾 4. SYSTEM RESOURCE BASELINE (Post-Purge)"
echo "----------------------------------------"
# هذه قراءتنا للذاكرة والـ Swap وهي "فارغة" الآن
free -h 2>/dev/null || echo "⚠️ Free command missing"

echo ""
echo "📊 5. POST-PURGE TOP CHECK"
echo "----------------------------------------"
# التأكد أن الـ CPU في حالة راحة تامة (Idle)
top -b -n 1 | head -n 15

echo ""
echo "================= [AUDIT COMPLETE] ================="
