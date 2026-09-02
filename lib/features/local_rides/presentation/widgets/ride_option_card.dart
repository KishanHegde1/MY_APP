import 'package:flutter/material.dart';

class RideOptionCard extends StatelessWidget {
  const RideOptionCard({
    required this.title,
    required this.icon,
    this.subtitle,
    this.accent,
    this.isSelected = false,
    this.isBusy = false,
    this.onTap,
    super.key,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final Color? accent;
  final bool isSelected;
  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final effectiveAccent = accent ?? colors.primary;

    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label: subtitle == null ? title : '$title, $subtitle',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveAccent.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.17 : 0.08,
                )
              : colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? effectiveAccent
                : colors.outlineVariant.withValues(alpha: 0.7),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: isSelected && theme.brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: effectiveAccent.withValues(alpha: 0.11),
                    blurRadius: 22,
                    offset: const Offset(0, 9),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isBusy ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: effectiveAccent.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icon, color: effectiveAccent, size: 25),
                      ),
                      const Spacer(),
                      if (isBusy)
                        SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: effectiveAccent,
                          ),
                        )
                      else
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.arrow_outward_rounded,
                            key: ValueKey(isSelected),
                            size: 21,
                            color: isSelected
                                ? effectiveAccent
                                : colors.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
