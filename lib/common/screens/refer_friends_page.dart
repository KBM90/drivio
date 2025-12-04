import 'package:drivio_app/common/services/referral_service.dart';
import 'package:drivio_app/common/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ReferFriendsScreen extends StatefulWidget {
  const ReferFriendsScreen({super.key});

  @override
  State<ReferFriendsScreen> createState() => _ReferFriendsScreenState();
}

class _ReferFriendsScreenState extends State<ReferFriendsScreen> {
  String? _referralCode;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _referralHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final code = await ReferralService.generateReferralCode();
      final stats = await ReferralService.getReferralStats();
      final history = await ReferralService.getReferralHistory();

      setState(() {
        _referralCode = code;
        _stats = stats;
        _referralHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading referral data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _copyCode() {
    if (_referralCode != null) {
      Clipboard.setData(ClipboardData(text: _referralCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('referral_code_copied'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareCode() {
    if (_referralCode != null) {
      final loc = AppLocalizations.of(context)!;
      final message =
          '${loc.translate('join_drivio_message')} $_referralCode ${loc.translate('and_earn_rewards')}';
      Share.share(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.referFriends),
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Card
                      _buildStatsCard(),
                      const SizedBox(height: 24),

                      // Referral Code Card
                      _buildReferralCodeCard(),
                      const SizedBox(height: 24),

                      // How it works
                      _buildHowItWorks(),
                      const SizedBox(height: 24),

                      // Referral History
                      _buildReferralHistory(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatsCard() {
    final totalEarnings = _stats?['total_earnings'] ?? 0.0;
    final pendingEarnings = _stats?['pending_earnings'] ?? 0.0;
    final totalPoints = _stats?['total_points'] ?? 0;
    final totalReferrals = _stats?['total_referrals'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('your_earnings'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '\$${totalEarnings.toStringAsFixed(2)}',
                  AppLocalizations.of(context)!.translate('total_earned'),
                  Colors.green,
                ),
                _buildStatItem(
                  '\$${pendingEarnings.toStringAsFixed(2)}',
                  AppLocalizations.of(context)!.translate('pending'),
                  Colors.orange,
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '$totalPoints',
                  AppLocalizations.of(context)!.points,
                  Colors.blue,
                ),
                _buildStatItem(
                  '$totalReferrals',
                  AppLocalizations.of(context)!.translate('referrals'),
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildReferralCodeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('your_referral_code'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _referralCode ??
                        AppLocalizations.of(context)!.translate('loading'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copyCode,
                    tooltip: AppLocalizations.of(
                      context,
                    )!.translate('copy_code'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareCode,
                    icon: const Icon(Icons.share),
                    label: Text(
                      AppLocalizations.of(context)!.translate('share_code'),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('how_it_works'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildStep(
          '1',
          AppLocalizations.of(context)!.translate('share_your_code'),
          AppLocalizations.of(context)!.translate('share_your_code_desc'),
          Icons.share,
        ),
        const SizedBox(height: 12),
        _buildStep(
          '2',
          AppLocalizations.of(context)!.translate('friend_signs_up'),
          AppLocalizations.of(context)!.translate('friend_signs_up_desc'),
          Icons.person_add,
        ),
        const SizedBox(height: 12),
        _buildStep(
          '3',
          AppLocalizations.of(context)!.translate('earn_rewards'),
          AppLocalizations.of(context)!.translate('earn_rewards_desc'),
          Icons.card_giftcard,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('reward_milestones'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildMilestone(
                AppLocalizations.of(context)!.translate('sign_up'),
                '50 ${AppLocalizations.of(context)!.points}',
              ),
              _buildMilestone(
                AppLocalizations.of(context)!.translate('first_ride'),
                '\$5 + 100 ${AppLocalizations.of(context)!.points}',
              ),
              _buildMilestone(
                '5 ${AppLocalizations.of(context)!.translate('rides')}',
                '\$10 + 200 ${AppLocalizations.of(context)!.points}',
              ),
              _buildMilestone(
                '10 ${AppLocalizations.of(context)!.translate('rides')}',
                '\$15 + 300 ${AppLocalizations.of(context)!.points}',
              ),
              _buildMilestone(
                '20 ${AppLocalizations.of(context)!.translate('rides')}',
                '\$25 + 500 ${AppLocalizations.of(context)!.points}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(
    String number,
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          child: Center(child: Icon(icon, color: Colors.white, size: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestone(String milestone, String reward) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('• $milestone'),
          Text(
            reward,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralHistory() {
    if (_referralHistory.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('referral_history'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.translate('no_referrals_yet'),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.translate('start_sharing'),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('referral_history'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _referralHistory.length,
          itemBuilder: (context, index) {
            final referral = _referralHistory[index];
            final status = referral['status'] as String?;
            final ridesCompleted = (referral['rides_completed'] as int?) ?? 0;
            final referredUser =
                referral['referred_user'] as Map<String, dynamic>?;
            final name =
                referredUser?['name'] ??
                AppLocalizations.of(context)!.translate('pending_signup');

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status),
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(name),
                subtitle: Text(
                  '$ridesCompleted ${AppLocalizations.of(context)!.translate('rides_completed')}',
                ),
                trailing: _getStatusChip(status),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _getStatusChip(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status?.toUpperCase() ?? 'UNKNOWN',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(status),
        ),
      ),
    );
  }
}
