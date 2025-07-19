import 'package:flutter/material.dart';
import '../../../../../core/services/download_service.dart';

class DocumentViewer extends StatefulWidget {
  final String documentUrl;
  final String fileName;
  final String? mimeType;
  final int? fileSize;

  const DocumentViewer({
    super.key,
    required this.documentUrl,
    required this.fileName,
    this.mimeType,
    this.fileSize,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getColorByMimeType(widget.mimeType),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconByMimeType(widget.mimeType),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _getFileTypeDescription(widget.mimeType),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (widget.fileSize != null) ...[
                          Text(
                            ' • ${_formatFileSize(widget.fileSize!)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _downloadDocument(context),
                icon: const Icon(
                  Icons.download,
                  color: Colors.blue,
                  size: 20,
                ),
                tooltip: 'Download',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorByMimeType(String? mimeType) {
    if (mimeType == null) return Colors.grey;
    
    if (mimeType.contains('pdf')) {
      return Colors.red;
    } else if (mimeType.contains('word') || mimeType.contains('doc')) {
      return Colors.blue;
    } else if (mimeType.contains('excel') || mimeType.contains('sheet')) {
      return Colors.green;
    } else if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) {
      return Colors.orange;
    } else if (mimeType.contains('text')) {
      return Colors.grey;
    } else if (mimeType.contains('zip') || mimeType.contains('rar') || mimeType.contains('archive')) {
      return Colors.purple;
    } else {
      return Colors.grey;
    }
  }

  IconData _getIconByMimeType(String? mimeType) {
    if (mimeType == null) return Icons.description;
    
    if (mimeType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType.contains('word') || mimeType.contains('doc')) {
      return Icons.description;
    } else if (mimeType.contains('excel') || mimeType.contains('sheet')) {
      return Icons.table_chart;
    } else if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) {
      return Icons.slideshow;
    } else if (mimeType.contains('text')) {
      return Icons.text_snippet;
    } else if (mimeType.contains('zip') || mimeType.contains('rar') || mimeType.contains('archive')) {
      return Icons.archive;
    } else {
      return Icons.description;
    }
  }

  String _getFileTypeDescription(String? mimeType) {
    if (mimeType == null) return 'Document';
    
    if (mimeType.contains('pdf')) {
      return 'PDF Document';
    } else if (mimeType.contains('word') || mimeType.contains('doc')) {
      return 'Word Document';
    } else if (mimeType.contains('excel') || mimeType.contains('sheet')) {
      return 'Excel Spreadsheet';
    } else if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) {
      return 'PowerPoint Presentation';
    } else if (mimeType.contains('text')) {
      return 'Text Document';
    } else if (mimeType.contains('zip') || mimeType.contains('rar') || mimeType.contains('archive')) {
      return 'Archive File';
    } else {
      return 'Document';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  Future<void> _downloadDocument(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Starting download...'),
          backgroundColor: Colors.blue,
        ),
      );

      final success = await DownloadService().downloadFile(widget.documentUrl, widget.fileName);
      
      if (!mounted) return;
      
      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Document downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to download document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error downloading document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}