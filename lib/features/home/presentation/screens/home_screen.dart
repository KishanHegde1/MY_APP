import 'package:flutter/material.dart';

import '../widgets/home_header.dart';
import '../widgets/nearby_services_section.dart';
import '../widgets/promotional_banner.dart';
import '../widgets/recent_bookings_section.dart';
import '../widgets/service_grid.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({this.onServiceSelected, super.key});

  final ValueChanged<String>? onServiceSelected;

  static const _offWhite = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : _offWhite,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 900 ? 32.0 : 20.0;

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                36,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const HomeHeader(),
                        const SizedBox(height: 30),
                        ServiceGrid(onServiceSelected: onServiceSelected),
                        const SizedBox(height: 28),
                        const PromotionalBanner(),
                        const SizedBox(height: 28),
                        const NearbyServicesSection(),
                        const SizedBox(height: 28),
                        const RecentBookingsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
