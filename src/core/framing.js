exports.sendFrame = (socket, obj) => {
    const payload = Buffer.from(JSON.stringify(obj));
    const header = Buffer.alloc(4);
    header.writeUInt32BE(payload.length, 0);
    socket.write(Buffer.concat([header, payload]));
};

exports.createParser = (onFrame) => {
    let buffer = Buffer.alloc(0);
    return (data) => {
        buffer = Buffer.concat([buffer, data]);
        while (buffer.length >= 4) {
            const length = buffer.readUInt32BE(0);
            if (buffer.length >= 4 + length) {
                const frameData = buffer.slice(4, 4 + length);
                buffer = buffer.slice(4 + length);
                try { onFrame(JSON.parse(frameData.toString())); } catch (e) { console.error("Parsing Error", e); }
            } else { break; }
        }
    };
};
