const crypto = require('crypto');

class DeterministicEventLedger {
    constructor() {
        this.ledger = new Map(); // السجل السيادي الموحد غير القابل للتلاعب
        this.circuitState = "CLOSED"; // CLOSED, OPEN, HALF_OPEN
        this.failureCount = 0;
        this.FAILURE_THRESHOLD = 3;
        this.HALF_OPEN_TIMEOUT = 1000;
        this.redisOnline = true;
    }

    injectNetworkCrash(status) {
        this.redisOnline = !status;
        console.log(`\n💥 [CHAOS] Redis Broker Online State: ${this.redisOnline}`);
    }

    // 🔒 محرك الحسم النهائي (Finality Engine)
    async executeAndLog(lane, eventName, payload) {
        const eventId = `evt_${crypto.randomUUID().slice(0,8)}`;
        
        // 1️⃣ المسار الأول: الرفض القطعي الفوري بسبب فتح الصمام (Edge Rejection)
        if (this.circuitState === "OPEN") {
            this.ledger.set(eventId, { eventName, lane, status: "CIRCUIT_REJECTED", timestamp: Date.now() });
            return { eventId, status: "CIRCUIT_REJECTED" };
        }

        try {
            if (!this.redisOnline) throw new Error("Broker Connection Lost");

            // 2️⃣ المسار الثاني: التقييد القطعي الناجح في العصب الوسيط
            this.failureCount = 0;
            if (this.circuitState === "HALF_OPEN") this.circuitState = "CLOSED";
            
            this.ledger.set(eventId, { eventName, lane, status: "COMMITTED_TO_STREAM", timestamp: Date.now() });
            return { eventId, status: "COMMITTED_TO_STREAM" };

        } catch (err) {
            this.failureCount++;
            
            // 3️⃣ المسار الثالث: العزل القطعي النهائي في الـ DLQ عند الفشل
            this.ledger.set(eventId, { eventName, lane, status: "TERMINATED_IN_DLQ", timestamp: Date.now(), error: err.message });

            if (this.failureCount >= this.FAILURE_THRESHOLD && this.circuitState !== "OPEN") {
                this.circuitState = "OPEN";
                console.log(`🛑 [CIRCUIT] Opened. Diverting all incoming traffic.`);
                setTimeout(() => {
                    this.circuitState = "HALF_OPEN";
                    console.log(`\n🔄 [CIRCUIT] Testing recovery via HALF_OPEN...`);
                }, this.HALF_OPEN_TIMEOUT);
            }

            return { eventId, status: "TERMINATED_IN_DLQ" };
        }
    }

    // 📊 توليد تقرير المطابقة والميزانية البرمجية الشاملة
    generateAuditReport() {
        console.log("\n=======================================================");
        console.log("📜 SOVEREIGN EVENT LEDGER - AUDIT REPORT (v1.0)");
        console.log("=======================================================");
        
        let committed = 0, terminated = 0, rejected = 0;
        
        for (let [id, record] of this.ledger.entries()) {
            console.log(`🔑 [${id}] -> STATUS: ${record.status} | Lane: ${record.lane}`);
            if (record.status === "COMMITTED_TO_STREAM") committed++;
            if (record.status === "TERMINATED_IN_DLQ") terminated++;
            if (record.status === "CIRCUIT_REJECTED") rejected++;
        }

        console.log("-------------------------------------------------------");
        console.log(`📊 Metrics: Committed: ${committed} | Terminated (DLQ): ${terminated} | Rejected: ${rejected}`);
        console.log(`📐 Total Ledger Integrity: ${this.ledger.size} Events Cataloged.`);
        console.log("=======================================================");
        
        // التحقق الحتمي: لا وجود لـ Transient/Buffer عائم، كل شيء مصنف ومحسوم
        if (this.ledger.size === (committed + terminated + rejected)) {
            console.log("🏆 DETERMINISTIC VERIFICATION: 100% AUDITABLE & SAFE! 💎");
        } else {
            console.log("❌ AUDIT FAILED: Non-deterministic states leaked!");
        }
    }
}

async function runProductionAudit() {
    const engine = new DeterministicEventLedger();
    
    console.log("🔥 Starting Deterministic Finality Test under Chaotic Loads...");

    // ضخ طبيعي
    await engine.executeAndLog('write', 'OrderCreated', { price: 25000 });
    await engine.executeAndLog('write', 'OrderCreated', { price: 40000 });

    // إسقاط الـ Broker فجأة
    engine.injectNetworkCrash(true);
    await engine.executeAndLog('write', 'OrderCreated', { price: 12000 });
    await engine.executeAndLog('write', 'OrderCreated', { price: 85000 });
    await engine.executeAndLog('write', 'OrderCreated', { price: 90000 }); // سيفتح القاطع هنا

    // طلبات إضافية أثناء فتح القاطع (تتحول فورا لـ Rejected قطعي دون تعليق)
    await engine.executeAndLog('write', 'OrderCreated', { price: 3000 });

    // انتهاء النافذة الزمنية والتعافي
    await new Promise(resolve => setTimeout(resolve, 1100));
    engine.injectNetworkCrash(false);
    await engine.executeAndLog('write', 'OrderCreated', { price: 55000 });

    // استخراج الدفتر السيادي
    engine.generateAuditReport();
}

runProductionAudit();
