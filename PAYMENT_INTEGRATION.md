# Payment Integration Guide

## Overview
تم دمج نظام الدفع الإلكتروني باستخدام Paymob في التطبيق بشكل كامل.

## Flow الدفع

### 1. إضافة الكورسات إلى السلة
- المستخدم يضيف الكورسات إلى السلة
- يتم حساب السعر النهائي مع الخصومات والكوبونات

### 2. Checkout
عند الضغط على "Pay":
1. يتم إنشاء `parent_enrollment` بحالة `pending`
2. يتم إنشاء `enrollments` لكل كورس بحالة `pending`
3. يتم إنشاء `instructor_earnings` بحالة `pending`

### 3. الدفع عبر Paymob
1. يتم الحصول على payment URL من Paymob
2. يتم فتح WebView لإتمام الدفع
3. المستخدم يدخل بيانات البطاقة ويدفع

### 4. تأكيد الدفع
عند نجاح الدفع:
1. يتم استدعاء `confirm_enrollment_payment` function
2. يتم تحديث `parent_enrollment.payment_status` إلى `paid`
3. يتم تحديث `enrollments.status` إلى `active`
4. يتم تحديث `instructor_earnings.status` إلى `pending`
5. يتم مسح السلة
6. يتم توجيه المستخدم إلى صفحة النجاح

### 5. في حالة الفشل
- يتم تحديث `parent_enrollment.payment_status` إلى `failed`
- الـ enrollments تبقى `pending`
- يمكن للمستخدم إعادة المحاولة

## Files Structure

```
lib/
├── features/
│   ├── payment/
│   │   ├── data/
│   │   │   └── services/
│   │   │       └── paymob_service.dart          # Paymob API integration
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       ├── payment_method.dart
│   │   │       ├── payment_result.dart
│   │   │       └── payment_status.dart
│   │   └── presentation/
│   │       └── widgets/
│   │           └── payment_webview.dart         # Payment WebView
│   │
│   ├── cart/
│   │   ├── data/
│   │   │   └── datasources/
│   │   │       ├── cart_remote_data_source.dart # Checkout logic
│   │   │       └── enrollment_payment_service.dart # Payment confirmation
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   └── checkout_cubit.dart          # Checkout state management
│   │       └── screens/
│   │           └── checkout_screen.dart         # Checkout UI
│   │
│   └── payments_history/                        # Payment history feature
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── core/
    └── config/
        └── paymob_config.dart                   # Paymob credentials
```

## Database Tables

### parent_enrollments
```sql
- id (UUID)
- user_id (UUID)
- total (DECIMAL)
- subtotal (DECIMAL)
- discount (DECIMAL)
- coupon_discount (DECIMAL)
- payment_method (TEXT)
- payment_status (TEXT) -- pending, paid, failed, refunded
- payment_transaction_id (TEXT)
- paid_at (TIMESTAMPTZ)
```

### enrollments
```sql
- id (UUID)
- user_id (UUID)
- course_id (UUID)
- parent_enrollment_id (UUID)
- status (TEXT) -- pending, active, completed
- price (DECIMAL)
```

### instructor_earnings
```sql
- id (UUID)
- instructor_id (UUID)
- enrollment_id (UUID)
- course_id (UUID)
- gross_amount (DECIMAL)
- platform_fee (DECIMAL)
- net_amount (DECIMAL)
- status (TEXT) -- pending, available, paid
```

## Database Functions

### confirm_enrollment_payment
```sql
CREATE OR REPLACE FUNCTION confirm_enrollment_payment(
  p_parent_enrollment_id UUID,
  p_transaction_id TEXT
)
```
يقوم بـ:
1. تحديث parent_enrollment إلى paid
2. تفعيل جميع enrollments
3. تحديث instructor_earnings

## Configuration

### Paymob Credentials
في `lib/core/config/paymob_config.dart`:
```dart
static const String apiKey = 'YOUR_API_KEY';
static const int integrationId = YOUR_INTEGRATION_ID;
static const int iFrameId = YOUR_IFRAME_ID;
static const int walletIntegrationId = YOUR_WALLET_INTEGRATION_ID;
```

## Testing

### Test Card Numbers (Paymob Sandbox)
- Success: 4987654321098769
- Declined: 4000000000000002
- CVV: Any 3 digits
- Expiry: Any future date

## Features

✅ Card payment via Paymob
✅ Payment confirmation
✅ Order tracking
✅ Payment history
✅ Instructor earnings calculation
✅ Coupon support
✅ Flash sale support
✅ Free courses support
⏳ Wallet payment (Vodafone Cash, etc.) - Coming soon

## Notes

- الدفع يتم عبر Paymob بشكل آمن
- جميع المعاملات مسجلة في قاعدة البيانات
- يمكن للمستخدم رؤية سجل مدفوعاته
- يتم حساب أرباح المدرسين تلقائياً
- الكورسات المجانية تفعل مباشرة بدون دفع
