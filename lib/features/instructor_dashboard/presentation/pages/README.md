# صفحات تفاصيل الدفع والسحب
# Payment & Withdrawal Details Pages

## الملفات / Files

### 1. `earning_details_screen.dart`
صفحة تعرض تفاصيل معاملة الدفع عند الضغط على كرت الربح.

Shows detailed payment transaction information when tapping on an earning card.

**المعلومات المعروضة / Displayed Information:**
- صافي الربح / Net Earnings
- رقم المعاملة / Transaction ID
- معرف المشتري / Buyer ID
- تاريخ ووقت الشراء / Purchase Date & Time
- معرف الكورس / Course ID
- تفاصيل المبلغ (السعر الأصلي، الخصم، العمولة) / Amount Breakdown
- الحالة والنوع / Status & Type

### 2. `withdraw_details_screen.dart`
صفحة تعرض تفاصيل طلب السحب عند الضغط على كرت السحب.

Shows detailed withdrawal request information when tapping on a withdrawal card.

**المعلومات المعروضة / Displayed Information:**
- مبلغ السحب / Withdrawal Amount
- رقم الطلب / Request ID
- طريقة السحب / Withdrawal Method
- تاريخ ووقت الطلب / Request Date & Time
- تاريخ المعالجة / Processed Date (if available)
- حالة الطلب / Request Status
- ملاحظات / Notes (if available)

## الاستخدام / Usage

الكروت في قائمة الأرباح والسحوبات أصبحت قابلة للضغط تلقائياً.

Cards in the earnings and withdrawals lists are now automatically tappable.

```dart
// في earnings_list_widgets.dart
// In earnings_list_widgets.dart

// EarningItem - يفتح earning_details_screen
// EarningItem - opens earning_details_screen
InkWell(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EarningDetailsScreen(earning: earning),
      ),
    );
  },
  // ...
)

// WithdrawItem - يفتح withdraw_details_screen
// WithdrawItem - opens withdraw_details_screen
InkWell(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawDetailsScreen(request: request),
      ),
    );
  },
  // ...
)
```

## الميزات / Features

✅ دعم اللغة العربية والإنجليزية / Arabic & English support
✅ دعم الوضع الداكن / Dark mode support
✅ تصميم متجاوب / Responsive design
✅ عرض جميع التفاصيل المهمة / Shows all important details
✅ ألوان مميزة حسب الحالة / Status-based color coding
✅ أيقونات واضحة / Clear icons
