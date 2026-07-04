const net = require('net');
const { sendFrame, createParser } = require('./src/core/framing');

const GATEWAY_PORT = 8080;
const ACCESS_SECRET = "YEMEN-CORE-2026-SECURE";

console.log(`🔥 [STRESS] Injecting Burst Traffic to saturate sharded queues...`);

const client = net.connect({ port: GATEWAY_PORT, host: '127.0.0.1' }, () => {
    sendFrame(client, { secret: ACCESS_SECRET });
});

let received = 0;
const burstSize = 150; // ضخ 150 طلب دفعة واحدة لتوليد تكدس حقيقي

const parse = createParser((res) => {
    if (res.status === "AUTH_OK") {
        // ضخ عشوائي مكثف ومتزامن لخلط الأوراق واختبار الـ Execution Priority
        for (let i = 0; i < 80; i++)  sendFrame(client, { queueType: 'read', payload: { data: i } });
        for (let i = 0; i < 50; i++)  sendFrame(client, { queueType: 'write', payload: { data: i } });
        for (let i = 0; i < 20; i++)  sendFrame(client, { queueType: 'admin', payload: { data: i } });
    } else {
        received++;
        if (received === burstSize) {
            console.log(`\n💥 Burst complete. Saturation test concluded.`);
            console.log(`📊 Execute: 'curl -s http://127.0.0.1:8081/health' to expose the truth!`);
            process.exit(0);
        }
    }
});
client.on('data', parse);
