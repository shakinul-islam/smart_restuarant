import 'package:flutter/material.dart';
import 'kitchen_display_screen.dart';
import 'admin_sales_dashboard.dart';
import 'live_table_grid.dart';
import 'menu_screen.dart';
import 'waiter_screen.dart';

class AdminDashboardTab extends StatelessWidget {
  final String restaurantId;

  const AdminDashboardTab({super.key, required this.restaurantId});

  // ================= MODERN CARD DESIGN =================
  Widget _buildModernCard(
    BuildContext context, {
    required double width,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 140, // Compact and smart height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic width for 2 cards side-by-side with 16px spacing
        final double cardWidth = (constraints.maxWidth - (24 * 2) - 16) / 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // =========== ROW 1 ===========
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildModernCard(
                    context,
                    width: cardWidth,
                    title: 'Live Tables',
                    subtitle: 'Monitor active tables',
                    icon: Icons.grid_view_rounded,
                    color: Colors.redAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LiveTableGridScreen(restaurantId: restaurantId),
                      ),
                    ),
                  ),
                  _buildModernCard(
                    context,
                    width: cardWidth,
                    title: 'Sales & Analytics',
                    subtitle: 'Revenue & Top Items',
                    icon: Icons.bar_chart_rounded,
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminSalesDashboard(restaurantId: restaurantId),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // =========== ROW 2 ===========
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildModernCard(
                    context,
                    width: cardWidth,
                    title: 'Kitchen Display',
                    subtitle: 'Live order screen',
                    icon: Icons.soup_kitchen,
                    color: Colors.brown,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            KitchenDisplayScreen(restaurantId: restaurantId),
                      ),
                    ),
                  ),
                  _buildModernCard(
                    context,
                    width: cardWidth,
                    title: 'Waiter Dashboard',
                    subtitle: 'Manage & serve food',
                    icon: Icons.room_service,
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WaiterScreen(restaurantId: restaurantId),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // =========== ROW 3 (CENTERED) ===========
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModernCard(
                    context,
                    width: cardWidth, // Exact same size as other cards
                    title: 'Customer View',
                    subtitle: 'Preview your menu',
                    icon: Icons.visibility_outlined,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MenuScreen(
                          restaurantId: restaurantId,
                          tableNumber: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
