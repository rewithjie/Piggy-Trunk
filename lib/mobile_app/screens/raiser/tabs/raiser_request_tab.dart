import 'package:flutter/material.dart';
import '../request_form_screen.dart';
import '../request_history_screen.dart';

class RaiserRequestTab extends StatefulWidget {
  final List<Map<String, dynamic>> activeAssignments;
  final Map<String, dynamic> raiserData;
  final List<Map<String, dynamic>> requestsList;
  final double investedAmount;
  final double initialCapital;
  final double stocksSpendAmount;
  final Future<void> Function() onRefresh;

  const RaiserRequestTab({
    super.key,
    required this.activeAssignments,
    required this.raiserData,
    required this.requestsList,
    this.investedAmount = 0.0,
    this.initialCapital = 0.0,
    this.stocksSpendAmount = 0.0,
    required this.onRefresh,
  });

  @override
  State<RaiserRequestTab> createState() => _RaiserRequestTabState();
}

class _RaiserRequestTabState extends State<RaiserRequestTab> {
  /// 'form' is Request Supplies, 'history' is Request History
  String _requestView = 'form';
  final String _selectedCategoryForForm = 'All';

  @override
  Widget build(BuildContext context) {
    if (_requestView == 'history') {
      return RequestHistoryScreen(
        raiserData: widget.raiserData,
        initialRequests: widget.requestsList,
        onBack: () {
          setState(() {
            _requestView = 'form';
          });
        },
      );
    }

    return RequestFormScreen(
      activeAssignments: widget.activeAssignments,
      raiserData: widget.raiserData,
      investedAmount: widget.investedAmount,
      initialCapital: widget.initialCapital,
      stocksSpendAmount: widget.stocksSpendAmount,
      initialCategory: _selectedCategoryForForm,
      showBackButton: false,
      onBack: () {
        setState(() {
          _requestView = 'history';
        });
      },
      onSuccess: () {
        setState(() {
          _requestView = 'history';
        });
        widget.onRefresh();
      },
      onViewHistory: () {
        setState(() {
          _requestView = 'history';
        });
      },
    );
  }
}
