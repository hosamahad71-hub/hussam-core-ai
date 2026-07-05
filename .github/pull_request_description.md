### Summary

This PR hardens our core platform foundation across database, backend, client, and testing layers to improve correctness, security, and operational reliability.

### Changes
- Database: Added a UNIQUE(tenant_id, request_id) constraint to the ai_logs table to enforce idempotency at the database level. This ensures duplicate sync payloads cannot create repeated AI log entries for the same tenant.

- Backend: Hardened SyncController to enforce strict tenant-binding (validating the authenticated user belongs to the resolved tenant) and switched to `insertOrIgnore` for idempotent inserts. This makes the /api/sync endpoint resilient to retries and cross-tenant attacks.

- Flutter: Implemented a secure and robust API client (`flutter_client/lib/core/network/api_client.dart`) which fail-fast when credentials are missing, performs single-flight token refreshes to prevent concurrent refresh storms, and limits automatic retries to idempotent requests or requests carrying an idempotency/request_id key.

- Testing: Added PHPUnit tests in `tests/Feature/SyncControllerTest.php` covering authentication requirements, tenant isolation, and idempotency behavior to prevent regressions.

### Migration and testing notes
- Before running `php artisan migrate`, ensure the `ai_logs` table already contains `tenant_id` and `request_id` columns; otherwise update the migration to add the missing columns first.
- After merging run:
  - `php artisan migrate`
  - `./vendor/bin/phpunit --filter SyncControllerTest`

### Risks
- The migration will fail if the `ai_logs` schema does not match the expected columns. Review the migration prior to running in production.

### Rollout
- Merge into `main` and deploy backend migrations as part of your usual release process. The Flutter client change is backward compatible but requires wiring `tokenProvider`/`tokenRefresher` and `tenantIdProvider` in the app.
