import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Primary red gradient button
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double height;
  final Color? color;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.height = 54,
    this.color,
    this.textColor,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.color ?? AppColors.primaryRed;
    final fgColor = widget.textColor ?? Colors.white;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      onTap: widget.onPressed == null || widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.isOutlined
                ? null
                : LinearGradient(
                    colors: [bgColor, Color.lerp(bgColor, Colors.black, 0.2)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: widget.isOutlined ? Border.all(color: bgColor, width: 1.5) : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isOutlined
                ? null
                : [
                    BoxShadow(
                      color: bgColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.isOutlined ? bgColor : fgColor,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: widget.isOutlined ? bgColor : fgColor, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.isOutlined ? bgColor : fgColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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

/// Compact icon + label button
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryRed;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Reusable text field
class AppTextField extends StatelessWidget {
  final String hint;
  final String? label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final int maxLines;
  final VoidCallback? onTap;
  final bool readOnly;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.hint,
    this.label,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.validator,
    this.maxLines = 1,
    this.onTap,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      onTap: onTap,
      readOnly: readOnly,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        prefixIcon: prefix,
        suffixIcon: suffix,
      ),
    );
  }
}

/// Reusable app card
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? borderRadius;
  final List<BoxShadow>? shadow;
  final Gradient? gradient;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderRadius,
    this.shadow,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: gradient == null ? (color ?? AppColors.cardBackground) : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          boxShadow: shadow ?? AppShadows.card,
          border: border,
        ),
        child: child,
      ),
    );
  }
}

/// Show a styled snackbar
void showAppSnackbar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? AppColors.error : AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.textPrimary))),
        ],
      ),
      backgroundColor: AppColors.surfaceElevated,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}
