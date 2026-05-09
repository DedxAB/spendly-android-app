class Money {
  static const int _scale = 100;

  static double normalize(num value) {
    return ((value * _scale).round()) / _scale;
  }

  static int toPaise(num value) {
    return (value * _scale).round();
  }

  static double fromPaise(int paise) {
    return paise / _scale;
  }

  static double? tryParse(String raw) {
    final parsed = double.tryParse(raw.trim());
    if (parsed == null) return null;
    return normalize(parsed);
  }
}
