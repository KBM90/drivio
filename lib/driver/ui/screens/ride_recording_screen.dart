import 'package:camera/camera.dart';
import 'package:drivio_app/driver/providers/ride_recording_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RideRecordingScreen extends StatefulWidget {
  final String? rideId;

  const RideRecordingScreen({super.key, this.rideId});

  @override
  State<RideRecordingScreen> createState() => _RideRecordingScreenState();
}

class _RideRecordingScreenState extends State<RideRecordingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  Future<void> _initializeCamera() async {
    final provider = context.read<RideRecordingProvider>();
    await provider.initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<RideRecordingProvider>(
        builder: (context, provider, child) {
          if (provider.status == RecordingStatus.initializing) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (provider.status == RecordingStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage ?? 'Camera error',
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

          return Stack(
            children: [
              // Camera Preview
              if (provider.cameraController != null &&
                  provider.cameraController!.value.isInitialized)
                Positioned.fill(
                  child: CameraPreview(provider.cameraController!),
                ),

              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(provider),
              ),

              // Recording Controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildControlsBar(provider),
              ),

              // Recording Indicator
              if (provider.isRecording || provider.isPaused)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 60,
                  left: 16,
                  child: _buildRecordingIndicator(provider),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(RideRecordingProvider provider) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              if (provider.isRecording) {
                final confirm = await _showStopRecordingDialog();
                if (confirm == true) {
                  await provider.stopRecording();
                  if (mounted) Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Spacer(),
          if (!provider.isRecording && !provider.isPaused)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              onPressed: () => provider.switchCamera(),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator(RideRecordingProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            provider.isPaused
                ? Colors.orange.withOpacity(0.9)
                : Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(provider.recordingDuration),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (provider.isPaused) ...[
            const SizedBox(width: 8),
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlsBar(RideRecordingProvider provider) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 24,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pause/Resume Button
          if (provider.isRecording || provider.isPaused)
            _buildControlButton(
              icon: provider.isPaused ? Icons.play_arrow : Icons.pause,
              label: provider.isPaused ? 'Resume' : 'Pause',
              onPressed: () {
                if (provider.isPaused) {
                  provider.resumeRecording();
                } else {
                  provider.pauseRecording();
                }
              },
            ),

          // Start/Stop Button
          _buildMainButton(provider),

          // Placeholder for symmetry
          if (provider.isRecording || provider.isPaused)
            const SizedBox(width: 64),
        ],
      ),
    );
  }

  Widget _buildMainButton(RideRecordingProvider provider) {
    if (provider.isRecording || provider.isPaused) {
      // Stop button
      return GestureDetector(
        onTap: () async {
          final recording = await provider.stopRecording();
          if (recording != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Recording saved: ${recording.formattedDuration}',
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        },
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.red, width: 4),
          ),
          child: const Icon(Icons.stop, color: Colors.red, size: 40),
        ),
      );
    } else {
      // Start button
      return GestureDetector(
        onTap: () async {
          final success = await provider.startRecording(rideId: widget.rideId);
          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to start recording'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: const Icon(
            Icons.fiber_manual_record,
            color: Colors.white,
            size: 40,
          ),
        ),
      );
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 32),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<bool?> _showStopRecordingDialog() {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Stop Recording?'),
            content: const Text(
              'Do you want to stop and save the current recording?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Stop & Save'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    final provider = context.read<RideRecordingProvider>();
    provider.disposeCamera();
    super.dispose();
  }
}
