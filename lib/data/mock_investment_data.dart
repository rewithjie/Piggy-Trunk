import '../models/investment_model.dart';

class MockInvestmentData {
  static List<Investment> generateMockInvestments() {
    return [
      Investment(
        id: '1',
        hogRaiserId: '1',
        raiserName: 'Raiser Alpha',
        initialCapital: 50000.0,
        hogType: 'Fattening',
        totalHog: 45,
        investmentDate: DateTime(2026, 3, 15),
        stage: 'Active',
      ),
      Investment(
        id: '2',
        hogRaiserId: '2',
        raiserName: 'Raiser Beta',
        initialCapital: 75000.0,
        hogType: 'Sow',
        totalHog: 30,
        investmentDate: DateTime(2026, 2, 20),
        stage: 'Active',
      ),
      Investment(
        id: '3',
        hogRaiserId: '3',
        raiserName: 'Raiser Gamma',
        initialCapital: 60000.0,
        hogType: 'Fattening',
        totalHog: 52,
        investmentDate: DateTime(2026, 1, 10),
        stage: 'Completed',
      ),
    ];
  }

  static List<Investment> getEmptyList() {
    return [];
  }
}
