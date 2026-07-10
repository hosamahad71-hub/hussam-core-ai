#!/bin/bash

# =============================================================================
# ENGINE: Hussam Core AI Platform v1.0 - Deep System Audit Script
# PURPOSE: Forensic code analysis, security auditing, & placeholder tracking.
# REGION: Taiz, Yemen (Local Sandbox Environment)
# =============================================================================

# الألوان لتنسيق مخرجات الفحص في الطرفية (Terminal)
RED='\0033[0;31m'
GREEN='\0033[0;32m'
YELLOW='\0033[0;33m'
BLUE='\0033[0;34m'
CYAN='\0033[0;36m'
NC='\0033[0m' # No Color
BOLD='\0033[1m'

echo -e "${CYAN}${BOLD}====================================================================${NC}"
echo -e "${BLUE}${BOLD}      محرك الفحص الجنائي العميق - المنصة الوطنية اليمنية (Hussam Core)      ${NC}"
echo -e "${CYAN}${BOLD}====================================================================${NC}"
echo -e "${YELLOW}تاريخ الفحص: $(date) | البيئة: محاكاة محلية (Sandbox)${NC}\n"

# -----------------------------------------------------------------------------
# 1. فحص هيكلية النطاقات وعزل مساحات الأسماء (Namespace Isolation)
# -----------------------------------------------------------------------------
echo -e "${BOLD}[1/4] فحص معمارية النطاقات وعزل البيانات (Tenancy & Isolation)...${NC}"

TOTAL_MODELS=0
SECURE_MODELS=0

if [ -d "backend/app/Models" ]; then
    MODELS=$(ls backend/app/Models/*.php 2>/dev/null)
    for model in $MODELS; do
        ((TOTAL_MODELS++))
        # التحقق مما إذا كان الموديل يحتوي على حقل المستأجر أو سكوب العزل
        if grep -q "tenant_id" "$model" || grep -q "BelongsToTenant" "$model"; then
            ((SECURE_MODELS++))
        fi
    done
    echo -e "  ├── إجمالي موديلات البيانات المكتشفة: ${CYAN}$TOTAL_MODELS${NC}"
    echo -e "  └── الموديلات المحصنة بعزل المستأجر (tenant_id): ${GREEN}$SECURE_MODELS${NC}"
    
    if [ "$TOTAL_MODELS" -ne "$SECURE_MODELS" ]; then
        echo -e "  ${RED}⚠️ تحذير معماري: هناك موديلات لا تفرض عزل المستأجر برمجياً!${NC}"
    fi
else
    echo -e "  ${RED}❌ خطأ: مجلد الموديلات غير موجود أو فارغ!${NC}"
fi

echo ""

# -----------------------------------------------------------------------------
# 2. تدقيق عقود قاعدة البيانات وحصانة الحتمية (Idempotency Audit)
# -----------------------------------------------------------------------------
echo -e "${BOLD}[2/4] تدقيق عقود الجداول وحصانة الحتمية ضد تكرار العمليات (Idempotency Key)...${NC}"

MIGRATION_DIR="backend/database/migrations"
if [ -d "$MIGRATION_DIR" ]; then
    # التحقق من القيد الفريد لمنع التكرار في جدول السجلات المزامنة
    IDEMPOTENCY_CHECK=$(grep -rn "UNIQUE.*tenant_id.*request_id" "$MIGRATION_DIR" 2>/dev/null)
    
    if [ -n "$IDEMPOTENCY_CHECK" ]; then
        echo -e "  ├── ${GREEN}✓ قيد الحتمية الفريد UNIQUE(tenant_id, request_id) مفعل ومكتشف!${NC}"
        echo -e "  └── الملف المسؤول: ${CYAN}$IDEMPOTENCY_CHECK${NC}"
    else
        echo -e "  └── ${RED}❌ ثغرة حتمية: لم يتم العثور على قيد الحظر الثنائي لمنع تكرار القيود المالية!${NC}"
    fi
    
    # فحص القيود المالية غير القابلة للتعديل (Ledger Immutability)
    if grep -rnq "create_ledger_transactions_table" "$MIGRATION_DIR"; then
        echo -e "  ├── ${GREEN}✓ دفتر القيد المالي المزدوج (Ledger) موجود في قواعد المهاجرة.${NC}"
    else
        echo -e "  ├── ${YELLOW}⚠️ تنبيه: لم يتم التحقق من حظر الحذف (SoftDeletes Only) في جداول الحسابات.${NC}"
    fi
else
    echo -e "  ${RED}❌ خطأ: مجلد المهاجرات (Migrations) غير موجود!${NC}"
fi

echo ""

# -----------------------------------------------------------------------------
# 3. تتبع وفحص الـ Placeholders (الحوافظ المؤقتة والوظائف الفارغة)
# -----------------------------------------------------------------------------
echo -e "${BOLD}[3/4] مسح وتتبع الـ Placeholders والوظائف الفارغة (TODOs / Fixmes)...${NC}"

TODO_COUNT=$(grep -rn "TODO" backend/app/ 2>/dev/null | wc -l)
FIXME_COUNT=$(grep -rn "FIXME" backend/app/ 2>/dev/null | wc -l)
PLACEHOLDER_FILES=$(grep -rn "PLACEHOLDER" backend/ 2>/dev/null | wc -l)

echo -e "  ├── علامات التطوير المعلقة (TODO): ${YELLOW}$TODO_COUNT${NC}"
echo -e "  ├── ثغرات حرجة تتطلب إصلاح عاجل (FIXME): ${RED}$FIXME_COUNT${NC}"
echo -e "  └── الملفات المحفوظة مؤقتاً (Placeholders): ${CYAN}$PLACEHOLDER_FILES${NC}"

# حساب تقريبي لنسبة جاهزية النواة استناداً إلى الكود الفعلي مقابل الحوافظ
if [ "$TODO_COUNT" -gt 0 ]; then
    READY_PERCENT=$(( 100 - (TODO_COUNT * 2) ))
    if [ "$READY_PERCENT" -lt 30 ]; then READY_PERCENT=30; fi
else
    READY_PERCENT=100
fi
echo -e "  └── ${BOLD}نسبة الجاهزية التقديرية لنواة النظام الفعلي: ${GREEN}$READY_PERCENT%${NC}"

echo ""

# -----------------------------------------------------------------------------
# 4. فحص تكامل جانب العميل (Flutter Client Sync Verification)
# -----------------------------------------------------------------------------
echo -e "${BOLD}[4/4] مراجعة معمارية العميل (Flutter Client Integrity)...${NC}"

if [ -d "flutter_client" ]; then
    if grep -rnq "IdempotencyManager" flutter_client/ 2>/dev/null; then
        echo -e "  └── ${GREEN}✓ تم التحقق: مدير الحتمية (Idempotency Manager) مدمج في طلبات هاتف العميل.${NC}"
    else
        echo -e "  └── ${YELLOW}⚠️ تنبيه: لم يتم العثور على حقن تلقائي للـ request_id في واجهات الـ BLoC.${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠️ تنبيه: مجلد flutter_client غير متوفر في المسار الحالي للمحاكاة.${NC}"
fi

echo -e "\n${CYAN}${BOLD}====================================================================${NC}"
echo -e "${GREEN}${BOLD}                     انتهى تقرير الفحص الجنائي الموحد                    ${NC}"
echo -e "${CYAN}${BOLD}====================================================================${NC}"
