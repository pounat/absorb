import 'package:flutter/material.dart';

class DesktopAccountButton extends StatelessWidget {
  const DesktopAccountButton({
    super.key,
    required this.accountName,
    required this.serverLabel,
    required this.extended,
    required this.onPressed,
  });

  static const buttonKey = ValueKey<String>('desktop-account-menu-button');

  final String accountName;
  final String serverLabel;
  final bool extended;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tooltip = serverLabel.isEmpty
        ? accountName
        : '$accountName\n$serverLabel';
    final avatar = CircleAvatar(
      radius: 18,
      backgroundColor: cs.secondaryContainer,
      foregroundColor: cs.onSecondaryContainer,
      child: Text(accountName.characters.first.toUpperCase()),
    );

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: buttonKey,
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: extended
                  ? Row(
                      children: [
                        avatar,
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                accountName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge,
                              ),
                              if (serverLabel.isNotEmpty)
                                Text(
                                  serverLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.manage_accounts_outlined,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    )
                  : Center(child: avatar),
            ),
          ),
        ),
      ),
    );
  }
}
