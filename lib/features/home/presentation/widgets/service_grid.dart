import 'package:flutter/material.dart';

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({this.onServiceSelected, super.key});

  final ValueChanged<String>? onServiceSelected;

  static const _blue = Color(0xFF2563EB);
  static const _teal = Color(0xFF14B8A6);
  static const _amber = Color(0xFFF59E0B);

  static const List<
    ({String id, String label, String description, IconData icon, Color color})
  >
  _services = [
    (
      id: 'local-rides',
      label: 'Local rides',
      description: 'Move around town',
      icon: Icons.two_wheeler_rounded,
      color: _blue,
    ),
    (
      id: 'outstation-rides',
      label: 'Outstation',
      description: 'Travel between cities',
      icon: Icons.route_rounded,
      color: _teal,
    ),
    (
      id: 'vehicle-rentals',
      label: 'Vehicle rentals',
      description: 'Drive on your terms',
      icon: Icons.key_rounded,
      color: _amber,
    ),
    (
      id: 'room-rentals',
      label: 'Rooms',
      description: 'Find a comfortable stay',
      icon: Icons.bed_rounded,
      color: Color(0xFF7C3AED),
    ),
    (
      id: 'property-rentals',
      label: 'Properties',
      description: 'Rent your next space',
      icon: Icons.apartment_rounded,
      color: Color(0xFFEA580C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a service',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Everything you need, right where you need it.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '5 services',
                style: TextStyle(
                  color: _blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 520
                ? 2
                : constraints.maxWidth < 880
                ? 3
                : 5;
            final itemHeight = constraints.maxWidth < 380 ? 190.0 : 184.0;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _services.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: itemHeight,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final service = _services[index];
                return _ServiceCard(
                  label: service.label,
                  description: service.description,
                  icon: service.icon,
                  accent: service.color,
                  onTap: onServiceSelected == null
                      ? null
                      : () => onServiceSelected!(service.id),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: onTap != null,
      label: '$label, $description',
      child: Material(
        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? theme.colorScheme.outlineVariant.withValues(alpha: 0.45)
                    : const Color(0xFFE8EDF5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: accent, size: 23),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_outward_rounded,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.55,
                        ),
                        size: 19,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
