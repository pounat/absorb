import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import 'author_books_sheet.dart';

class AuthorCard extends StatelessWidget {
  final Map<String, dynamic> author;

  const AuthorCard({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final lib = context.read<LibraryProvider>();

    final name = author['name'] as String? ?? l.unknown;
    final authorId = author['id'] as String? ?? '';

    String? imageUrl;
    // Only authors with a photo get a request: the server answers 404 for
    // the rest, and a burst of those reads as probing to fail2ban and
    // CrowdSec in front of it (GH #418).
    final hasPhoto = (author['imagePath'] as String?)?.isNotEmpty == true;
    if (authorId.isNotEmpty && hasPhoto && auth.apiService != null) {
      final ts = (author['updatedAt'] as num?)?.toInt();
      imageUrl = auth.apiService!.getAuthorImageUrl(authorId, updatedAt: ts);
    }

    final headers = lib.mediaHeaders;

    return InkWell(
      onTap: () {
        if (authorId.isNotEmpty) {
          showAuthorDetailSheet(context, authorId: authorId, authorName: name);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.secondaryContainer,
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    httpHeaders: headers,
                    placeholder: (_, __) => _placeholder(cs),
                    errorWidget: (_, __, ___) => _placeholder(cs),
                  )
                : _placeholder(cs),
          ),
          const SizedBox(height: 8),
          // Name
          SizedBox(
            width: 100,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: 32,
        color: cs.onSecondaryContainer.withValues(alpha: 0.5),
      ),
    );
  }
}
