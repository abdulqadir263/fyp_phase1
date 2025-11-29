import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../controllers/home_controller.dart';

/// Quick actions section with grid of action cards
class QuickActionsSection extends GetView<HomeController> {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'What would you like to do today?',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildActionsGrid(context),
      ],
    );
  }

  Widget _buildActionsGrid(BuildContext context) {
    final actions = [
      _QuickAction(
        title: 'Crop Tracker',
        icon: Icons.agriculture,
        color: Colors.brown,
        onTap: () => controller.navigateToFeature('crop_tracker'),
      ),
      _QuickAction(
        title: 'Weather',
        icon: Icons.wb_sunny,
        color: Colors.orange,
        onTap: () => controller.navigateToFeature('weather'),
      ),
      _QuickAction(
        title: 'Marketplace',
        icon: Icons.shopping_cart,
        color: Colors.green,
        onTap: () => controller.navigateToFeature('marketplace'),
      ),
      _QuickAction(
        title: 'Community',
        icon: Icons.people,
        color: Colors.purple,
        onTap: () => controller.navigateToFeature('community'),
      ),
      _QuickAction(
        title: 'Chatbot',
        icon: Icons.chat,
        color: Colors.teal,
        onTap: () => controller.navigateToFeature('chatbot'),
      ),
      _QuickAction(
        title: 'Appointments',
        icon: Icons.calendar_today,
        color: Colors.blue,
        onTap: () => controller.navigateToFeature('appointments'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return _buildActionCard(action);
        },
      ),
    );
  }

  Widget _buildActionCard(_QuickAction action) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: action.color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
