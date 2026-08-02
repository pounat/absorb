import 'package:flutter/material.dart';

class CollapsibleSection extends StatefulWidget {
  final IconData icon;
  final String title;
  final ColorScheme cs;
  final List<Widget> children;
  final bool isExpanded;
  final bool desktopMode;
  final ValueChanged<bool>? onExpansionChanged;

  const CollapsibleSection({
    super.key,
    required this.icon,
    required this.title,
    required this.cs,
    required this.children,
    this.isExpanded = false,
    this.desktopMode = false,
    this.onExpansionChanged,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  final ExpansibleController _controller = ExpansibleController();
  bool _isBuilt = false;

  @override
  void didUpdateWidget(covariant CollapsibleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isBuilt &&
        !widget.desktopMode &&
        !oldWidget.desktopMode &&
        widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.expand();
      } else {
        _controller.collapse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isBuilt = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.desktopMode) {
      if (!widget.isExpanded) return const SizedBox.shrink();
      return Card(
        elevation: isDark ? 0 : 1,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: widget.cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: widget.cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.cs.primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: widget.cs.outlineVariant.withValues(alpha: 0.35),
            ),
            ...widget.children,
          ],
        ),
      );
    }
    return Card(
      elevation: isDark ? 0 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: widget.cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? BorderSide(color: widget.cs.outlineVariant.withValues(alpha: 0.3))
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          controller: _controller,
          initiallyExpanded: widget.isExpanded,
          onExpansionChanged: widget.onExpansionChanged,
          leading: Icon(widget.icon, color: widget.cs.primary, size: 22),
          title: Text(
            widget.title,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          childrenPadding: EdgeInsets.zero,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          children: widget.children,
        ),
      ),
    );
  }
}
