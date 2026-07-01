<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\SectorController;
/*
|--------------------------------------------------------------------------

| Hussam Core AI - API Routes Matrix
| :--- |
| هنا نحدد المنافذ البرمجية الآمنة التي يتصل بها تطبيق الـ Flutter
| لجلب مصفوفة البيانات والقطاعات بشكل فوري وبأعلى كفاءة.

*/
Route::get('/v1/core-matrix', [SectorController::class, 'index']);
