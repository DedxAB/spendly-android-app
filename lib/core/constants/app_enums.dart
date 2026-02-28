enum TransactionType { income, expense }

enum PaymentMode { cash, upi, card }

enum AppThemeMode { system, light, dark }

extension TransactionTypeX on TransactionType {
  String get value => name;

  static TransactionType fromValue(String value) {
    return TransactionType.values.firstWhere(
      (element) => element.name == value,
      orElse: () => TransactionType.expense,
    );
  }
}

extension PaymentModeX on PaymentMode {
  String get value => name;

  static PaymentMode fromValue(String value) {
    return PaymentMode.values.firstWhere(
      (element) => element.name == value,
      orElse: () => PaymentMode.cash,
    );
  }
}

extension AppThemeModeX on AppThemeMode {
  String get value => name;

  static AppThemeMode fromValue(String value) {
    return AppThemeMode.values.firstWhere(
      (element) => element.name == value,
      orElse: () => AppThemeMode.system,
    );
  }
}

