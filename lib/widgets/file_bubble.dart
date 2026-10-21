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
    this.isOutgoing = true,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(item.modifiedTime);

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 3,
          bottom: 3,
          left: isOutgoing ? 56 : 10,
          right: isOutgoing ? 10 : 56,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isOutgoing ? AppTheme.outgoingBubble : AppTheme.incomingBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: Radius.circular(isOutgoing ? 2 : 10),
            bottomLeft: Radius.circular(isOutgoing ? 10 : 2),
            bottomRight: const Radius.circular(10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 3,
              offset: const Offset(0, 1.2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _handleOpen(context),
            child: _buildBubbleContent(context, timeStr),
          ),
        ),
      ),
    );
  }

  Widget _buildBubbleContent(BuildContext context, String timeStr) {
    if (item.isImage) {
      return _buildImageBubble(context, timeStr);
    } else if (item.isAudio) {
      return _buildAudioBubble(context, timeStr);
    } else if (item.isTextNote) {
      return _buildTextNoteBubble(context, timeStr);
    } else {
      return _buildDocumentBubble(context, timeStr);
    }
  }

  // --- PHOTO BUBBLE ---
  Widget _buildImageBubble(BuildContext context, String timeStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          child: Stack(
            children: [
              item.thumbnailLink != null
                  ? CachedNetworkImage(
                      imageUrl: item.thumbnailLink!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: AppTheme.cardElevated,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.whatsappTeal,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _buildFallbackThumbnail(),
                    )
                  : _buildFallbackThumbnail(),
              // Gradient scrim for caption/overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildTimestampAndReceipt(timeStr),
            ],
          ),
        ),
      ],
    );
  }

  // --- DOCUMENT (PDF / DOC / ZIP) BUBBLE ---
  Widget _buildDocumentBubble(BuildContext context, String timeStr) {
    final ext = item.name.contains('.') ? item.name.split('.').last.toUpperCase() : 'FILE';
    Color badgeColor = const Color(0xFFEF4444); // Red default for PDF
    if (ext == 'ZIP' || ext == 'RAR') badgeColor = const Color(0xFFEAB308);
    if (ext == 'DOC' || ext == 'DOCX') badgeColor = const Color(0xFF3B82F6);
    if (ext == 'XLS' || ext == 'XLSX') badgeColor = const Color(0xFF10B981);

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isOutgoing ? const Color(0xFF025143) : const Color(0xFF182229),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // File extension badge
                Container(
                  width: 38,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withOpacity(0.5), width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_rounded, size: 18, color: badgeColor),
                      const SizedBox(height: 2),
                      Text(
                        ext.length > 4 ? ext.substring(0, 3) : ext,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.formattedSize.isNotEmpty ? item.formattedSize : 'Document',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildTimestampAndReceipt(timeStr),
            ),
          ),
        ],
      ),
    );
  }

  // --- AUDIO / VOICE MEMO BUBBLE ---
  Widget _buildAudioBubble(BuildContext context, String timeStr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Avatar with mic indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isOutgoing ? const Color(0xFF025143) : const Color(0xFF182229),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppTheme.whatsappGreen,
                      size: 26,
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppTheme.whatsappTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Simulated Audio Waveform Bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(24, (index) {
                        final heights = [8, 14, 18, 10, 22, 16, 12, 20, 14, 8, 16, 24, 18, 12, 10, 16, 20, 8, 14, 18, 10, 12, 8, 14];
                        final h = heights[index % heights.length].toDouble();
                        final isPlayed = index < 10;
                        return Expanded(
                          child: Container(
                            height: h,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isPlayed ? AppTheme.whatsappGreen : AppTheme.textMuted.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '0:42',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        Text(
                          item.formattedSize.isNotEmpty ? item.formattedSize : 'Voice Note',
                          style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: _buildTimestampAndReceipt(timeStr),
          ),
        ],
      ),
    );
  }

  // --- TEXT NOTE BUBBLE ---
  Widget _buildTextNoteBubble(BuildContext context, String timeStr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2, right: 8),
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppTheme.textPrimary,
                height: 1.35,
              ),
            ),
          ),
          _buildTimestampAndReceipt(timeStr),
        ],
      ),
    );
  }

  Widget _buildTimestampAndReceipt(String timeStr) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          timeStr,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (isOutgoing) ...[
          const SizedBox(width: 3),
          const Icon(
            Icons.done_all_rounded,
            size: 15,
            color: AppTheme.whatsappCheckBlue,
          ),
        ],
      ],
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      height: 160,
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
        SnackBar(
          content: Text('Opening ${item.name}...'),
          backgroundColor: AppTheme.darkAppBar,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
