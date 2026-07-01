<?php

namespace App\Http\Controllers;

use App\Models\Sector;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log; // تم تصحيح مسار الحزمة هنا

class SectorController extends Controller
{
    /**
     * جلب مصفوفة القطاعات والخدمات النشطة لخدمة واجهات الـ SaaS و Flutter
     */
    public function index(): JsonResponse
    {
        try {
            // جلب القطاعات المفعلة مع خدماتها دفعة واحدة (Eager Loading)
            $matrixData = Sector::with('services')
                ->where('is_enabled', true)
                ->get();

            return response()->json([
                'status' => 'success',
                'system_identity' => 'Hussam Core AI Engine',
                'timestamp' => now()->toIso8601String(),
                'count' => $matrixData->count(),
                'data' => $matrixData
            ], 200);

        } catch (\Exception $e) {
            // تسجيل الخطأ فوراً في نظام الـ Observability للمنصة
            Log::error("Matrix Fetch Error: " . $e->getMessage());

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to retrieve matrix infrastructure data.',
                'trace_id' => uniqid('core_err_')
            ], 500);
        }
    }
}
