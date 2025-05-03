import 'dart:async';

import 'package:flutter/material.dart';

class RiderNotifiedCountdown extends StatefulWidget {
  final bool shouldShow;
  final String passengerName;

  const RiderNotifiedCountdown({
    super.key,
    required this.shouldShow,
    required this.passengerName,
  });

  @override
  State<RiderNotifiedCountdown> createState() => _RiderNotifiedCountdownState();
}

class _RiderNotifiedCountdownState extends State<RiderNotifiedCountdown> {
  Timer? _countdownTimer;
  int _countdownSeconds = 120;

  @override
  void initState() {
    super.initState();
    if (widget.shouldShow) {
      _startCountdown();
    }
  }

  @override
  void didUpdateWidget(covariant RiderNotifiedCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldShow && _countdownTimer == null) {
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
      }
    });
  }

  String _formatCountdown(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
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
        const Center(
          child: Text(
            'Rider Notified',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Center(
          child: Text(
            _formatCountdown(_countdownSeconds),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
