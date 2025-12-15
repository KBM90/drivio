import 'package:drivio_app/common/models/ride_recording.dart';
import 'package:drivio_app/driver/providers/ride_recording_provider.dart';
import 'package:drivio_app/driver/ui/screens/ride_recording_playback_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RideRecordingsHistoryScreen extends StatefulWidget {
  const RideRecordingsHistoryScreen({super.key});

  @override
  State<RideRecordingsHistoryScreen> createState() =>
      _RideRecordingsHistoryScreenState();
}

class _RideRecordingsHistoryScreenState
    extends State<RideRecordingsHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await context.read<RideRecordingProvider>().loadUserRecordings(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ride Recordings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecordings,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'cleanup') {
                _showCleanupDialog();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'cleanup',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep),
                        SizedBox(width: 8),
                        Text('Cleanup Old Recordings'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Consumer<RideRecordingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingRecordings) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.recordings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No recordings yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start recording your rides for safety',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadRecordings,
            child: ListView.builder(
              itemCount: provider.recordings.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final recording = provider.recordings[index];
                return _buildRecordingCard(recording, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordingCard(
    RideRecording recording,
    RideRecordingProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      RideRecordingPlaybackScreen(recording: recording),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(
                        'MMM dd, yyyy • HH:mm',
                      ).format(recording.startTime),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          recording.formattedDuration,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.storage, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          recording.formattedFileSize,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (recording.rideId != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.local_taxi, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            'Ride #${recording.rideId!.substring(0, 8)}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(recording, provider);
                  } else if (value == 'share') {
                    _shareRecording(recording);
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share),
                            SizedBox(width: 8),
                            Text('Share'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    RideRecording recording,
    RideRecordingProvider provider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Recording?'),
            content: const Text(
              'This action cannot be undone. The video file will be permanently deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      final success = await provider.deleteRecording(
        recording.id,
        recording.filePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Recording deleted successfully'
                  : 'Failed to delete recording',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCleanupDialog() async {
    final daysController = TextEditingController(text: '30');

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cleanup Old Recordings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delete recordings older than:'),
                const SizedBox(height: 16),
                TextField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Days',
                    suffixText: 'days',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cleanup'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      final days = int.tryParse(daysController.text) ?? 30;
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId != null) {
        final deletedCount = await context
            .read<RideRecordingProvider>()
            .cleanupOldRecordings(userId, daysToKeep: days);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted $deletedCount old recording(s)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _shareRecording(RideRecording recording) async {
    // TODO: Implement share functionality using share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }
}
