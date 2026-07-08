# ======================================================================
# HUS SPECIFICATION LANGUAGE — OFFICIAL KEYWORDS Lexicon
# Version: 3.3
# Mode: DETERMINISTIC | State: STATELESS
# Status: Approved & Enforced
# ======================================================================

## 1. CORE STRUCTURAL TOKENS (الكلمات البنائية النواتية)
- `platform_constitution`: الكلمة الحاكمة لاستدعاء الدستور البرمجي الأعلى للمنصة.
- `bounded_context`: محدد مساحة الاسم والسياق المغلق المعزول (Namespace).
- `aggregate`: معرف حدود الاتساق والعمليات المشتركة للكيانات.
- `entity`: تعريف كائن تشغيلي يمتلك دورة حياة ومعرف فريد.
- `value_object`: تعريف كائن قيمة مجهول الهوية بالكامل ومحمي ضد حقول المعرفات.

## 2. SECURITY & ISOLATION TOKENS (كلمات الأمن والعزل السيادي)
- `tenant_id`: المعرف الإجباري الحتمي (UUID) لعزل بيانات المستأجرين في كل كيان تشغيلي.
- `namespace`: الكلمة المفتاحية لتحديد النطاق البرمجي الحاد لمنع التسريب البرمجي.
- `contract`: القناة الوحيدة المسموحة للاستدعاءات المتزامنة بين السياقات المختلفة.
- `domain_event`: الحدث السيادي الحاكم للاستدعاءات غير المتزامنة عبر المنصة.

## 3. FINANCIAL LEDGER TOKENS (كلمات الدفتر المالي الحتمي)
- `immutable_ledger`: تفعيل استراتيجية سجل القيد المزدوج غير القابل للتعديل أو الحذف.
- `double_entry`: فرض التوازن الميكانيكي الصارم بين المدين والدائن.
- `debit`: سجل الزيادة في الأصول / المصاريف المالية.
- `credit`: سجل الزيادة في الالتزامات / الإيرادات المالية.

## 4. IDEMPOTENCY & PIPELINE TOKENS (كلمات حتمية التنفيذ ومنع التكرار)
- `request_id`: المعرف الفريد الإجباري لكل معاملة تقنية أو مالية داخل `ai_logs`.
- `insert_or_ignore`: التعليمية الميكانيكية الصارمة لمنع تكرار القيود في قاعدة البيانات.
- `backend_first`: قيادة التطوير من الخلفية (Laravel) وفرض قيود التحقق قبل واجهات Flutter.

## 5. COMPILER ENFORCEMENT LAW (قانون المترجم للكلمات غير المعرفة)
- Any unmapped token or custom identifier passing through the lexer that conflicts with or duplicates these reserved keywords, or any token outside the approved schema, must instantly halt the compilation pipeline with error code: `HUS_ERR_COMPILER_UNKNOWN_KEYWORD`.

