import 'dart:async';
import 'package:flutter/material.dart';

class RiderNotifiedCountdown extends StatefulWidget {
  final bool shouldShow;
  final String passengerName;
  final Future<void> Function() onMarkAsArrived;
  const RiderNotifiedCountdown({
    super.key,
    required this.shouldShow,
    required this.passengerName,
    required this.onMarkAsArrived,
  });

  @override
  State<RiderNotifiedCountdown> createState() => _RiderNotifiedCountdownState();
}

class _RiderNotifiedCountdownState extends State<RiderNotifiedCountdown> {
  Timer? _countdownTimer;
  int _countdownSeconds = 120;
  bool _hasMarkedArrived = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.shouldShow && _hasMarkedArrived) {
      _startCountdown();
    }
  }

  @override
  void didUpdateWidget(covariant RiderNotifiedCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldShow && _countdownTimer == null && _hasMarkedArrived) {
      _startCountdown();
    } else if (!widget.shouldShow) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }
  }

  void _startCountdown() {
    _countdownSeconds = 120;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        _countdownTimer = null;
        // Reset after countdown finishes
        setState(() => _hasMarkedArrived = false);
      }
    });
  }

  String _formatCountdown(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  Future<void> _handleMarkAsArrived() async {
    setState(() => _isLoading = true);

    try {
      await widget.onMarkAsArrived();
      setState(() {
        _hasMarkedArrived = true;
        _isLoading = false;
      });
      _startCountdown();
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error if needed
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.shouldShow) return const SizedBox.shrink();

    return Column(
      children: [
        Center(
          child: Text(
            _hasMarkedArrived ? 'Rider Notified' : '',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        if (_hasMarkedArrived && _countdownTimer != null)
          Center(
            child: Text(
              _formatCountdown(_countdownSeconds),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          )
        else
          Center(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleMarkAsArrived,
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Notify Passenger'),
            ),
          ),
      ],
    );
  }
}
