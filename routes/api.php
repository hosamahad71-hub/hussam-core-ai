use App\Http\Controllers\TransactionController;
/*
|--------------------------------------------------------------------------

| Hussam Core AI - API Matrix Routes (V1)
| :--- |

*/
Route::prefix('v1/matrix')->group(function () {
    // مسار جلب كشف الحساب المالي اللحظي للتجار والعملاء
    Route::get('/ledger/{userId}', [TransactionController::class, 'index']);
    
    // مسار تسجيل عملية مالية جديدة (سحب / إيداع)
    Route::post('/ledger/transaction', [TransactionController::class, 'store']);
});
