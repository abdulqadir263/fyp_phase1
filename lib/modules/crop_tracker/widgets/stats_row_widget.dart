import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class StatsRowWidget extends StatelessWidget {
  final int activeCrops;
  final double totalIncome;
  final double totalProfit;

  const StatsRowWidget({
    super.key,
    required this.activeCrops,
    required this.totalIncome,
    required this.totalProfit,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = totalProfit >= 0;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.agriculture,
            label: 'Active Crops',
            value: activeCrops.toString(),
            color: AppConstants.primaryGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.attach_money,
            label: 'Total Income',
            value: _fmt(totalIncome),
            color: Colors.blue.shade600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: isProfit
                ? Icons.trending_up
                : Icons.trending_down,
            label: isProfit ? 'Profit' : 'Loss',
            value: _fmt(totalProfit.abs()),
            color: isProfit
                ? Colors.green.shade600
                : Colors.red.shade600,
          ),
        ),
      ],
    );
  }

  String _fmt(double n) {
    if (n >= 1000000)
      return 'Rs ${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)
      return 'Rs ${(n / 1000).toStringAsFixed(1)}K';
    return 'Rs ${n.toStringAsFixed(0)}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}