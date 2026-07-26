class ApiEndpoints {
  // Base URL - change for production
  static const String baseUrl = 'http://76.13.17.86:3000/api/v1'; // VPS Server

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Accounts
  static const String accounts = '/accounts';
  static String reconcileAccount(String id) => '/accounts/$id/reconcile';
  static const String freshStart = '/accounts/fresh-start';

  // Envelopes & Pockets
  static const String envelopes = '/envelopes';
  static const String allocateEnvelopes = '/envelopes/allocate';
  static String pockets(String masterId) => '/envelopes/$masterId/pockets';

  // Transactions
  static const String transactions = '/transactions';
  static const String transactionIncome = '/transactions/income';
  static const String transactionExpense = '/transactions/expense';
  static const String transactionInbox = '/transactions/inbox';
  static String assignInbox(String id) => '/transactions/inbox/$id/assign';

  // Dashboard
  static const String dashboardSummary = '/dashboard/summary';

  // Journal
  static String journalMonthly(int year, int month) => '/journal/monthly/$year/$month';
  static String journalYearly(int year) => '/journal/yearly/$year';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';

  // Rules
  static const String sweepingRules = '/rules/sweeping';
  static const String categorizationRules = '/rules/categorization';
}
