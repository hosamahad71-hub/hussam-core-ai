-- سكريبت إنشاء الهيكل السحابي السيادي لمنصة حسام لخدمة اليمنيين
-- قم بنسخ هذا الكود ولصقه في Supabase SQL Editor

-- 1. إنشاء جدول المنتجات والمشروعات اللوجستية
CREATE TABLE IF NOT EXISTS public.products (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT EXISTS NOT NULL,
    price NUMERIC NOT NULL,
    description TEXT,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. تفعيل الحماية والأمان على مستوى الصفوف (Row Level Security)
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- 3. فتح سياسة القراءة العامة للبيانات لتمكين كل مواطن يمني من التصفح الحي
CREATE POLICY "Allow Public Read Access" 
ON public.products 
FOR SELECT 
USING (true);

-- 4. حقن البيانات التأسيسية الفاخرة لتظهر فوراً عند الاتصال بقاعدة البيانات
INSERT INTO public.products (name, price, description, is_available)
VALUES 
('بوابة عدن الرقمية', 250.0, 'بوابة سيادية ذكية حرة', true),
('حزمة صنعاء اللوجستية', 420.0, 'إدارة سلاسل الإمداد الموحدة', true),
('مستودع تعز السيادي', 180.0, 'نظام إدارة التخزين الذكي الأمني', true),
('شريان حضرموت الذكي', 590.0, 'منظومة الربط السحابي والتدفق الحي', true)
ON CONFLICT DO NOTHING;
