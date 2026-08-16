import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../couple_connection/bloc/couple_bloc.dart';
import '../../couple_connection/bloc/couple_event.dart';
import '../models/connection_request_model.dart';
import '../repositories/discover_repository.dart';

class ConnectionRequestsScreen extends StatefulWidget {
  const ConnectionRequestsScreen({super.key});

  @override
  State<ConnectionRequestsScreen> createState() => _ConnectionRequestsScreenState();
}

class _ConnectionRequestsScreenState extends State<ConnectionRequestsScreen> {
  final _discoverRepository = DiscoverRepository();
  List<ConnectionRequestModel> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final reqs = await _discoverRepository.getIncomingRequests();
    if (mounted) {
      setState(() {
        _requests = reqs;
        _isLoading = false;
      });
    }
  }

  void _accept(ConnectionRequestModel req) async {
    _discoverRepository.acceptSpark(req.senderId, triggerNotification: true);
    await _discoverRepository.acceptRequest(req.id);
    if (!mounted) return;

    context.read<CoupleBloc>().add(CheckCoupleStatusRequested());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.favorite_rounded, color: AppColors.roseDust, size: 28),
            SizedBox(width: 10),
            Text('Couples Paired in Love! 💖', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(
          'You and ${req.senderProfile?.fullName ?? 'your partner'} are now paired into your private Haven love space!',
          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        ),
        actions: [
          CustomButton(
            text: 'Enter Haven',
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Love Sparks & Invites 💌', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: HavenLoadingIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_outline_rounded, size: 56, color: Colors.grey.shade600),
                      const SizedBox(height: 16),
                      const Text(
                        'No pending Love Sparks',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Incoming partner invites and romantic sparks appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    final sender = req.senderProfile;

                    return GlassCard(
                      borderRadius: 20,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundImage: sender?.avatarUrl != null ? NetworkImage(sender!.avatarUrl!) : null,
                                  child: sender?.avatarUrl == null
                                      ? Text(sender?.fullName.isNotEmpty == true ? sender!.fullName[0] : '?')
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sender?.fullName ?? 'User',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                                      if (req.message != null)
                                        Text(
                                          '"${req.message}"',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.champagne,
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                      ),
                                      onPressed: () => _accept(req),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.favorite_rounded, size: 15, color: Colors.black),
                                          SizedBox(width: 6),
                                          Text('Accept & Pair', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                                        foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                      ),
                                      onPressed: () {
                                        setState(() => _requests.removeAt(index));
                                      },
                                      child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
