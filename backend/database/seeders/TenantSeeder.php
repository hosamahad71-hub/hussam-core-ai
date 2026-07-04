<?php
namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Tenant;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;

class TenantSeeder extends Seeder
{
    /**
     * Seed initial national tenants and sectors for the Hussam platform.
     *
     * The seeder creates a default 'hussam' management tenant and several sector tenants:
     *  - commerce (national commerce marketplace)
     *  - logistics (national logistic network)
     *  - industrial (industrial manufacturing / supply)
     *  - regional-commerce (regional commerce aggregator)
     *
     * Each tenant receives realistic metadata including allowed_sectors, region codes, and default settings.
     */
    public function run()
    {
        // Common timestamp for seeded records for determinism
        $now = now();

        // Management/Platform tenant
        Tenant::updateOrCreate(
            ['code' => 'hussam'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'Hussam National Platform',
                'region' => 'YE',
                'metadata' => [
                    'active' => true,
                    'allowed_sectors' => ['commerce', 'logistics', 'industrial', 'regional-commerce'],
                    'description' => 'Platform-level tenant for national orchestration and admin.',
                    'created_by' => 'system-seeder',
                    'settings' => [
                        'billing_provider' => 'internal',
                        'ai_model_default' => 'gpt-4',
                    ],
                ],
                'created_at' => $now,
                'updated_at' => $now,
            ]
        );

        // Commerce tenant
        Tenant::updateOrCreate(
            ['code' => 'commerce'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'National Commerce',
                'region' => 'YE',
                'metadata' => [
                    'active' => true,
                    'allowed_sectors' => ['commerce'],
                    'description' => 'E-commerce marketplace across Yemeni regions.',
                    'pricing' => ['currency' => 'YER', 'commission' => 0.025],
                    'settings' => ['max_listings_per_merchant' => 5000],
                ],
                'created_at' => $now,
                'updated_at' => $now,
            ]
        );

        // Logistics tenant
        Tenant::updateOrCreate(
            ['code' => 'logistics'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'National Logistics',
                'region' => 'YE',
                'metadata' => [
                    'active' => true,
                    'allowed_sectors' => ['logistics', 'commerce'],
                    'description' => 'Logistics and delivery network supporting commerce.',
                    'settings' => ['max_vehicle_capacity' => 1000, 'sla_hours' => 72],
                ],
                'created_at' => $now,
                'updated_at' => $now,
            ]
        );

        // Industrial tenant
        Tenant::updateOrCreate(
            ['code' => 'industrial'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'Industrial Sector',
                'region' => 'YE',
                'metadata' => [
                    'active' => true,
                    'allowed_sectors' => ['industrial'],
                    'description' => 'Industrial manufacturers and B2B supply chain.',
                    'settings' => ['default_payment_terms_days' => 30],
                ],
                'created_at' => $now,
                'updated_at' => $now,
            ]
        );

        // Regional commerce aggregator (example: southern region)
        Tenant::updateOrCreate(
            ['code' => 'regional-commerce'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'Regional Commerce Aggregator',
                'region' => 'YE-South',
                'metadata' => [
                    'active' => true,
                    'allowed_sectors' => ['regional-commerce', 'commerce'],
                    'description' => 'Aggregation and routing for the southern economic region.',
                    'settings' => ['region_focus' => 'south'],
                ],
                'created_at' => $now,
                'updated_at' => $now,
            ]
        );

        // Optional: seed tenant settings entries if table exists
        if (DB::getSchemaBuilder()->hasTable('tenant_settings')) {
            $defaults = [
                ['tenant_code' => 'hussam', 'key' => 'ui.theme', 'value' => json_encode(['color' => 'green', 'logo' => null])],
                ['tenant_code' => 'commerce', 'key' => 'pricing.commission', 'value' => json_encode(0.025)],
            ];

            foreach ($defaults as $d) {
                $tenant = Tenant::where('code', $d['tenant_code'])->first();
                if ($tenant) {
                    DB::table('tenant_settings')->updateOrInsert(
                        ['tenant_id' => $tenant->id, 'key' => $d['key']],
                        ['value' => $d['value'], 'created_at' => now(), 'updated_at' => now()]
                    );
                }
            }
        }
    }
}
