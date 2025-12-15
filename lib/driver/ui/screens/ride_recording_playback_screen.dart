import 'dart:io';
import 'package:drivio_app/common/models/ride_recording.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class RideRecordingPlaybackScreen extends StatefulWidget {
  final RideRecording recording;

  const RideRecordingPlaybackScreen({super.key, required this.recording});

  @override
  State<RideRecordingPlaybackScreen> createState() =>
      _RideRecordingPlaybackScreenState();
}

class _RideRecordingPlaybackScreenState
    extends State<RideRecordingPlaybackScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final file = File(widget.recording.filePath);
      if (!await file.exists()) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video file not found';
        });
        return;
      }

      _controller = VideoPlayerController.file(file);
      await _controller.initialize();

      setState(() {
        _isInitialized = true;
      });

      _controller.addListener(() {
        setState(() {});
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Recording Playback'),
      ),
      body:
          _hasError
              ? _buildErrorView()
              : !_isInitialized
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : Column(
                children: [
                  // Video Player
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  ),

                  // Controls
                  _buildControls(),

                  // Recording Info
                  _buildRecordingInfo(),
                ],
              ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Failed to load video',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          // Progress Bar
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.blue,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 8),

          // Time and Controls
          Row(
            children: [
              // Current Time / Duration
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const Spacer(),

              // Rewind
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white),
                onPressed: () {
                  final newPosition =
                      _controller.value.position - const Duration(seconds: 10);
                  _controller.seekTo(
                    newPosition < Duration.zero ? Duration.zero : newPosition,
                  );
                },
              ),

              // Play/Pause
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),

              // Forward
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white),
                onPressed: () {
                  final newPosition =
                      _controller.value.position + const Duration(seconds: 10);
                  _controller.seekTo(
                    newPosition > _controller.value.duration
                        ? _controller.value.duration
                        : newPosition,
                  );
                },
              ),
              const Spacer(),

              // Speed Control
              PopupMenuButton<double>(
                icon: const Icon(Icons.speed, color: Colors.white),
                onSelected: (speed) {
                  _controller.setPlaybackSpeed(speed);
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                      const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                      const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                      const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                    ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingInfo() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recording Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.calendar_today,
            'Date',
            DateFormat(
              'MMM dd, yyyy • HH:mm',
            ).format(widget.recording.startTime),
          ),
          _buildInfoRow(
            Icons.timer,
            'Duration',
            widget.recording.formattedDuration,
          ),
          _buildInfoRow(
            Icons.storage,
            'File Size',
            widget.recording.formattedFileSize,
          ),
          if (widget.recording.rideId != null)
            _buildInfoRow(
              Icons.local_taxi,
              'Ride ID',
              widget.recording.rideId!.substring(0, 8),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
