enum TransactionType { income, expense }

enum PaymentMode { cash, upi, card }

enum AppThemeMode { system, light, dark }

enum RecurringFrequency { weekly, monthly, yearly }

extension TransactionTypeX on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
    }
  }

  static TransactionType fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
      default:
        return TransactionType.expense;
    }
  }
}

extension PaymentModeX on PaymentMode {
  String get value {
    switch (this) {
      case PaymentMode.cash:
        return 'cash';
      case PaymentMode.upi:
        return 'upi';
      case PaymentMode.card:
        return 'card';
    }
  }

  static PaymentMode fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'upi':
        return PaymentMode.upi;
      case 'card':
        return PaymentMode.card;
      case 'cash':
      default:
        return PaymentMode.cash;
    }
  }
}

extension AppThemeModeX on AppThemeMode {
  String get value {
    switch (this) {
      case AppThemeMode.system:
        return 'system';
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
    }
  }

  static AppThemeMode fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }
}

extension RecurringFrequencyX on RecurringFrequency {
  String get value {
    switch (this) {
      case RecurringFrequency.weekly:
        return 'weekly';
      case RecurringFrequency.monthly:
        return 'monthly';
      case RecurringFrequency.yearly:
        return 'yearly';
    }
  }

  static RecurringFrequency fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'weekly':
        return RecurringFrequency.weekly;
      case 'yearly':
        return RecurringFrequency.yearly;
      case 'monthly':
      default:
        return RecurringFrequency.monthly;
    }
  }
}
