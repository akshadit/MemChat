import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../models/drive_item.dart';
import '../theme/app_theme.dart';

class FileBubble extends StatelessWidget {
  final DriveItem item;
  final bool isOutgoing;

  const FileBubble({
    super.key,
    required this.item,
    this.isOutgoing = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(item.modifiedTime);

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isOutgoing ? AppTheme.outgoingBubble : AppTheme.incomingBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOutgoing ? 16 : 4),
            bottomRight: Radius.circular(isOutgoing ? 4 : 16),
          ),
          border: Border.all(
            color: isOutgoing ? AppTheme.outgoingBorder : AppTheme.incomingBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleOpen(context),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.isImage) _buildImagePreview(context),
                if (!item.isImage) _buildDocumentPreview(context),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all,
                      size: 14,
                      color: AppTheme.whatsappGreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: item.thumbnailLink != null
              ? CachedNetworkImage(
                  imageUrl: item.thumbnailLink!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: AppTheme.cardElevated,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildFallbackThumbnail(),
                )
              : _buildFallbackThumbnail(),
        ),
        const SizedBox(height: 8),
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        if (item.formattedSize.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            item.formattedSize,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentPreview(BuildContext context) {
    IconData iconData = Icons.insert_drive_file_rounded;
    Color iconColor = AppTheme.primaryEmerald;

    if (item.isPdf) {
      iconData = Icons.picture_as_pdf_rounded;
      iconColor = const Color(0xFFEF4444); // Red
    } else if (item.isAudio) {
      iconData = Icons.headphones_rounded;
      iconColor = const Color(0xFFF59E0B); // Amber
    } else if (item.isTextNote) {
      iconData = Icons.notes_rounded;
      iconColor = const Color(0xFF38BDF8); // Sky blue
    }

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: iconColor.withOpacity(0.3)),
          ),
          child: Icon(iconData, color: iconColor, size: 24),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.formattedSize.isNotEmpty
                    ? item.formattedSize
                    : (item.isTextNote ? 'Text note' : 'Document'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      height: 140,
      width: double.infinity,
      color: AppTheme.cardElevated,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40, color: AppTheme.textMuted),
      ),
    );
  }

  void _handleOpen(BuildContext context) {
    if (item.webViewLink != null && item.webViewLink!.isNotEmpty) {
      OpenFilex.open(item.webViewLink!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening ${item.name}...')),
      );
    }
  }
}
