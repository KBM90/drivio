import 'package:drivio_app/common/helpers/snack_bar_helper.dart';
import 'package:drivio_app/common/models/report.dart';
import 'package:drivio_app/common/services/report_service.dart';
import 'package:flutter/material.dart';

class ReportDialog extends StatefulWidget {
  final int reportedUserId;
  final String reportedUserName;
  final bool isDriver; // true if current user is driver, false if passenger

  const ReportDialog({
    super.key,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.isDriver,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  List<ReportReason> get _reasons {
    return widget.isDriver
        ? ReportReasons.driverReasons
        : ReportReasons.passengerReasons;
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      SnackBarHelper.showErrorSnackBar(
        context,
        'Please select a reason for reporting',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ReportService.submitReport(
        reportedUserId: widget.reportedUserId,
        reason: _selectedReason!,
        details:
            _detailsController.text.trim().isEmpty
                ? null
                : _detailsController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        SnackBarHelper.showSuccessSnackBar(
          context,
          'Report submitted successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Failed to submit report: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.reportedUserName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please select a reason for reporting:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            // Reason selection
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedReason,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Select a reason'),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  items:
                      _reasons.map((reason) {
                        return DropdownMenuItem<String>(
                          value: reason.value,
                          child: Text(
                            reason.label,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                  onChanged:
                      _isSubmitting
                          ? null
                          : (value) {
                            setState(() {
                              _selectedReason = value;
                            });
                          },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Optional details
            const Text(
              'Additional details (optional):',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              enabled: !_isSubmitting,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Provide more details about the issue...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Text('Submit Report'),
        ),
      ],
    );
  }
}
