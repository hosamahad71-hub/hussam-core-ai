const crypto = require('crypto');

// 🧪 محاكاة حارس البوابة المطور مع طبقة عزل وحقن الأخطاء (Chaos Mock Gateway)
class UltraResilientGateway {
    constructor() {
        this.circuitState = "CLOSED"; // CLOSED, OPEN, HALF_OPEN
        this.failureCount = 0;
        this.FAILURE_THRESHOLD = 3;   // فتح القاطع بعد 3 أخطاء متتالية
        this.HALF_OPEN_TIMEOUT = 2000; // المحاولة مجدداً بعد ثانيتين
        this.redisOnline = true;       // مفتاح التحكم بالشبكة الافتراضية للـ Broker
        
        // سجلات الذاكرة للتحقق الرقمي بعد الاختبار
        this.sovereignStream = [];
        this.deadLetterQueue = [];
        this.localFallbackStore = [];
    }

    // 💥 حقن الخطأ العمدي - قطع اتصال الـ Message Broker
    injectNetworkPartition(status) {
        this.redisOnline = !status;
        console.log(`\n🚨 [CHAOS INJECTION] Redis Network Partition Set to: ${status ? 'DISCONNECTED ❌' : 'ONLINE  '}`);
    }

    // 📡 محرك قذف الأحداث السيادي
    async publishEvent(lane, eventName, payload) {
        const eventPacket = {
            eventId: `evt_${crypto.randomUUID().slice(0,8)}`,
            eventName: eventName,
            timestamp: Date.now(),
            lane: lane,
            payload: payload
        };

        // 1️⃣ فحص حالة الـ Circuit Breaker
        if (this.circuitState === "OPEN") {
            this.localFallbackStore.push(eventPacket);
            return { status: "REJECTED_BY_CIRCUIT", action: "LOCAL_FALLBACK_BUFFERED" };
        }

        // 2️⃣ محاكاة قذف الحدث في عصب الـ Redis Streams
        try {
            if (!this.redisOnline) {
                throw new Error("Connection Refused to Redis Sovereign Bus");
            }

            // في حال النجاح
            this.sovereignStream.push(eventPacket);
            this.failureCount = 0;
            if (this.circuitState === "HALF_OPEN") this.circuitState = "CLOSED";
            return { status: "SUCCESS_STREAM", id: eventPacket.eventId };

        } catch (err) {
            // 3️⃣ تفعيل آليات الطوارئ عند حدوث الفشل
            this.failureCount++;
            this.deadLetterQueue.push(eventPacket); // العزل الفوري في الـ DLQ لمنع فقدان الحزمة

            if (this.failureCount >= this.FAILURE_THRESHOLD && this.circuitState !== "OPEN") {
                this.circuitState = "OPEN";
                console.log(`🛑 [CIRCUIT BREAKER] Threshold Breached! Switching State to: OPEN 🔓 (Traffic Diverted)`);
                
                // جدولة الدخول في حالة نصف مفتوح HALF_OPEN للفحص الذاتي لاحقاً
                setTimeout(() => {
                    this.circuitState = "HALF_OPEN";
                    console.log(`\n🔄 [CIRCUIT BREAKER] Timeout Passed. Entering: HALF_OPEN ⚠️ (Testing Backbone Quality)`);
                }, this.HALF_OPEN_TIMEOUT);
            }

            return { status: "ROUTED_TO_DLQ", reason: err.message };
        }
    }
}

// 🚀 بدء سيناريو الفحص الشامل وتحت الضغط الناري
async function runChaosAudit() {
    console.log("🔥 Starting 100% System Audit - Fault Injection Micro-Test v1.0");
    const gateway = new UltraResilientGateway();

    // 🟢 الاختبار الأول: استقرار النظام تحت التدفق الطبيعي
    console.log("\n--- Test 1: Baseline Stability under Heavy Burst ---");
    for (let i = 1; i <= 3; i++) {
        let res = await gateway.publishEvent('write', 'OrderCreated', { amount: i * 5000 });
        console.log(`📍 Sent Event ${i}: Status => ${res.status}`);
    }

    // 🔴 الاختبار الثاني: حقن الانهيار الفجائي وقطع الـ Redis
    console.log("\n--- Test 2: Injecting Sudden Failure (Redis Crash) ---");
    gateway.injectNetworkPartition(true); // قطع الاتصال عمداً

    for (let i = 4; i <= 7; i++) {
        let res = await gateway.publishEvent('write', 'OrderCreated', { amount: i * 5000 });
        console.log(`📍 Sent Event ${i}: Status => ${res.status}`);
    }

    // 🟡 الاختبار الثالث: فحص صمام الأمان ومنع التدفق الإضافي
    console.log("\n--- Test 3: Circuit Breaker Enforcement (Load Shedding) ---");
    let resFallback = await gateway.publishEvent('write', 'OrderCreated', { amount: 9999 });
    console.log(`📍 Sent Event 8 (While Circuit Open): Status => ${resFallback.status} | Action => ${resFallback.action}`);

    // 🔵 الاختبار الرابع: التعافي التلقائي الذكي والعودة للاستقرار
    console.log("\n⏳ Waiting for Circuit Breaker to transition into HALF_OPEN...");
    await new Promise(resolve => setTimeout(resolve, 2200));

    console.log("\n--- Test 4: Testing Backbone Recovery Quality ---");
    gateway.injectNetworkPartition(false); // إعادة شبكة Redis للخدمة

    let resRecovery = await gateway.publishEvent('write', 'OrderCreated', { amount: 100000 });
    console.log(`📍 Sent Recovery Event 9: Status => ${resRecovery.status} | Circuit State => ${gateway.circuitState}`);

    // 📊 كشف الحساب الرقمي والتدقيق النهائي للصك
    console.log("\n=======================================================");
    console.log("📊 FINAL FAULT AUDIT REPORT (Sovereign Verification)");
    console.log("=======================================================");
    console.log(`✔️ Total Events Successfully Processed in Stream: ${gateway.sovereignStream.length}`);
    console.log(`⚠️ Total Corrupted/Isolated Events Rescued in DLQ : ${gateway.deadLetterQueue.length}`);
    console.log(`🛡️ Total Events Buffered in Local Fallback (Protected): ${gateway.localFallbackStore.length}`);
    console.log("=======================================================");
    
    if (gateway.deadLetterQueue.length === 3 && gateway.localFallbackStore.length === 1) {
        console.log("🏆 AUDIT RESULT: 100% PERFECT! No Data Lost. The Backbone is UNBREAKABLE! 💎");
    } else {
        console.log("❌ AUDIT RESULT: Vulnerability Detected. Data leakage occurred.");
    }
}

runChaosAudit();
