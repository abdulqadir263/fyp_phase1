import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/constants/app_constants.dart';
import '../models/message_model.dart';

/// Reusable widget for chat message bubbles with smooth animations
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          // Haptic feedback
          HapticFeedback.mediumImpact();
          // Copy text to clipboard
          Clipboard.setData(ClipboardData(text: message.text));
          // Show toast notification
          Fluttertoast.showToast(
            msg: "Copied!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
            fontSize: 14.0,
          );
          onLongPress?.call();
        },
        child: AnimatedContainer(
          duration: AppConstants.shortAnimation,
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: EdgeInsets.only(
            left: message.isUser ? 48 : 12,
            right: message.isUser ? 12 : 48,
            top: 4,
            bottom: 4,
          ),
          child: Column(
            crossAxisAlignment:
                message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: message.isUser
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppConstants.primaryGreen,
                            Color.fromARGB(
                              AppConstants.primaryGreen.a.toInt(),
                              AppConstants.primaryGreen.r.toInt(),
                              (AppConstants.primaryGreen.g * 0.85).toInt(),
                              AppConstants.primaryGreen.b.toInt(),
                            ),
                          ],
                        )
                      : null,
                  color: message.isUser ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(message.isUser ? 20 : 6),
                    bottomRight: Radius.circular(message.isUser ? 6 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: message.isUser
                          ? AppConstants.primaryGreen.withOpacity(0.2)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show image if available
                    if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: message.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.error_outline_rounded),
                          ),
                        ),
                      ),
                    if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                      const SizedBox(height: 10),
                    // Message text with improved typography
                    SelectableText(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.grey[850],
                        fontSize: 15,
                        height: 1.5,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              // Timestamp with smooth styling
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 6, right: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(message.timestamp),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (message.isUser) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all_rounded,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
