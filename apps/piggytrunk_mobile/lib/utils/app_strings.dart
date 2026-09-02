import 'package:flutter/material.dart';
import '../services/locale_provider.dart';

class AppStrings {
  final String locale;

  AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    final loc = SettingsProvider.of(context)?.currentLocale ?? 'en';
    return AppStrings(loc);
  }

  bool get isFilipino => locale == 'fil';

  // ================= Common / Navigation =================
  String get dashboard => isFilipino ? 'Dashboard' : 'Dashboard';
  String get request => isFilipino ? 'Kahilingan' : 'Request';
  String get hogs => isFilipino ? 'Mga Baboy' : 'Hogs';
  String get profile => isFilipino ? 'Profile' : 'Profile';
  String get signOut => isFilipino ? 'Mag-sign Out' : 'Sign Out';
  String get cancel => isFilipino ? 'Kanselahin' : 'Cancel';
  String get confirm => isFilipino ? 'Kumpirmahin' : 'Confirm';
  String get edit => isFilipino ? 'I-edit' : 'Edit';
  String get reset => isFilipino ? 'I-reset' : 'Reset';
  String get close => isFilipino ? 'Isara' : 'Close';
  String get save => isFilipino ? 'I-save' : 'Save';
  String get viewAll => isFilipino ? 'Tingnan Lahat' : 'View All';
  String get viewBreakdown => isFilipino ? 'Tingnan ang Detalye' : 'View Breakdown';

  // ================= Bottom Navigation Bar (Constant English) =================
  String get navDashboard => 'DASHBOARD';
  String get navRequest => 'REQUEST';
  String get navHogs => 'HOGS';
  String get navProfile => 'PROFILE';
  String get navHome => 'HOME';
  String get navInventory => 'INVENTORY';
  String get navPOS => 'POS';

  // ================= Dashboard / Home Tab =================
  String get helloGreeting => isFilipino ? 'Kumusta Tagapag-alaga,' : 'Hello Hog Raiser,';
  String get totalCurrentInvestment => isFilipino ? 'KABUUANG KASALUKUYANG PUHUNAN' : 'TOTAL CURRENT INVESTMENT';
  String get initialCapital => isFilipino ? 'Paunang Puhunan' : 'Initial Capital';
  String get stockRequestsSpend => isFilipino ? 'Mga Kahilingan sa Stock' : 'Stock Requests';
  String get activeBatch => isFilipino ? 'Aktibong Batch' : 'Active Batch';
  String get quickSummary => isFilipino ? 'Mabilisang Buod' : 'Quick Summary';
  String get totalHogs => isFilipino ? 'Kabuuang Baboy' : 'Total Hogs';
  String get healthy => isFilipino ? 'Malusog' : 'Healthy';
  String get underCare => isFilipino ? 'Nasa Pag-aalaga' : 'Under Care';
  String get pendingRequests => isFilipino ? 'Nakabinbing Kahilingan' : 'Pending Requests';
  String get hogBatchProgress => isFilipino ? 'Progreso ng Batch' : 'Hog Batch Progress';
  String get recentStockRequests => isFilipino ? 'Kamakailang Kahilingan' : 'Recent Stock Requests';
  String get noStockRequestsYet => isFilipino ? 'Wala pang kahilingan sa stock.' : 'No stock requests yet.';
  String get noActiveBatchNotice => isFilipino ? 'Wala pang aktibong batch na nakatalaga.' : 'No active batch assigned yet.';
  String get investmentBreakdownTitle => isFilipino ? 'Detalye ng Puhunan' : 'Investment Breakdown';

  // ================= Stock Requests Tab =================
  String get stockRequestsTitle => isFilipino ? 'Mga Kahilingan sa Stock' : 'Stock Requests';
  String get stockRequestsSubtitle => isFilipino ? 'Subaybayan at pamahalaan ang iyong mga kahilingan sa pakain at gamot' : 'Track and manage your feeds, medicines, and equipment requests';
  String get newRequestButton => isFilipino ? '+ Humiling' : '+ Request';
  String get requestHistory => isFilipino ? 'Kasaysayan' : 'History';
  String get newStockRequest => isFilipino ? 'Bagong Kahilingan' : 'New Stock Request';
  String get searchRequests => isFilipino ? 'Maghanap ng kahilingan...' : 'Search requests...';
  String get selectProduct => isFilipino ? 'Pumili ng Produkto' : 'Select Product';
  String get quantity => isFilipino ? 'Dami' : 'Quantity';
  String get notesOrReason => isFilipino ? 'Mga Tala / Dahilan' : 'Notes / Reason';
  String get submitRequest => isFilipino ? 'Isumite ang Kahilingan' : 'Submit Request';
  String get filterAll => isFilipino ? 'Lahat' : 'All';
  String get filterPending => isFilipino ? 'Nakabinbin' : 'Pending';
  String get filterApproved => isFilipino ? 'Aprubado' : 'Approved';
  String get filterDistributed => isFilipino ? 'Naipamahagi' : 'Distributed';
  String get filterRejected => isFilipino ? 'Tinanggihan' : 'Rejected';

  // ================= Notifications Drawer =================
  String get notificationsTitle => isFilipino ? 'Mga Notification' : 'Notifications';
  String get notificationsSubtitle => isFilipino ? 'Mga update sa farm at requests' : 'Live updates and alerts';
  String get markAllRead => isFilipino ? 'Mark read' : 'Mark read';
  String get noNotifications => isFilipino ? 'Walang Notipikasyon' : 'No Notifications';
  String get noNotificationsSubtitle => isFilipino ? 'Lalabas dito ang mga bagong update.' : 'You\'re all caught up! New updates will show here.';

  // ================= Hogs Tab & Reports =================
  String get myHogsTitle => isFilipino ? 'Aking mga Baboy' : 'My Hogs';
  String get myHogsSubtitle => isFilipino ? 'Subaybayan ang kalusugan ng mga alaga' : 'Monitor daily health and status';
  String get healthReportsActivity => isFilipino ? 'Mga Ulat sa Kalusugan' : 'Health Reports Activity';
  String get addReportButton => isFilipino ? '+ Mag-ulat' : '+ Add Report';
  String get submitReportButton => isFilipino ? '+ Magsumite ng Ulat' : '+ Submit Report';
  String get searchHog => isFilipino ? 'Maghanap ng tag number...' : 'Search tag number...';
  String get statusHealthy => isFilipino ? 'Malusog' : 'Healthy';
  String get statusSick => isFilipino ? 'May Sakit' : 'Sick';
  String get statusObservation => isFilipino ? 'Obserbasyon' : 'Under Observation';
  String get statusQuarantine => isFilipino ? 'Kuwarentenas' : 'Quarantine';
  String get statusDeceased => isFilipino ? 'Namatay' : 'Deceased';
  String get statusSold => isFilipino ? 'Naibenta' : 'Sold';
  String get noHogsFound => isFilipino ? 'Walang nahanap na baboy.' : 'No hogs found.';
  String get noHogsSubtitle => isFilipino ? 'Walang nakatalagang baboy sa batch.' : 'No hogs assigned to this batch.';
  String get noHealthReports => isFilipino ? 'Walang ulat sa kalusugan.' : 'No health reports yet.';
  String get noHealthReportsSubtitle => isFilipino ? 'Lahat ng alaga ay malusog.' : 'All hogs are in healthy condition.';

  // ================= Cashier Module Strings =================
  String get cashierGreeting => isFilipino ? 'Kumusta Kahera,' : 'Hello Cashier,';
  String get cashierRole => isFilipino ? 'Staff ng Tindahan / POS' : 'Cashier Staff';
  String get todaySales => isFilipino ? 'Kabuuang Benta Ngayong Araw' : 'Today\'s Total Sales';
  String get todayTransactions => isFilipino ? 'Mga Transaksyon' : 'Transactions';
  String get inStockItems => isFilipino ? 'May Stock na Item' : 'In Stock Items';
  String get lowStockAlerts => isFilipino ? 'Babala sa Mababang Stock' : 'Low Stock Alerts';
  String get pendingHogRequests => isFilipino ? 'Nakabinbing Kahilingan' : 'Pending Requests';
  String get quickActions => isFilipino ? 'Mabilisang Aksyon' : 'Quick Actions';
  String get openPOS => isFilipino ? 'Buksan ang POS' : 'Open POS';
  String get stockAllocation => isFilipino ? 'Pamamahagi ng Stock' : 'Stock Allocation';
  String get manageInventory => isFilipino ? 'Pamahalaan ang Imbentaryo' : 'Manage Inventory';
  String get fastMovingProducts => isFilipino ? 'Mabilis Mabentang Produkto' : 'Fast-Moving Products';
  String get recentSalesActivity => isFilipino ? 'Kamakailang Benta' : 'Recent Sales Activity';
  String get viewAllSales => isFilipino ? 'Tingnan Lahat ng Resibo' : 'View All Receipts';
  String get inventoryTitle => isFilipino ? 'Imbentaryo ng Tindahan' : 'Store Inventory';
  String get inventorySubtitle => isFilipino ? 'Subaybayan at pamahalaan ang mga stock' : 'Track and manage supplies & feeds';
  String get posRegister => isFilipino ? 'Punto ng Pagbenta (POS)' : 'Point of Sale (POS)';
  String get searchProducts => isFilipino ? 'Maghanap ng produkto...' : 'Search products by name or category...';
  String get cartSummary => isFilipino ? 'Buod ng Cart' : 'Cart Summary';
  String get checkout => isFilipino ? 'Magbayad' : 'Checkout';
  String get clearCart => isFilipino ? 'Linisin ang Cart' : 'Clear Cart';
  String get emptyCart => isFilipino ? 'Walang laman ang cart' : 'Your cart is empty';
  String get addToCart => isFilipino ? 'Idagdag sa Cart' : 'Add to Cart';

  // ================= Profile Tab =================
  String get hogRaiserRole => isFilipino ? 'Tagapag-alaga' : 'Hog Raiser';
  String get accountDetails => isFilipino ? 'Impormasyon ng Account' : 'Account Details';
  String get emailAddress => isFilipino ? 'Email Address' : 'Email Address';
  String get phoneNumber => isFilipino ? 'Numero ng Telepono' : 'Phone Number';
  String get farmAddress => isFilipino ? 'Address ng Bukid' : 'Farm Address';
  String get branchAddress => isFilipino ? 'Address ng Tindahan / Sangay' : 'Store / Branch Address';
  String get pigTypeAssignment => isFilipino ? 'Uri ng Alagang Baboy' : 'Pig Type Assignment';
  String get currentFeedsStage => isFilipino ? 'Kasalukuyang Stage ng Pagkain' : 'Current Feeds Stage';
  String get systemAccess => isFilipino ? 'Antas sa Sistema' : 'System Access';
  String get accountStatus => isFilipino ? 'Katayuan ng Account' : 'Account Status';
  String get activeStatus => isFilipino ? 'Aktibo' : 'Active';
  String get unassigned => isFilipino ? 'Hindi pa naitatalaga' : 'Unassigned';
  String get notSet => isFilipino ? 'Hindi nakatakda' : 'Not set';

  // ================= Settings / Language =================
  String get settings => isFilipino ? 'Mga Setting' : 'Settings';
  String get languagePreference => isFilipino ? 'Piniling Wika' : 'Language Preference';
  String get languageSubtitle => isFilipino ? 'Piliin ang nais mong wika sa app' : 'Choose your preferred app language';
  String get english => 'English';
  String get filipino => 'Filipino';

  // ================= Partner Investor Module Strings =================
  String get partnerGreeting => isFilipino ? 'Kumusta Kasosyo,' : 'Hello Partner Investor,';
  String get partnerRole => isFilipino ? 'Kasosyong Mamumuhunan' : 'Partner Investor';
  String get portfolioOverview => isFilipino ? 'Portfolio' : 'Portfolio Overview';
  String get totalInvested => isFilipino ? 'KABUUANG NAIPUHUNAN' : 'TOTAL INVESTED';
  String get activeProjects => isFilipino ? 'MGA AKTIBONG PROYEKTO' : 'ACTIVE PROJECTS';
  String get activeRaisers => isFilipino ? 'Aktibong Tagapag-alaga' : 'Active Raisers';
  String get hogsFunded => isFilipino ? 'Pinondohang Baboy' : 'Hogs Funded';
  String get browseOpportunities => isFilipino ? 'Mag-browse ng Oportunidad' : 'Browse Opportunities';
  String get recentActivities => isFilipino ? 'Kamakailang Aktibidad' : 'Recent Activities';
  String get seeAll => isFilipino ? 'Tingnan Lahat' : 'See All';
  String get noActivitiesYet => isFilipino ? 'Wala pang naitalang aktibidad.' : 'No activities recorded yet.';
  String get investmentOpportunities => isFilipino ? 'Mga Oportunidad sa Puhunan' : 'Investment Opportunities';
  String get availableBatchesSubtitle => isFilipino ? 'Tingnan at pondohan ang mga aktibong batch ng baboy' : 'View and fund active hog batches';
  String get fundBatch => isFilipino ? 'Pondohan ang Batch' : 'Fund Batch';
  String get investNow => isFilipino ? 'Mamuhunan Ngayon' : 'Invest Now';
  String get batchProgress => isFilipino ? 'Progreso ng Batch' : 'Batch Progress';
  String get batchDetails => isFilipino ? 'Detalye ng Batch' : 'Batch Details';
  String get assignedRaiser => isFilipino ? 'Nakatalagang Tagapag-alaga' : 'Assigned Raiser';
  String get targetCapital => isFilipino ? 'Target na Puhunan' : 'Target Capital';
  String get currentFunded => isFilipino ? 'Kasalukuyang Naipon' : 'Current Funded';
  String get projectedROI => isFilipino ? 'Tantiyang Kita (ROI)' : 'Projected ROI';
  String get lifecycleStage => isFilipino ? 'Yugto ng Buhay' : 'Lifecycle Stage';
  String get hogCount => isFilipino ? 'Bilang ng Baboy' : 'Hog Count';
  String get searchBatches => isFilipino ? 'Maghanap ng batch o tagapag-alaga...' : 'Search batch or raiser...';
  String get allBatches => isFilipino ? 'Lahat ng Batch' : 'All Batches';
  String get myInvestments => isFilipino ? 'Aking mga Puhunan' : 'My Investments';
  String get myInvestmentsSubtitle => isFilipino ? 'Subaybayan ang iyong mga pinondohang proyekto' : 'Track your funded projects and returns';
  String get navInvestment => 'INVESTMENT';
  String get navActivities => 'ACTIVITIES';
  String get noReportsYet => isFilipino ? 'Walang Ulat sa Ngayon' : 'No Reports Yet';
  String get noReportsSubtitle => isFilipino ? 'Lalabas dito ang mga update ng tagapag-alaga.' : 'Updates & logs from your raisers will appear here.';
  String get refreshReports => isFilipino ? 'I-refresh' : 'Refresh Reports';

  // ================= Settings / Theme =================
  String get themePreference => isFilipino ? 'Tema ng App' : 'App Theme';
  String get themeSubtitle => isFilipino ? 'Piliin ang light o dark mode' : 'Switch between light and dark mode';
  String get lightMode => isFilipino ? 'Light Mode' : 'Light Mode';
  String get darkMode => isFilipino ? 'Dark Mode' : 'Dark Mode';
}
