<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Route;
use App\Repositories\TenantRepository;
use App\Repositories\AccountRepository;
use App\Http\Middleware\TenantMiddleware;

class TenancyServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     *
     * @return void
     */
    public function register()
    {
        // Bind repository concrete classes (they already exist in repo)
        $this->app->singleton(TenantRepository::class, function ($app) {
            return new TenantRepository($app->make('cache.store'));
        });

        $this->app->singleton(AccountRepository::class, function ($app) {
            // Provide a simple AccountRepository stub if not present
            return new \App\Repositories\AccountRepository($app->make('cache.store'));
        });
    }

    /**
     * Bootstrap services.
     *
     * @return void
     */
    public function boot()
    {
        // Alias middleware so it can be used in routes/kernel
        if ($this->app->bound('router')) {
            $this->app['router']->aliasMiddleware('tenant', TenantMiddleware::class);
        }
    }
}
