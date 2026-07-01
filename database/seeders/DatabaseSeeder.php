<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // هنا نخبر لارافيل بتشغيل مصفوفة بيانات Hussam Core AI تلقائياً
        $this->call(CoreSystemSeeder::class);
    }
}
