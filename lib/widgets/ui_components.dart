import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String? delta;
  final String? deltaDir; // 'up', 'down', 'flat'
  final IconData icon;
  final Color? iconColor;
  final Color? iconBg;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.delta,
    this.deltaDir,
    required this.icon,
    this.iconColor,
    this.iconBg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconBg ?? AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor ?? AppColors.forestLight),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (delta != null) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (deltaDir == 'up') ...[
                    const Icon(Icons.arrow_upward_rounded, size: 12, color: AppColors.success),
                    const SizedBox(width: 3),
                  ] else if (deltaDir == 'down') ...[
                    const Icon(Icons.arrow_downward_rounded, size: 12, color: AppColors.danger),
                    const SizedBox(width: 3),
                  ],
                  Flexible(
                    child: Text(
                      delta!,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: deltaDir == 'up'
                            ? AppColors.success
                            : (deltaDir == 'down' ? AppColors.danger : AppColors.textSecondary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ] else if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum BadgeTone { success, warning, danger, info, purple, gold, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (tone) {
      case BadgeTone.success:
        bg = AppColors.successBg;
        fg = AppColors.success;
        break;
      case BadgeTone.warning:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        break;
      case BadgeTone.danger:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        break;
      case BadgeTone.info:
        bg = AppColors.infoBg;
        fg = AppColors.info;
        break;
      case BadgeTone.purple:
        bg = AppColors.purpleBg;
        fg = AppColors.purple;
        break;
      case BadgeTone.gold:
        bg = AppColors.goldLight;
        fg = AppColors.goldDark;
        break;
      case BadgeTone.neutral:
        bg = AppColors.surfaceAlt;
        fg = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class SearchInput extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const SearchInput({
    super.key,
    this.hint = 'Search...',
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
        suffixIcon: controller != null && controller!.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  controller!.clear();
                  onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A premium button in the Gold tone family matching the web .btn-gold specification.
class GoldButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final dynamic icon;
  final String label;
  final bool fullWidth;
  final double height;
  final bool isBusy;
  final EdgeInsetsGeometry? padding;

  const GoldButton({
    super.key,
    required this.onPressed,
    this.icon,
    required this.label,
    this.fullWidth = false,
    this.height = 44,
    this.isBusy = false,
    this.padding,
  });

  Widget? _resolveIcon() {
    if (icon == null) return null;
    if (icon is IconData) {
      return Icon(icon as IconData, size: 16, color: AppColors.forest);
    }
    if (icon is Widget) {
      return icon as Widget;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isBusy;
    final iconWidget = _resolveIcon();

    return Container(
      height: height,
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: isDisabled ? null : AppColors.goldGradient,
        color: isDisabled ? AppColors.border : null,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isDisabled ? null : const [AppColors.goldButtonShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isDisabled ? null : onPressed,
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Center(
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.forest,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (iconWidget != null) ...[
                          iconWidget,
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDisabled ? AppColors.text3 : AppColors.forest,
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

/// A responsive action bar that displays action buttons side-by-side on desktop
/// and stacks them vertically (or provides full-width touch targets) on mobile screens.
class ResponsiveActionBar extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;

  const ResponsiveActionBar({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 550;
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children.map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  height: 48,
                  child: c,
                ),
              );
            }).toList(),
          );
        }

        return Row(
          mainAxisAlignment: mainAxisAlignment,
          children: children.map((c) {
            return Padding(
              padding: const EdgeInsets.only(left: 10),
              child: c,
            );
          }).toList(),
        );
      },
    );
  }
}

/// A responsive filter bar that adjusts search input, dropdown filter, and action button
/// dynamically depending on the available screen width.
class ResponsiveFilterBar extends StatelessWidget {
  final Widget searchWidget;
  final Widget? filterWidget;
  final Widget? actionWidget;
  final double? filterWidth;

  const ResponsiveFilterBar({
    super.key,
    required this.searchWidget,
    this.filterWidget,
    this.actionWidget,
    this.filterWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 480;
        final isNarrow = constraints.maxWidth < 680;

        if (isMobile) {
          // Mobile single column stacked layout
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchWidget,
              if (filterWidget != null) ...[
                const SizedBox(height: 8),
                filterWidget!,
              ],
              if (actionWidget != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: actionWidget!,
                ),
              ],
            ],
          );
        }

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchWidget,
              if (filterWidget != null || actionWidget != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (filterWidget != null) Expanded(child: filterWidget!),
                    if (filterWidget != null && actionWidget != null) const SizedBox(width: 10),
                    if (actionWidget != null) actionWidget!,
                  ],
                ),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchWidget),
            if (filterWidget != null) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: filterWidth ?? 200,
                child: filterWidget!,
              ),
            ],
            if (actionWidget != null) ...[
              const SizedBox(width: 12),
              actionWidget!,
            ],
          ],
        );
      },
    );
  }
}


