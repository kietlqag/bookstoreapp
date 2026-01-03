import 'package:flutter/material.dart';

import 'app_colors.dart';

class SearchBarField extends StatelessWidget {
  const SearchBarField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.readOnly = false,
    this.onTap,
    this.compact = false,
    this.fillColor,
    this.iconColor,
    this.hintColor,
    this.height,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool compact;
  final Color? fillColor;
  final Color? iconColor;
  final Color? hintColor;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 12.0 : 16.0;
    final padding = compact
        ? const EdgeInsets.symmetric(vertical: 6, horizontal: 12)
        : const EdgeInsets.symmetric(vertical: 14, horizontal: 12);
    final iconConstraints = compact
        ? const BoxConstraints(minWidth: 32, minHeight: 32)
        : null;
    final fontSize = compact ? 13.0 : null;
    final showClear = !readOnly && controller.text.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: height,
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textAlignVertical: TextAlignVertical.center,
              style: fontSize != null ? TextStyle(fontSize: fontSize) : null,
              decoration: InputDecoration(
                hintText: 'Tìm sách, tác giả...',
                prefixIcon:
                    Icon(Icons.search, color: iconColor ?? AppColors.gray600),
                prefixIconConstraints: iconConstraints,
                suffixIcon: showClear
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          color: hintColor ?? AppColors.gray600,
                          size: 18,
                        ),
                        onPressed: () {
                          controller.clear();
                          onChanged?.call('');
                        },
                      )
                    : null,
                isDense: compact,
                contentPadding: padding,
                filled: true,
                fillColor: fillColor ?? AppColors.gray100,
                hintStyle: TextStyle(
                  color: hintColor ?? AppColors.gray600,
                  fontSize: fontSize,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            height: 48,
            child: FilledButton(
              onPressed: onFilterTap,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.orange600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Icon(Icons.tune, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }
}
