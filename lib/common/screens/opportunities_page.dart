import 'package:drivio_app/common/services/opportunities_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _activeCampaigns = [];
  List<Map<String, dynamic>> _myCampaigns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Get driver's city from location or profile
      final city = 'New York'; // Placeholder

      final events = await OpportunitiesService.getLocalEvents(city);
      final activeCampaigns = await OpportunitiesService.getActiveCampaigns(
        city: city,
      );
      final myCampaigns = await OpportunitiesService.getMyCampaigns();

      setState(() {
        _events = events;
        _activeCampaigns = activeCampaigns;
        _myCampaigns = myCampaigns;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading opportunities: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunities'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Events'), Tab(text: 'Campaigns')],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildEventsTab(), _buildCampaignsTab()],
                ),
              ),
    );
  }

  Widget _buildEventsTab() {
    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No upcoming events',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final startTime = DateTime.parse(event['start_time'] as String);
    final timeStr = DateFormat('h:mm a').format(startTime);
    final dateStr = DateFormat('MMM d, yyyy').format(startTime);
    final surgeMultiplier =
        (event['surge_multiplier'] as num?)?.toDouble() ?? 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getEventTypeColor(event['event_type'] as String?),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (event['event_type'] as String? ?? 'Event').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (surgeMultiplier > 1.0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${surgeMultiplier}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$dateStr • $timeStr',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event['title'] as String? ?? 'Untitled Event',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event['venue'] as String? ??
                        event['city'] as String? ??
                        'Location TBD',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
            if (event['expected_attendance'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatNumber(event['expected_attendance'] as int)} expected',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_myCampaigns.isNotEmpty) ...[
          const Text(
            'My Campaigns',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._myCampaigns.map((participation) {
            final campaign = participation['campaign'] as Map<String, dynamic>;
            return _buildMyCampaignCard(participation, campaign);
          }),
          const SizedBox(height: 24),
        ],
        const Text(
          'Available Campaigns',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_activeCampaigns.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No active campaigns',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          )
        else
          ..._activeCampaigns.map((campaign) => _buildCampaignCard(campaign)),
      ],
    );
  }

  Widget _buildMyCampaignCard(
    Map<String, dynamic> participation,
    Map<String, dynamic> campaign,
  ) {
    final completionPercentage =
        (participation['completion_percentage'] as num?)?.toDouble() ?? 0;
    final isCompleted = participation['is_completed'] as bool? ?? false;
    final progress = participation['progress'] as Map<String, dynamic>? ?? {};
    final goalCriteria = campaign['goal_criteria'] as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isCompleted ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    campaign['title'] as String? ?? 'Campaign',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getCampaignProgressText(
                campaign['campaign_type'] as String,
                progress,
                goalCriteria,
              ),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${completionPercentage.toStringAsFixed(0)}% Complete',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getRewardText(campaign),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final endDate = DateTime.parse(campaign['end_date'] as String);
    final daysLeft = endDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    campaign['title'] as String? ?? 'Campaign',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$daysLeft days left',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              campaign['description'] as String? ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  _getRewardText(campaign),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _joinCampaign(campaign['id'] as int),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Join Campaign'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinCampaign(int campaignId) async {
    final success = await OpportunitiesService.joinCampaign(campaignId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully joined campaign!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData(); // Refresh data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to join campaign'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getEventTypeColor(String? type) {
    switch (type) {
      case 'sporting':
        return Colors.blue;
      case 'concert':
        return Colors.purple;
      case 'conference':
        return Colors.teal;
      case 'festival':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  String _getCampaignProgressText(
    String type,
    Map<String, dynamic> progress,
    Map<String, dynamic> goal,
  ) {
    switch (type) {
      case 'ride_count':
        final completed = progress['rides_completed'] ?? 0;
        final target = goal['rides'] ?? 0;
        return '$completed / $target rides completed';
      case 'earnings':
        final completed = progress['total_earnings'] ?? 0;
        final target = goal['earnings'] ?? 0;
        return '\$${completed.toStringAsFixed(2)} / \$${target.toStringAsFixed(2)} earned';
      case 'hours':
        final completed = progress['hours_worked'] ?? 0;
        final target = goal['hours'] ?? 0;
        return '${completed.toStringAsFixed(1)} / ${target} hours worked';
      default:
        return 'In progress';
    }
  }

  String _getRewardText(Map<String, dynamic> campaign) {
    final rewardType = campaign['reward_type'] as String?;
    final rewardAmount = (campaign['reward_amount'] as num?)?.toDouble() ?? 0;
    final rewardPoints = campaign['reward_points'] as int? ?? 0;

    if (rewardType == 'combo') {
      return '\$${rewardAmount.toStringAsFixed(0)} + $rewardPoints pts';
    } else if (rewardType == 'cash') {
      return '\$${rewardAmount.toStringAsFixed(0)}';
    } else if (rewardType == 'points') {
      return '$rewardPoints points';
    } else if (rewardType == 'badge') {
      return campaign['reward_badge'] as String? ?? 'Badge';
    }
    return 'Reward';
  }
}
