import 'package:drivio_app/common/models/map_report.dart';
import 'package:drivio_app/common/providers/map_reports_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class UserReportsScreen extends StatelessWidget {
  final List<MapReport> reports;

  const UserReportsScreen({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    final mapReportsProvider = Provider.of<MapReportsProvider>(context);
    final reports = mapReportsProvider.userReports;

    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: FutureBuilder<List<MapReport>>(
        future: MapReportsProvider().getUserReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No reports found'));
          } else {
            final reports = snapshot.data!;
            return ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return ReportListItem(report: report);
              },
            );
          }
        },
      ),
    );
  }
}

class ReportListItem extends StatelessWidget {
  final MapReport report;

  const ReportListItem({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _getReportIcon(report.reportType),
        color: _getReportColor(report.reportType),
      ),
      title: Text(report.reportType),
      subtitle: Text(
        DateFormat('MMM dd, yyyy - hh:mm a').format(report.createdAt),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Handle tapping on a report if needed
      },
    );
  }

  IconData _getReportIcon(String reportType) {
    switch (reportType.toLowerCase()) {
      case 'traffic':
        return Icons.traffic;
      case 'accident':
        return Icons.car_crash;
      case 'closure':
        return Icons.block;
      default:
        return Icons.report;
    }
  }

  Color _getReportColor(String reportType) {
    switch (reportType.toLowerCase()) {
      case 'traffic':
        return Colors.orange;
      case 'accident':
        return Colors.red;
      case 'closure':
        return Colors.black;
      default:
        return Colors.blue;
    }
  }
}
