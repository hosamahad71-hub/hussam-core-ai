<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class LedgerTransaction extends Model
{
    use HasFactory;

    protected $table = 'ledger_transactions';

    protected $fillable = [
        'tenant_id', 'uuid', 'reference', 'description', 'posted_at', 'metadata', 'total_debits', 'total_credits',
    ];

    protected $casts = [
        'metadata' => 'array',
        'posted_at' => 'datetime',
        'total_debits' => 'decimal:4',
        'total_credits' => 'decimal:4',
    ];

    public function tenant()
    {
        return $this->belongsTo(\App\Models\Tenant::class);
    }

    public function entries()
    {
        return $this->hasMany(LedgerEntry::class, 'ledger_transaction_id');
    }

    /**
     * Record a balanced double-entry transaction for a tenant.
     *
     * $tenantId: integer
     * $entries: array of arrays:
     *    [
     *      'account_id' => int,
     *      'side' => 'debit'|'credit',
     *      'amount' => string|float (positive)
     *      'metadata' => array optional
     *    ]
     * $payload: ['reference' => string, 'description' => string, 'posted_at' => Carbon|null, 'metadata' => array|null]
     *
     * Throws ValidationException if not balanced.
     */
    public static function record(int $tenantId, array $entries, array $payload = [])
    {
        // normalize and sum
        $totalDebits = 0.0;
        $totalCredits = 0.0;

        foreach ($entries as $e) {
            $side = strtolower($e['side'] ?? '');
            $amt = (float) $e['amount'];
            if ($amt <= 0) {
                throw ValidationException::withMessages(['amount' => 'Entry amounts must be positive.']);
            }
            if ($side === 'debit') {
                $totalDebits = bcadd((string)$totalDebits, (string)$amt, 4);
            } elseif ($side === 'credit') {
                $totalCredits = bcadd((string)$totalCredits, (string)$amt, 4);
            } else {
                throw ValidationException::withMessages(['side' => 'Entry side must be debit or credit.']);
            }
        }

        // Balanced?
        if (bccomp((string)$totalDebits, (string)$totalCredits, 4) !== 0) {
            throw ValidationException::withMessages(['transaction' => 'Transaction must be balanced: total debits must equal total credits.']);
        }

        // Atomic write
        return DB::transaction(function () use ($tenantId, $entries, $payload, $totalDebits, $totalCredits) {
            $tx = self::create([
                'tenant_id' => $tenantId,
                'uuid' => (string) Str::uuid(),
                'reference' => $payload['reference'] ?? null,
                'description' => $payload['description'] ?? null,
                'posted_at' => $payload['posted_at'] ?? now(),
                'metadata' => $payload['metadata'] ?? null,
                'total_debits' => $totalDebits,
                'total_credits' => $totalCredits,
            ]);

            foreach ($entries as $entry) {
                $account = Account::where('id', $entry['account_id'])->where('tenant_id', $tenantId)->lockForUpdate()->firstOrFail();

                // Determine signed amount to apply to account's balance:
                // Convention example: assets and expenses increase with debits; liabilities, equity, revenue increase with credits.
                // For cached balance we will apply signed amounts by entry_side and account type.
                $side = strtolower($entry['side']);
                $amt = (string) number_format((float)$entry['amount'], 4, '.', '');

                // Compute the signed amount to add to stored balance.
                // To keep simple and consistent, we will:
                //  - For 'debit' entries: add +amount to balance
                //  - For 'credit' entries: add -amount to balance
                // This means balance sign semantics are "debit-positive". If you prefer normal balance semantics per account type,
                // adapt adjustBalance logic or store positive/negative balances per account type.
                $signedAmount = $side === 'debit' ? $amt : '-' . $amt;

                // Insert ledger entry
                $ledgerEntry = LedgerEntry::create([
                    'ledger_transaction_id' => $tx->id,
                    'tenant_id' => $tenantId,
                    'account_id' => $account->id,
                    'entry_side' => $side,
                    'amount' => $amt,
                    'account_balance_after' => null, // will update after balance adjust
                    'metadata' => $entry['metadata'] ?? null,
                ]);

                // Adjust account balance and store snapshot
                // Use lockForUpdate above to serialize balance updates
                $account->balance = bcadd((string)$account->balance, (string)$signedAmount, 4);
                $account->save();

                // update snapshot on ledger entry
                $ledgerEntry->account_balance_after = $account->balance;
                $ledgerEntry->save();
            }

            return $tx;
        });
    }
}
