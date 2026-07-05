<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Tenancy configuration
    |--------------------------------------------------------------------------
    |
    | This file defines the tenancy defaults used by the application. The
    | header name is used by TenantMiddleware to resolve the tenant for each
    | incoming request. TENANCY_STRATEGY controls whether Postgres schemas
    | (schema) or separate databases (database) are used.
    |
    */

    'tenant_header' => env('TENANT_HEADER', 'X-Tenant-ID'),

    'default_tenant_code' => env('DEFAULT_TENANT_CODE', null),

    'strategy' => env('TENANCY_STRATEGY', 'schema'),
];
