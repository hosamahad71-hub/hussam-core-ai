const { Worker } = require('worker_threads');
const path = require('path');

module.exports = class WorkerPool {
    constructor(size = 4) {
        this.size = size;
        this.workers = [];
        this.queue = [];
        this.activeWorkers = new Map();

        for (let i = 0; i < size; i++) {
            const worker = new Worker(path.join(__dirname, 'sandbox.js'));
            worker.on('message', (res) => {
                const callback = this.activeWorkers.get(res.id);
                if (callback) {
                    this.activeWorkers.delete(res.id);
                    callback(null, res);
                }
                this.next(worker);
            });
            worker.on('error', (err) => { console.error("Worker Error", err); });
            this.workers.push(worker);
        }
    }

    next(worker) {
        if (this.queue.length === 0) {
            this.workers.push(worker);
            return;
        }
        const { task, callback } = this.queue.shift();
        this.activeWorkers.set(task.id, callback);
        worker.postMessage(task);
    }

    execute(task) {
        return new Promise((resolve, reject) => {
            const callback = (err, res) => err ? reject(err) : resolve(res);
            if (this.workers.length > 0) {
                const worker = this.workers.pop();
                this.activeWorkers.set(task.id, callback);
                worker.postMessage(task);
            } else {
                this.queue.push({ task, callback });
            }
        });
    }
};
