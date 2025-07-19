import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _totalDuration = widget.duration ?? const Duration(minutes: 3); // Default 3 minutes
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      // Listen to player state changes
      _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
            _isLoading = state == PlayerState.playing && _currentPosition == Duration.zero;
          });
        }
      });

      // Listen to position changes
      _audioPlayer.onPositionChanged.listen((Duration position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      });

      // Listen to duration changes
      _audioPlayer.onDurationChanged.listen((Duration duration) {
        if (mounted) {
          setState(() {
            _totalDuration = duration;
          });
        }
      });

      // Set the source
      await _audioPlayer.setSourceUrl(widget.audioUrl);
    } catch (e) {
      // Handle error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _pauseAudio();
      } else {
        _playAudio();
      }
    });
  }

  Future<void> _playAudio() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await _audioPlayer.resume();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _seekToPosition(double value) async {
    try {
      final position = Duration(
        milliseconds: (value * _totalDuration.inMilliseconds).round(),
      );
      await _audioPlayer.seek(position);
    } catch (e) {
      // Handle error
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File name
          if (widget.fileName != null)
            Text(
              widget.fileName!,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          
          const SizedBox(height: 8),
          
          // Player controls
          Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Progress slider and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress bar
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: _totalDuration.inMilliseconds > 0
                            ? _currentPosition.inMilliseconds /
                                _totalDuration.inMilliseconds
                            : 0.0,
                        onChanged: _seekToPosition,
                        activeColor: Colors.deepPurple,
                        inactiveColor: Colors.grey[300],
                      ),
                    ),
                    
                    // Time display
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_currentPosition),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _formatDuration(_totalDuration),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Download button
              IconButton(
                onPressed: () => _downloadAudio(context),
                icon: const Icon(
                  Icons.download,
                  color: Colors.grey,
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

  Future<void> _downloadAudio(BuildContext context) async {
    try {
      final fileName = widget.fileName ?? 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading audio...'),
          backgroundColor: Colors.blue,
        ),
      );

      final success = await DownloadService().downloadFile(widget.audioUrl, fileName);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download audio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}