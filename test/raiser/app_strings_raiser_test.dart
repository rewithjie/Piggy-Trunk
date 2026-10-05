import 'package:flutter_test/flutter_test.dart';
import 'package:piggytrunk/mobile_app/utils/app_strings.dart';

void main() {
  group('AppStrings Hog Raiser Localization Tests', () {
    test('English strings verify key labels', () {
      final strings = AppStrings('en');
      expect(strings.isFilipino, false);
      expect(strings.dashboard, 'Dashboard');
      expect(strings.request, 'Request');
      expect(strings.hogs, 'Hogs');
      expect(strings.profile, 'Profile');
      expect(strings.logWeight, 'Log Weight');
      expect(strings.statusHealthy, 'Healthy');
      expect(strings.statusRecovered, 'Recovered');
      expect(strings.statusSick, 'Sick');
      expect(strings.fatteningTag, 'Fattening');
      expect(strings.sowBreedTag, 'Sow / Breeding');
      expect(strings.helloGreeting.isNotEmpty, true);
    });

    test('Filipino strings verify localized labels', () {
      final strings = AppStrings('fil');
      expect(strings.isFilipino, true);
      expect(strings.dashboard, 'Dashboard');
      expect(strings.request, 'Kahilingan');
      expect(strings.hogs, 'Mga Baboy');
      expect(strings.profile, 'Profile');
      expect(strings.logWeight, 'Itala ang Timbang');
      expect(strings.statusHealthy, 'Malusog');
      expect(strings.statusRecovered, 'Nakabawi');
      expect(strings.statusSick, 'May Sakit');
      expect(strings.fatteningTag, 'Pagpapataba');
      expect(strings.sowBreedTag, 'Palahi / Sow');
      expect(strings.helloGreeting.isNotEmpty, true);
    });

    test('formatStatus properly resolves all health and request states', () {
      final strings = AppStrings('en');
      expect(strings.formatStatus('healthy'), 'Healthy');
      expect(strings.formatStatus('recovered'), 'Recovered');
      expect(strings.formatStatus('sick'), 'Sick');
      expect(strings.formatStatus('injured'), 'Injury');
      expect(strings.formatStatus('injury'), 'Injury');
      expect(strings.formatStatus('dead'), 'Deceased');
      expect(strings.formatStatus('deceased'), 'Deceased');
      expect(strings.formatStatus('food poisoning'), 'Food Poisoning');
      expect(strings.formatStatus('fever'), 'Fever');
      expect(strings.formatStatus('diarrhea'), 'Diarrhea');
      expect(strings.formatStatus('pending'), 'Pending');
      expect(strings.formatStatus('for_approval'), 'Pending');
      expect(strings.formatStatus('approved'), 'Approved');
      expect(strings.formatStatus('distributed'), 'Distributed');
      expect(strings.formatStatus('rejected'), 'Rejected');
    });

    test('formatStatus in Filipino properly resolves localized labels', () {
      final strings = AppStrings('fil');
      expect(strings.formatStatus('healthy'), 'Malusog');
      expect(strings.formatStatus('recovered'), 'Nakabawi');
      expect(strings.formatStatus('sick'), 'May Sakit');
      expect(strings.formatStatus('injured'), 'Sugat');
      expect(strings.formatStatus('dead'), 'Namatay');
      expect(strings.formatStatus('pending'), 'Nakabinbin');
      expect(strings.formatStatus('approved'), 'Aprubado');
    });

    test('formatRelativeTime returns expected strings', () {
      final strings = AppStrings('en');
      final now = DateTime.now();
      expect(strings.formatRelativeTime(now), 'Just now');
      expect(strings.formatRelativeTime(now.subtract(const Duration(minutes: 5))), '5m ago');
      expect(strings.formatRelativeTime(now.subtract(const Duration(hours: 3))), '3h ago');
      expect(strings.formatRelativeTime(now.subtract(const Duration(days: 2))), '2d ago');
      expect(strings.formatRelativeTime(null), 'Recent');
    });
  });
}
