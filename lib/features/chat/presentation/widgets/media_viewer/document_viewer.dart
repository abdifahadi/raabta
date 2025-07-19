import 'package:flutter/material.dart';

class DocumentViewer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // File icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getFileTypeColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileTypeIcon(),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        if (mimeType != null) ...[
                          Text(
                            _getFileTypeDisplay(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (fileSize != null) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                        if (fileSize != null)
                          Text(
                            _formatFileSize(fileSize!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              Column(
                children: [
                  IconButton(
                    onPressed: () => _previewDocument(context),
                    icon: const Icon(
                      Icons.visibility,
                      color: Colors.deepPurple,
                    ),
                    tooltip: 'Preview',
                  ),
                  IconButton(
                    onPressed: () => _downloadDocument(context),
                    icon: Icon(
                      Icons.download,
                      color: Colors.grey[600],
                    ),
                    tooltip: 'Download',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getFileTypeColor() {
    if (mimeType == null) return Colors.grey;
    
    if (mimeType!.contains('pdf')) {
      return Colors.red;
    } else if (mimeType!.contains('word') || mimeType!.contains('document')) {
      return Colors.blue;
    } else if (mimeType!.contains('excel') || mimeType!.contains('spreadsheet')) {
      return Colors.green;
    } else if (mimeType!.contains('powerpoint') || mimeType!.contains('presentation')) {
      return Colors.orange;
    } else if (mimeType!.contains('text')) {
      return Colors.grey[700]!;
    } else {
      return Colors.grey;
    }
  }

  IconData _getFileTypeIcon() {
    if (mimeType == null) return Icons.insert_drive_file;
    
    if (mimeType!.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType!.contains('word') || mimeType!.contains('document')) {
      return Icons.description;
    } else if (mimeType!.contains('excel') || mimeType!.contains('spreadsheet')) {
      return Icons.table_chart;
    } else if (mimeType!.contains('powerpoint') || mimeType!.contains('presentation')) {
      return Icons.slideshow;
    } else if (mimeType!.contains('text')) {
      return Icons.article;
    } else if (mimeType!.contains('zip') || mimeType!.contains('archive')) {
      return Icons.archive;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _getFileTypeDisplay() {
    if (mimeType == null) return 'Document';
    
    if (mimeType!.contains('pdf')) {
      return 'PDF';
    } else if (mimeType!.contains('word') || mimeType!.contains('document')) {
      return 'Word Document';
    } else if (mimeType!.contains('excel') || mimeType!.contains('spreadsheet')) {
      return 'Excel Spreadsheet';
    } else if (mimeType!.contains('powerpoint') || mimeType!.contains('presentation')) {
      return 'PowerPoint';
    } else if (mimeType!.contains('text')) {
      return 'Text File';
    } else if (mimeType!.contains('zip')) {
      return 'ZIP Archive';
    } else {
      return 'Document';
    }
  }

  String _formatFileSize(int bytes) {
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;
    
    if (bytes >= gb) {
      return '${(bytes / gb).toStringAsFixed(1)} GB';
    } else if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    } else if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(1)} KB';
    } else {
      return '$bytes B';
    }
  }

  void _previewDocument(BuildContext context) {
    // For now, show a dialog indicating preview functionality
    // In a real app, you might use packages like flutter_pdfview or webview_flutter
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: $fileName'),
            if (mimeType != null) Text('Type: ${_getFileTypeDisplay()}'),
            if (fileSize != null) Text('Size: ${_formatFileSize(fileSize!)}'),
            const SizedBox(height: 16),
            const Text(
              'Document preview functionality will be implemented with appropriate viewers for different file types.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _downloadDocument(context);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _downloadDocument(BuildContext context) {
    // TODO: Implement document download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download functionality will be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Static method to show document viewer in fullscreen
  static void showFullscreen(
    BuildContext context, {
    required String documentUrl,
    required String fileName,
    String? mimeType,
    int? fileSize,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(fileName),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: DocumentViewer(
              documentUrl: documentUrl,
              fileName: fileName,
              mimeType: mimeType,
              fileSize: fileSize,
            ),
          ),
        ),
      ),
    );
  }
}