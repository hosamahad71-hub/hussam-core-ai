const net = require('net');
const fs = require('fs');
const { createParser, sendFrame } = require('./src/core/framing');
const WorkerPool = require('./src/core/pool');

const SOCKET = process.env.HOME + '/hussam.sock';
const READY_FILE = process.env.HOME + '/kernel.ready';

if (fs.existsSync(SOCKET)) fs.unlinkSync(SOCKET);
if (fs.existsSync(READY_FILE)) fs.unlinkSync(READY_FILE);

const pool = new WorkerPool(4); // 4 متزامنين كحد أقصى لحماية المعالج

const server = net.createServer((c) => {
    const parse = createParser(async (req) => {
        try {
            const result = await pool.execute({ id: req.id, payload: req.payload });
            sendFrame(c, result);
        } catch (e) {
            sendFrame(c, { id: req.id, error: e.message });
        }
    });
    c.on('data', parse);
});

server.listen(SOCKET, () => {
    console.log("🚀 HUSSAM KERNEL v4.0-Enterprise Activated");
    setTimeout(() => {
        const probe = net.connect(SOCKET, () => {
            fs.writeFileSync(READY_FILE, '1');
            console.log("往 KERNEL READY (Production Multi-Threading Active)");
            probe.destroy();
        });
    }, 50);
});
