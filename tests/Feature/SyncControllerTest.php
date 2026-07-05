<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use App\Models\User;

class SyncControllerTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function sync_without_x_tenant_id_is_rejected()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user, ['*']);

        $payload = [
            'items' => [
                [
                    'request_id' => (string) Str::uuid(),
                    'model' => 'gpt-test',
                    'prompt' => 'no tenant header',
                ]
            ]
        ];

        $response = $this->postJson('/api/sync', $payload);

        $response->assertStatus(404);
        $response->assertJson(['error' => 'Tenant not resolved']);
    }

    /** @test */
    public function user_from_tenant_a_cannot_sync_into_tenant_b()
    {
        $tenantAId = (string) Str::uuid();
        DB::table('tenants')->insert([
            'id' => $tenantAId,
            'code' => 'tenant-a',
            'name' => 'Tenant A',
            'region' => 'XX',
            'metadata' => json_encode(['active' => true]),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $tenantBId = (string) Str::uuid();
        DB::table('tenants')->insert([
            'id' => $tenantBId,
            'code' => 'tenant-b',
            'name' => 'Tenant B',
            'region' => 'XX',
            'metadata' => json_encode(['active' => true]),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $user = User::factory()->create([
            'tenant_id' => $tenantAId,
        ]);

        Sanctum::actingAs($user, ['*']);

        $payload = [
            'items' => [
                [
                    'request_id' => (string) Str::uuid(),
                    'model' => 'gpt-test',
                    'prompt' => 'attempt cross-tenant write',
                ]
            ]
        ];

        $response = $this->postJson('/api/sync', $payload, ['X-Tenant-ID' => $tenantBId]);

        $response->assertStatus(403);
        $response->assertJson(['error' => 'User not authorized for tenant']);
    }

    /** @test */
    public function successful_sync_with_request_id_creates_log()
    {
        $tenantId = (string) Str::uuid();
        DB::table('tenants')->insert([
            'id' => $tenantId,
            'code' => 'tenant-success',
            'name' => 'Tenant Success',
            'region' => 'YY',
            'metadata' => json_encode(['active' => true]),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $user = User::factory()->create([
            'tenant_id' => $tenantId,
        ]);

        Sanctum::actingAs($user, ['*']);

        $rid = (string) Str::uuid();
        $payload = [
            'items' => [
                [
                    'request_id' => $rid,
                    'model' => 'gpt-test',
                    'prompt' => 'successful sync record',
                    'response' => ['ok' => true],
                ]
            ]
        ];

        $response = $this->postJson('/api/sync', $payload, ['X-Tenant-ID' => $tenantId]);

        $response->assertStatus(200);
        $response->assertJsonStructure(['results']);
        $this->assertDatabaseHas('ai_logs', [
            'request_id' => $rid,
            'tenant_id' => $tenantId,
        ]);
    }
}
