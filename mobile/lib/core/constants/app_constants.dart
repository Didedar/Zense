class AppConstants {
  AppConstants._();

  static const List<String> expenseCategories = [
    'food',
    'transport',
    'entertainment',
    'shopping',
    'health',
    'education',
    'bills',
    'subscriptions',
    'gifts',
    'other',
  ];

  static const List<String> incomeSourceTypes = [
    'salary',
    'freelance',
    'allowance',
    'gift',
    'scholarship',
    'part_time',
    'other',
  ];

  static const List<String> segments = [
    'student',
    'freelancer',
    'part_time',
    'creator',
  ];

  static const List<String> spendingStyles = [
    'chaotic',
    'medium',
    'disciplined',
  ];

  static const List<String> goalCategories = [
    'savings',
    'gadget',
    'travel',
    'education',
    'fashion',
    'emergency',
    'custom',
  ];

  static const Map<String, String> categoryEmojis = {
    'food': '🍔',
    'transport': '🚕',
    'entertainment': '🎮',
    'shopping': '🛍️',
    'health': '💊',
    'education': '📚',
    'bills': '📄',
    'subscriptions': '📱',
    'gifts': '🎁',
    'other': '📌',
    'salary': '💼',
    'freelance': '💻',
    'allowance': '💰',
    'gift': '🎁',
    'scholarship': '🎓',
    'part_time': '⏰',
    'savings': '🏦',
    'gadget': '📱',
    'travel': '✈️',
    'fashion': '👗',
    'emergency': '🆘',
    'custom': '⭐',
  };
}
