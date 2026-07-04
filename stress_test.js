const net = require('net');
const { sendFrame, createParser } = require('./src/core/framing');

const GATEWAY_PORT = 8080;
const ACCESS_SECRET = "YEMEN-CORE-2026-SECURE";
const CONCURRENT_CONNECTIONS = 10; 
const REQUESTS_PER_CONN = 10;      
const TOTAL_EXPECTED = CONCURRENT_CONNECTIONS * REQUESTS_PER_CONN;

const latencies = [];
let totalResponses = 0;
const wallClockStart = Date.now();
const sentTimes = new Map();

console.log(`🔥 [HUSSAM CORE TELEMETRY] Launching Deterministic Test Harness...`);

for (let c = 0; c < CONCURRENT_CONNECTIONS; c++) {
    const client = net.connect({ port: GATEWAY_PORT, host: '127.0.0.1' }, () => {
        sendFrame(client, { secret: ACCESS_SECRET });
    });

    const parse = createParser((res) => {
        if (res.status === "AUTH_OK") {
            for (let i = 0; i < REQUESTS_PER_CONN; i++) {
                const key = `${c}-${i}`;
                sentTimes.set(key, Date.now());
                sendFrame(client, { payload: { connectionId: c, index: i } });
            }
        } else if (res.result && res.result.data && res.result.data.connectionId !== undefined) {
            const data = res.result.data;
            const key = `${data.connectionId}-${data.index}`;
            const sentAt = sentTimes.get(key);

            if (sentAt) {
                latencies.push(Date.now() - sentAt);
            }
            totalResponses++;

            if (totalResponses === TOTAL_EXPECTED) {
                const totalWallClockTime = Date.now() - wallClockStart;
                latencies.sort((a, b) => a - b);

                console.log(`\n==================================================`);
                console.log(`📊 [PRODUCTION-GRADE HIGH-RESOLUTION LATENCY REPORT]`);
                console.log(`==================================================`);
                console.log(`⚡ Concurrency Sockets  : ${CONCURRENT_CONNECTIONS}`);
                console.log(`✅ Packets Audited      : ${totalResponses} / ${TOTAL_EXPECTED}`);
                console.log(`⏱️ Total Wall Clock Time : ${totalWallClockTime} ms`);
                console.log(`--------------------------------------------------`);
                console.log(`📉 MIN Latency         : ${latencies[0]} ms`);
                console.log(`📊 AVG Latency          : ${Math.round(latencies.reduce((s, v) => s + v, 0) / latencies.length)} ms`);
                console.log(`🎯 P50 Latency (Median) : ${latencies[Math.floor(latencies.length * 0.50)]} ms`);
                console.log(`⚠️ P95 Latency (Intense): ${latencies[Math.floor(latencies.length * 0.95)]} ms`);
                console.log(`🚨 P99 Latency (Tail)   : ${latencies[Math.floor(latencies.length * 0.99)]} ms`);
                console.log(`📈 MAX Latency (Worst)  : ${latencies[latencies.length - 1]} ms`);
                console.log(`==================================================`);
                process.exit(0);
            }
        } else if (res.error) {
            console.error(`❌ Rejected: ${res.error}`);
            totalResponses++;
        }
    });

    client.on('data', parse);
    client.on('error', (e) => console.error(`❌ Socket [${c}] Error: ${e.message}`));
}
