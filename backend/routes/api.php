<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\SyncController;
/*
|--------------------------------------------------------------------------

| API Routes - Hussam Core AI Platform
| :--- |

*/
// مجموعة مسارات الإصدار الأول للمنصة مع البادئة المنضبطة
Route::prefix('api/v1')->group(function () {
    // 1. مسارات المصادقة العامة (Authentication)
    Route::post('auth/login', [AuthController::class, 'login']);
    Route::post('auth/register', [AuthController::class, 'register']);
    // 2. مسارات المصادقة المحمية بجدار الحماية المصرفي (Sanctum)
    Route::middleware('auth:sanctum')->group(function () {
        
        // تسجيل الخروج وجلب بيانات الملف الشخصي
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('profile', [ProfileController::class, 'me']);
        // مسار استقبال طلبات المزامنة وحظر التكرار (Idempotency Engine)
        // تم ربطه بالدالة المحدثة 'syncData' التي تحمي الدفتر المالي
        Route::post('sync', [SyncController::class, 'syncData']);
    });
});
