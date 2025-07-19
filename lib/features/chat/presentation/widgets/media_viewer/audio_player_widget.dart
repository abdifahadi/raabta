import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';  // Temporarily disabled for web compatibility
import '../../../../../core/services/download_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String? fileName;
  final Duration? duration;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.fileName,
    this.duration,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Audio icon and info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.audiotrack,
                  color: Colors.deepPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fileName ?? 'Audio File',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.duration != null 
                          ? _formatDuration(widget.duration!)
                          : 'Audio Message',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Web notice and actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Audio player coming soon for web platform',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    // Open in new tab button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openAudioInNewTab(),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Open', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(color: Colors.deepPurple),
                          foregroundColor: Colors.deepPurple,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Download button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading ? null : () => _downloadAudio(context),
                        icon: _isDownloading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download, size: 16),
                        label: Text(
                          _isDownloading ? 'Downloading...' : 'Download',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAudioInNewTab() {
    // For web platform, open audio in new tab
    // This will be handled by the browser's built-in audio player
    try {
      // Use html package for web or url_launcher for other platforms
      final uri = Uri.parse(widget.audioUrl);
      // In a real implementation, you'd use url_launcher here
      print('Opening audio in new tab: ${uri.toString()}');
      
      // Fallback: Show snackbar with URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio URL: ${widget.audioUrl}'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () {
              // Copy to clipboard functionality would go here
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open audio file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadAudio(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      setState(() {
        _isDownloading = true;
      });

      final success = await DownloadService.downloadFile(
        widget.audioUrl,
        widget.fileName ?? 'audio_file.mp3',
      );

      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Audio downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to download audio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Download error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}