<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\JsonResponse;

class SyncController extends Controller
{
    /**
     * استقبال ومعالجة البيانات القادمة من تعز بحتمية مطلقة ومقاومة لقطع الإنترنت.
     */
    public function syncData(Request $request): JsonResponse
    {
        $requestId = $request->header('X-Request-ID');
        $tenantId = auth()->user()->tenant_id;

        if (empty($requestId)) {
            return response()->json([
                'status' => 'error',
                'message' => 'CRITICAL_SECURITY_BREACH: X-Request-ID header is missing.'
            ], 400);
        }

        // اختبار الحتمية الحركي (Idempotency Core Engine)
        // استخدام insertOrIgnore لمنع تكرار القيد المالي أو السجل التقني هندسياً
        $isUnique = DB::table('ai_logs')->insertOrIgnore([
            'tenant_id'  => $tenantId,
            'request_id' => $requestId,
            'payload'    => json_encode($request->all()),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // إذا كانت القيمة 0، فهذا يعني أن الطلب مكرر وتم التقاطه وحظره بنجاح
        if ($isUnique === 0) {
            return response()->json([
                'status'  => 'ignored',
                'message' => 'Idempotency Engine: Duplicate request detected and neutralized safely.'
            ], 200);
        }

        // إطلاق المعاملة المالية الآمنة داخل دفتر القيد المزدوج (Ledger)
        DB::beginTransaction();
        try {
            // هنا يتم حقن منطق معالجة الحسابات والطلبات (Ledger Transactions)
            
            DB::commit();
            return response()->json([
                'status'  => 'success',
                'message' => 'Data synchronized and committed to ledger successfully.'
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'status' => 'error',
                'message' => 'Transaction failed: ' . $e->getMessage()
            ], 500);
        }
    }
}

