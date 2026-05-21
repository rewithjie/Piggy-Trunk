import '../models/dashboard_model.dart';

class MockDashboardData {
  static DashboardData generateMockData() {
    // Mock user
    final user = AdminUser(
      name: 'Admin User',
      role: 'System Administrator',
      initials: 'AU',
    );

    // Mock raisers
    final raisers = [
      Raiser(
        id: 1,
        name: 'Raiser Alpha',
        code: 'RA-001',
        location: 'Farm A - Building 1',
        status: 'Active',
        pigType: PigType(id: 1, name: 'Fattening'),
      ),
      Raiser(
        id: 2,
        name: 'Raiser Beta',
        code: 'RA-002',
        location: 'Farm A - Building 2',
        status: 'Active',
        pigType: PigType(id: 1, name: 'Fattening'),
      ),
      Raiser(
        id: 3,
        name: 'Raiser Gamma',
        code: 'RA-003',
        location: 'Farm B - Building 1',
        status: 'Active',
        pigType: PigType(id: 2, name: 'Sow'),
      ),
    ];

    // Mock raiser lifecycles
    final fatteningStages = [
      LifecycleStage(
        label: 'Booster',
        duration: 'Initial boost',
        status: 'completed',
      ),
      LifecycleStage(
        label: 'Pre-Starter',
        duration: '1 month & 2 weeks',
        status: 'completed',
      ),
      LifecycleStage(
        label: 'Starter',
        duration: '2 months & 2 weeks',
        status: 'completed',
      ),
      LifecycleStage(
        label: 'Grower',
        duration: '2 months & 2 weeks',
        status: 'in-progress',
      ),
      LifecycleStage(
        label: 'Finisher',
        duration: 'Final growth stage',
        status: 'pending',
      ),
      LifecycleStage(
        label: 'Selling',
        duration: 'Final Stage',
        status: 'pending',
      ),
    ];

    final sowStages = [
      LifecycleStage(
        label: 'Booster',
        duration: 'Initial boost',
        status: 'completed',
      ),
      LifecycleStage(
        label: 'Pre-Starter',
        duration: '1 month & 2 weeks',
        status: 'completed',
      ),
      LifecycleStage(
        label: 'Starter',
        duration: '2 months & 2 weeks',
        status: 'completed',
      ),
      LifecycleStage(
        label: 'Grower',
        duration: '4 months - 8 months',
        status: 'in-progress',
      ),
      LifecycleStage(
        label: 'Gilt Developer',
        duration: 'Development stage',
        status: 'pending',
      ),
      LifecycleStage(
        label: 'Gestation Feed',
        duration: 'Pregnancy period',
        status: 'pending',
      ),
      LifecycleStage(
        label: 'Lactation Feed',
        duration: 'Nursing stage',
        status: 'pending',
      ),
      LifecycleStage(
        label: 'Separation',
        duration: 'Final Stage',
        status: 'pending',
      ),
    ];

    final raiserLifecycles = {
      '1': RaiserLifecycle(
        name: 'Raiser Alpha',
        status: 'Active',
        categories: fatteningStages,
      ),
      '2': RaiserLifecycle(
        name: 'Raiser Beta',
        status: 'Active',
        categories: fatteningStages,
      ),
      '3': RaiserLifecycle(
        name: 'Raiser Gamma',
        status: 'Active',
        categories: sowStages,
      ),
    };

    // Mock investment summary
    final allocation = InvestmentAllocation(
      fattening: 2500000.0,
      sow: 1500000.0,
    );

    final investmentSummary = InvestmentSummary(
      totalActive: 5,
      batchCount: 3,
      allocation: allocation,
      totalCapital: 4000000.0,
      expectedProfit: 850000.0,
    );

    return DashboardData(
      raisers: raisers,
      raiserLifecycles: raiserLifecycles,
      investmentSummary: investmentSummary,
      user: user,
    );
  }
}
