<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\SyncController;

Route::prefix('api/v1')->group(function () {
    Route::post('auth/login', [AuthController::class, 'login']);
    Route::post('auth/register', [AuthController::class, 'register']);
    Route::post('auth/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');

    Route::get('profile', [ProfileController::class, 'me'])->middleware('auth:sanctum');

    Route::post('sync', [SyncController::class, 'sync'])->middleware('auth:sanctum', 'tenant');
});
