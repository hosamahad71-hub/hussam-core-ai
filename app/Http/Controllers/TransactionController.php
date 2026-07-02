<?php

namespace App\Http\Controllers;

use App\Models\TransactionLedger;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class TransactionController extends Controller
{
    /**
     * جلب كشف الحساب المالي (Ledger) الخاص بمستخدم معين لتعرض في الـ Flutter
     */
    public function index($userId)
    {
        $transactions = TransactionLedger::where('user_id', $userId)
            ->orderBy('created_at', 'desc')
            ->paginate(15); // تقسيم النتائج لسرعة التحميل في الهاتف

        return response()->json([
            'status' => 'success',
            'data' => $transactions
        ], 200);
    }

    /**
     * تسجيل عملية مالية جديدة (دائن / مدين) بحماية صارمة ضد التلاعب
     */
    public function store(Request $request)
    {
        // 1. التحقق من صحة البيانات القادمة من التطبيق
        $validated = $request->validate([
            'user_id'     => 'required|exists:users,id',
            'type'        => 'required|in:credit,debit',
            'amount'      => 'required|numeric|min:0.01',
            'sector'      => 'nullable|string',
            'description' => 'nullable|string',
            'metadata'    => 'nullable|array',
        ]);

        // 2. استخدام DB Transaction لمنع حدوث تضارب في الرصيد إذا تمت عمليتان في نفس الأجزاء من الثانية
        return DB::transaction(function () use ($validated) {
            
            // جلب آخر عملية مسجلة للمقاصة وحساب الرصيد الحالي
            $lastTransaction = TransactionLedger::where('user_id', $validated['user_id'])
                ->orderBy('id', 'desc')
                ->first();

            $currentBalance = $lastTransaction ? $lastTransaction->running_balance : 0.00;

            // حساب الرصيد التراكمي الجديد بناءً على نوع العملية
            if ($validated['type'] === 'credit') {
                // دائن (إيداع / دخول أموال للحساب)
                $newBalance = $currentBalance + $validated['amount'];
            } else {
                // مدين (سحب / خروج أموال من الحساب)
                $newBalance = $currentBalance - $validated['amount'];
            }

            // توليد رقم مرجعي فريد وذكي للعملية يحمل هوية المنصة
            $referenceId = 'HCAI-' . strtoupper(Str::random(4)) . '-' . time();

            // حقن العملية في قاعدة البيانات
            $transaction = TransactionLedger::create([
                'user_id'         => $validated['user_id'],
                'reference_id'    => $referenceId,
                'type'            => $validated['type'],
                'amount'          => $validated['amount'],
                'running_balance' => $newBalance,
                'sector'          => $validated['sector'] ?? 'General',
                'description'     => $validated['description'] ?? null,
                'metadata'        => $validated['metadata'] ?? null,
            ]);

            // إرجاع استجابة نجاح فورية لتطبيق Flutter بمعدل استجابة قياسي
            return response()->json([
                'status'  => 'success',
                'message' => 'Transaction recorded successfully',
                'data'    => $transaction
            ], 201);
        });
    }
}
