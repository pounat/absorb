import 'package:flutter/material.dart';

class EditableSheetItem extends StatelessWidget {
  final int index;
  final bool selected;
  final ValueChanged<bool> onSelectedChanged;
  final Widget leading;
  final String title;
  final String? subtitle;

  const EditableSheetItem({
    super.key,
    required this.index,
    required this.selected,
    required this.onSelectedChanged,
    required this.leading,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: selected
            ? cs.primary.withValues(alpha: 0.08)
            : cs.onSurface.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? cs.primary.withValues(alpha: 0.35)
                : cs.onSurface.withValues(alpha: 0.08),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          onTap: () => onSelectedChanged(!selected),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: selected,
                onChanged: (value) => onSelectedChanged(value ?? false),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 6),
              SizedBox(width: 36, height: 36, child: leading),
            ],
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
          trailing: ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.drag_handle_rounded,
                size: 18,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
