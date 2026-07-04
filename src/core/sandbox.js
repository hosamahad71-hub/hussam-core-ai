const { parentPort } = require('worker_threads');
parentPort.on('message', (task) => {
    // معالجة البيانات الحقيقية
    parentPort.postMessage({ id: task.id, status: 'SUCCESS', result: { processed: true, platform: "YEMEN-CORE-PROD", data: task.payload } });
});
