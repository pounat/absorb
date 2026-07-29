import 'package:flutter/material.dart';

class ServerAdminStatusBadges extends StatelessWidget {
  final int issueCount;
  final String? updateVersion;
  final String updateTooltip;

  const ServerAdminStatusBadges({
    super.key,
    required this.issueCount,
    required this.updateVersion,
    required this.updateTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (updateVersion case final version?) ...[
          Tooltip(
            message: updateTooltip,
            child: Semantics(
              label: updateTooltip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.system_update_alt_rounded,
                      size: 12,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'v$version',
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (issueCount > 0) const SizedBox(width: 6),
        ],
        if (issueCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.report_problem_rounded,
                  size: 12,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  '$issueCount',
                  style: tt.labelSmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
