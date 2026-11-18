// Màu sắc đạt chuẩn WCAG AA (>= 4.5:1), icon và nhãn tiếng Việt cho 4 loại nhắc.

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/reminder.dart';

class CategoryVisual {
  const CategoryVisual({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.containerColor,
  });

  final String label;
  final IconData icon;
  final Color foregroundColor;
  final Color containerColor;
}

class CategoryStyle {
  const CategoryStyle._();

  static CategoryVisual of(
    ReminderCategory category,
    Brightness brightness, {
    bool highContrast = false,
  }) {
    final isDark = brightness == Brightness.dark;
    switch (category) {
      case ReminderCategory.task:
        return CategoryVisual(
          label: 'Công việc',
          icon: LucideIcons.briefcase,
          foregroundColor: highContrast
              ? (isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E3A8A))
              : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF)),
          containerColor:
              isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        );
      case ReminderCategory.meal:
        return CategoryVisual(
          label: 'Ăn uống',
          icon: LucideIcons.utensils,
          foregroundColor: highContrast
              ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F))
              : (isDark ? const Color(0xFFFCD34D) : const Color(0xFF9A3412)),
          containerColor:
              isDark ? const Color(0xFF292524) : const Color(0xFFFFF7ED),
        );
      case ReminderCategory.hydration:
        return CategoryVisual(
          label: 'Uống nước & Nghỉ',
          icon: LucideIcons.droplets,
          foregroundColor: highContrast
              ? (isDark ? const Color(0xFF99F6E4) : const Color(0xFF115E59))
              : (isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E)),
          containerColor:
              isDark ? const Color(0xFF132A2E) : const Color(0xFFF0FDFA),
        );
      case ReminderCategory.sleep:
        return CategoryVisual(
          label: 'Giấc ngủ',
          icon: LucideIcons.moon,
          foregroundColor: highContrast
              ? (isDark ? const Color(0xFFC7D2FE) : const Color(0xFF312E81))
              : (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA)),
          containerColor:
              isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
        );
    }
  }
}
