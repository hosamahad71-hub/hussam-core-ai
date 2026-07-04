const net = require('net');
const http = require('http');
const crypto = require('crypto');
const { createParser, sendFrame } = require('./src/core/framing');

const SOCKET_PATH = process.env.HOME + '/hussam.sock';
const GATEWAY_PORT = 8080;
const METRICS_PORT = 8081;
const ACCESS_SECRET = "YEMEN-CORE-2026-SECURE";

// 🏗️ طوابير حقيقية خاضعة لكابح الضغط
const queues = { admin: [], write: [], read: [] };
const pendingRequests = new Map();

let kernelConn = null;
let circuitState = "CLOSED";
let activeFlights = 0; 
const MAX_CONCURRENT_FLIGHTS = 4; // كابح الدخول لمطابقة الـ Workers وتوليد الضغط الحقيقي

// تليمتري تفصيلي يفصل زمن الانتظار عن زمن التنفيذ
const queueMetrics = {
    admin: { total: 0, success: 0, queueWaitSum: 0, procSum: 0 },
    write: { total: 0, success: 0, queueWaitSum: 0, procSum: 0 },
    read:  { total: 0, success: 0, queueWaitSum: 0, procSum: 0 }
};

function connectToKernel() {
    kernelConn = net.connect(SOCKET_PATH);
    circuitState = "CLOSED";

    const parse = createParser((res) => {
        if (res.id && pendingRequests.has(res.id)) {
            const reqState = pendingRequests.get(res.id);
            
            const procTime = Date.now() - reqState.dispatchedAt;
            
            queueMetrics[reqState.queueType].success++;
            queueMetrics[reqState.queueType].queueWaitSum += reqState.queueWaitMs;
            queueMetrics[reqState.queueType].procSum += procTime;
            
            pendingRequests.delete(res.id);
            sendFrame(reqState.client, res);
            
            activeFlights--;
            drainQueues(); // إطلاق النبضة التالية فور تحرر خانة في النواة
        }
    });

    kernelConn.on('data', parse);
    kernelConn.on('error', () => {
        kernelConn = null;
        circuitState = "OPEN";
        setTimeout(connectToKernel, 2000);
    });
}

// 🎯 محرك صرف الطوابير الذكي بحسب الأولوية (Priority Drain Loop)
function drainQueues() {
    if (!kernelConn || circuitState === "OPEN") return;

    while (activeFlights < MAX_CONCURRENT_FLIGHTS) {
        let selectedTask = null;
        let selectedType = null;

        // فحص الطوابير بحسب رتبة الأهمية الإستراتيجية لأمازون اليمن
        if (queues.admin.length > 0) { selectedType = 'admin'; }
        else if (queues.write.length > 0) { selectedType = 'write'; }
        else if (queues.read.length > 0) { selectedType = 'read'; }

        if (!selectedType) break; // الطوابير كلها فارغة حالياً

        selectedTask = queues[selectedType].shift();
        const now = Date.now();
        const queueWaitMs = now - selectedTask.enqueuedAt;

        activeFlights++;
        pendingRequests.set(selectedTask.id, {
            client: selectedTask.client,
            queueType: selectedType,
            queueWaitMs: queueWaitMs,
            dispatchedAt: now
        });

        sendFrame(kernelConn, { id: selectedTask.id, payload: selectedTask.payload });
    }
}

connectToKernel();

// خادم التليمتري عالي الدقة والمفصل هندسياً
http.createServer((req, res) => {
    if (req.url === '/health') {
        res.writeHead(circuitState === "CLOSED" ? 200 : 503, { 'Content-Type': 'application/json' });
        
        const report = {
            status: circuitState === "CLOSED" ? "HEALTHY" : "CIRCUIT_OPEN",
            active_flights_to_kernel: activeFlights,
            backlog_depth: {
                admin: queues.admin.length,
                write: queues.write.length,
                read: queues.read.length
            },
            telemetry_lanes: {}
        };

        for (const key in queueMetrics) {
            const m = queueMetrics[key];
            report.telemetry_lanes[key] = {
                total_packets: m.total,
                processed_packets: m.success,
                avg_queue_wait: m.success > 0 ? Math.round(m.queueWaitSum / m.success) + " ms" : "0 ms",
                avg_kernel_processing: m.success > 0 ? Math.round(m.procSum / m.success) + " ms" : "0 ms"
            };
        }

        res.end(JSON.stringify(report, null, 2));
    } else { res.writeHead(404); res.end(); }
}).listen(METRICS_PORT, '0.0.0.0');

const gateway = net.createServer((client) => {
    let authenticated = false;
    
    const parse = createParser((req) => {
        if (!authenticated) {
            if (req.secret === ACCESS_SECRET) { authenticated = true; sendFrame(client, { status: "AUTH_OK" }); }
            else { client.end(); }
        } else {
            const queueType = req.queueType || 'read';
            queueMetrics[queueType].total++;

            // دفع الطلب إلى الطابور مع بصمة الدخول الحتمية
            queues[queueType].push({
                id: crypto.randomUUID(),
                payload: req.payload,
                enqueuedAt: Date.now(),
                client: client
            });

            drainQueues();
        }
    });
    client.on('data', parse);
});
gateway.listen(GATEWAY_PORT, '0.0.0.0');
