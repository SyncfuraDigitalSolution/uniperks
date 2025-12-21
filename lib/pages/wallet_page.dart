import 'package:flutter/material.dart';
import 'package:uniperks/services/user_coins_service.dart';

class WalletPage extends StatefulWidget {
  final String username;
  const WalletPage({super.key, required this.username});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late Future<int> _coinsFuture;
  late Future<List<Map<String, dynamic>>> _txFuture;

  @override
  void initState() {
    super.initState();
    _coinsFuture = UserCoinsService.getCoins(widget.username);
    _txFuture = UserCoinsService.getTransactions(widget.username);
  }

  Future<void> _reload() async {
    setState(() {
      _coinsFuture = UserCoinsService.getCoins(widget.username);
      _txFuture = UserCoinsService.getTransactions(widget.username);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Coins',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<int>(
                          future: _coinsFuture,
                          builder: (context, snapshot) {
                            final coins = snapshot.data ?? 0;
                            return Text(
                              '$coins',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0066CC),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Manage section removed
            const SizedBox(height: 8),
            const Text(
              'History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _txFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final txs = snapshot.data ?? [];
                  if (txs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No history yet'),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: txs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final tx = txs[i];
                      final type = (tx['type'] as String?) ?? 'add';
                      final amount = (tx['amount'] as int?) ?? 0;
                      final source = (tx['source'] as String?) ?? '';
                      final createdAt = tx['created_at']?.toString();
                      final isAdd = type == 'add';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              (isAdd
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444))
                                  .withOpacity(0.15),
                          child: Icon(
                            isAdd
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: isAdd
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        title: Text(
                          (isAdd ? '+ ' : '- ') + amount.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isAdd
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        subtitle: Text(
                          source.isEmpty
                              ? (isAdd ? 'Addition' : 'Deduction')
                              : source,
                        ),
                        trailing: createdAt != null
                            ? Text(
                                createdAt
                                    .split('.')
                                    .first
                                    .replaceFirst('T', ' '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
