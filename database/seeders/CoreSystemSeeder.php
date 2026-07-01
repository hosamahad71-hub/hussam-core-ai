<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Sector;
use App\Models\Service;

class CoreSystemSeeder extends Seeder
{
    public function run(): void
    {
        // 1. قطاع ذكاء البيانات والـ AI النواتي المتقدم
        $dataCore = Sector::create([
            'name' => 'Data Intelligence & Core AI Matrix',
            'slug' => 'data-intelligence-core',
            'icon' => 'cpu_charge_bolt',
            'is_enabled' => true,
            'schema_definition' => [
                'allowed_regions' => ['YE', 'SA', 'AE'],
                'auth_type' => 'oauth_provider_secure',
                'observability_level' => 'high_trace_logging',
                'tunnel_routing' => 'cloudflare_secure_mesh'
            ]
        ]);

        // 2. قطاع إدارة العيادات والأنظمة الطبية والتحليل المخبري (بنية الـ Unit Clinical والـ Card Index)
        $healthCore = Sector::create([
            'name' => 'Clinical Intelligence & Medical Management Core',
            'slug' => 'clinical-intelligence-medical',
            'icon' => 'medical_matrix_shield',
            'is_enabled' => true,
            'schema_definition' => [
                'compliance' => 'encrypted_data_privacy_standard',
                'require_laboratory_routing' => true,
                'case_status_matrix' => ['pending', 'laboratory_processing', 'ready_for_delivery', 'completed']
            ]
        ]);

        // 3. قطاع السجلات المالية وإدارة الموارد الفاخرة لشركات التوزيع والتجزئة (Luxury Ledger Core)
        $enterpriseCore = Sector::create([
            'name' => 'Enterprise Resource & Luxury Ledger Operations',
            'slug' => 'enterprise-resource-ledgers',
            'icon' => 'ledger_luxury_gold',
            'is_enabled' => true,
            'schema_definition' => [
                'multi_tenant_scoped' => true,
                'currency_default' => 'YER',
                'accounting_precision' => 2,
                'design_aesthetic' => 'minimalist_luxury_dark'
            ]
        ]);

        // --- حقن الخدمات المركزية المربوطة بحقول الـ JSON المرنة لتغذية واجهات Flutter ---

        // خدمات قطاع الـ Data Core
        Service::create([
            'sector_id' => $dataCore->id,
            'name' => 'Real-Time Data Intelligence Mapping',
            'slug' => 'real-time-data-mapping',
            'price' => 450.00,
            'is_active' => true,
            'config' => ['sync_interval_ms' => 500, 'matrix_storage_type' => 'large_scale_data_matrices'],
            'features' => ['automated_backup_push', 'threat_intelligence_ml_filter'],
            'custom_data' => ['observability_logging' => 'ai_audit_trace']
        ]);

        // خدمات القطاع الطبي وإدارة ملفات الحالات والمختبرات
        Service::create([
            'sector_id' => $healthCore->id,
            'name' => 'Automated Laboratory Case Tracking & Card Index',
            'slug' => 'automated-lab-case-tracking',
            'price' => 120.00,
            'is_active' => true,
            'config' => ['tracking_system' => 'color_coded_status_matrix', 'device_sync' => true],
            'features' => ['patient_attendance_logs', 'inventory_dental_tools_automation'],
            'custom_data' => ['clinic_id_scope' => 'unit_clinic_main']
        ]);

        // خدمات إدارة السجلات المالية المتطورة (مثل أنظمة الغيث للمصفوفات التجارية المحمية)
        Service::create([
            'sector_id' => $enterpriseCore->id,
            'name' => 'Luxury Multi-Tenant Debt Ledger Engine',
            'slug' => 'luxury-debt-ledger-engine',
            'price' => 299.00,
            'is_active' => true,
            'config' => ['theme_aesthetic' => 'black_and_gold_luxury', 'manual_print_optimized' => true],
            'features' => ['real_time_balance_sheet_generation', 'zero_charitable_branding_enforcement'],
            'custom_data' => ['ledger_scope' => 'al_ghaith_grocery_matrix']
        ]);
    }
}

