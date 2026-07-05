<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\Tenant;
use App\Models\User;

class SyncTest extends TestCase
{
    use RefreshDatabase;

    public function test_sync_requires_tenant()
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $res = $this->withHeader('Authorization', 'Bearer ' . $token)
                    ->postJson('/api/v1/sync');

        $res->assertStatus(404);
    }
}
