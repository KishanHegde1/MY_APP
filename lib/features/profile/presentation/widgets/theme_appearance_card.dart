import 'package:flutter/material.dart';

import '../../../../core/theme/theme_controller.dart';

class ThemeAppearanceCard extends StatelessWidget {
  const ThemeAppearanceCard({super.key});

  static const _blue = Color(0xFF2563EB);
  static const _teal = Color(0xFF14B8A6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = ThemeControllerScope.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.45)
              : const Color(0xFFE7EDF5),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF132238).withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _blue.withValues(alpha: isDark ? 0.2 : 0.12),
                      _teal.withValues(alpha: isDark ? 0.18 : 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  color: _blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Choose how the app feels.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ThemeChoice(
                  label: 'System',
                  icon: Icons.brightness_auto_rounded,
                  selected: controller.themeMode == ThemeMode.system,
                  onTap: () => controller.setThemeMode(ThemeMode.system),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ThemeChoice(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  selected: controller.themeMode == ThemeMode.light,
                  onTap: () => controller.setThemeMode(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ThemeChoice(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  selected: controller.themeMode == ThemeMode.dark,
                  onTap: () => controller.setThemeMode(ThemeMode.dark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 17,
                color: isDark ? theme.colorScheme.secondary : _teal,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _modeDescription(controller.themeMode),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _modeDescription(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'Following your device setting',
      ThemeMode.light => 'Light mode is active',
      ThemeMode.dark => 'Dark mode is active',
    };
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme',
      child: Material(
        color: selected
            ? ThemeAppearanceCard._blue.withValues(alpha: 0.11)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selected ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? ThemeAppearanceCard._blue
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected
                      ? ThemeAppearanceCard._blue
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? ThemeAppearanceCard._blue
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
