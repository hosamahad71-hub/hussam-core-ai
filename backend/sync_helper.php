#!/usr/bin/env php
<?php
$options = getopt("", ["dsn::", "user::", "pass::", "file::", "help::"]);
if (isset($options['help'])) {
    echo "Usage: php sync_helper.php --dsn='pgsql:host=...;port=...;dbname=...' --user=... --pass=... [--file=data.jsonl]\n";
    exit(0);
}
$dsn = $options['dsn'] ?? getenv('SYNC_PG_DSN') ?: null;
$user = $options['user'] ?? getenv('SYNC_PG_USER') ?: null;
$pass = $options['pass'] ?? getenv('SYNC_PG_PASS') ?: null;
$file = $options['file'] ?? null;
if (!$dsn) {
    fwrite(STDERR, "Missing DSN (use --dsn or set SYNC_PG_DSN)\n");
    exit(2);
}
try {
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (Exception $e) {
    fwrite(STDERR, "Failed to connect to Postgres: " . $e->getMessage() . "\n");
    exit(3);
}
$in = STDIN;
if ($file) {
    if (!file_exists($file)) {
        fwrite(STDERR, "File not found: $file\n");
        exit(4);
    }
    $in = fopen($file, 'r');
}
$lineNo = 0;
while (!feof($in)) {
    $line = trim(fgets($in));
    $lineNo++;
    if ($line === '') continue;
    $obj = json_decode($line, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        fwrite(STDERR, "JSON parse error on line $lineNo\n");
        continue;
    }
    $type = $obj['type'] ?? null;
    if ($type === 'tenant') {
        $sql = "INSERT INTO tenants (id, code, name, region, metadata, created_at, updated_at)
                VALUES (:id, :code, :name, :region, :metadata, coalesce(:created_at, now()), coalesce(:updated_at, now()))
                ON CONFLICT (id) DO UPDATE SET
                  code = EXCLUDED.code,
                  name = EXCLUDED.name,
                  region = EXCLUDED.region,
                  metadata = EXCLUDED.metadata,
                  updated_at = EXCLUDED.updated_at";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':id' => $obj['id'] ?? null,
            ':code' => $obj['code'] ?? $obj['id'] ?? null,
            ':name' => $obj['name'] ?? 'unknown',
            ':region' => $obj['region'] ?? 'unknown',
            ':metadata' => json_encode($obj['metadata'] ?? new stdClass()),
            ':created_at' => $obj['created_at'] ?? null,
            ':updated_at' => $obj['updated_at'] ?? null,
        ]);
    } elseif ($type === 'ai_log') {
        $sql = "INSERT INTO ai_logs (tenant_id, event_at, request_id, model, prompt, response, cost, region, created_at)
                VALUES (:tenant_id, :event_at, :request_id, :model, :prompt, :response, :cost, :region, coalesce(:created_at, now()))";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':tenant_id' => $obj['tenant_id'],
            ':event_at' => $obj['event_at'] ?? date('c'),
            ':request_id' => $obj['request_id'] ?? null,
            ':model' => $obj['model'] ?? 'unknown',
            ':prompt' => json_encode($obj['prompt'] ?? new stdClass()),
            ':response' => json_encode($obj['response'] ?? null),
            ':cost' => $obj['cost'] ?? 0.0,
            ':region' => $obj['region'] ?? null,
            ':created_at' => $obj['created_at'] ?? null,
        ]);
    } else {
        fwrite(STDERR, "Unknown type on line $lineNo\n");
    }
}
if ($file) fclose($in);
fwrite(STDOUT, "Sync completed\n");
