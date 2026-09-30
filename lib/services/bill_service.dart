import 'package:supabase_flutter/supabase_flutter.dart';

/// One person's part of a bill.
class BillShare {
  final String userId;
  final String name;
  final String? avatarUrl;
  final int amountPaise;
  final DateTime? paidAt;

  const BillShare({
    required this.userId,
    required this.name,
    required this.amountPaise,
    this.avatarUrl,
    this.paidAt,
  });

  bool get paid => paidAt != null;
}

/// A split bill for one hangout. Amounts are integer paise.
class Bill {
  final String id;
  final String sessionId;
  final String payerId;
  final String payerName;
  final String payerUpi;
  final int totalPaise;
  final List<BillShare> shares;

  const Bill({
    required this.id,
    required this.sessionId,
    required this.payerId,
    required this.payerName,
    required this.payerUpi,
    required this.totalPaise,
    required this.shares,
  });

  BillShare? shareOf(String userId) {
    for (final s in shares) {
      if (s.userId == userId) return s;
    }
    return null;
  }

  int get paidCount => shares.where((s) => s.paid).length;
  bool get settled => shares.every((s) => s.paid);

  factory Bill.fromJson(Map<String, dynamic> json) {
    final shares = [
      for (final r in (json['bill_shares'] as List? ?? const []))
        BillShare(
          userId: r['user_id'] as String,
          name: ((r['profiles'] as Map<String, dynamic>?)?['display_name']
                  as String?) ??
              'Someone',
          avatarUrl: (r['profiles'] as Map<String, dynamic>?)?['avatar_url']
              as String?,
          amountPaise: (r['amount_paise'] as num).toInt(),
          paidAt: r['paid_at'] == null
              ? null
              : DateTime.parse(r['paid_at'] as String),
        ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Bill(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      payerId: json['payer_id'] as String,
      payerName: ((json['profiles'] as Map<String, dynamic>?)?['display_name']
              as String?) ??
          'Someone',
      payerUpi: json['payer_upi'] as String,
      totalPaise: (json['total_paise'] as num).toInt(),
      shares: shares,
    );
  }
}

/// Why a bill action failed, from the database functions' error codes.
enum BillError {
  alreadyExists,
  notRevealed,
  invalidUpi,
  invalidTotal,
  sharesMustAddUp,
  notAllowed,
  network,
}

class BillException implements Exception {
  final BillError error;
  const BillException(this.error);

  @override
  String toString() => 'BillException($error)';
}

/// Bills are written only through database functions (see
/// supabase/002_complete_app.sql), which keep shares adding up to the total.
class BillService {
  final SupabaseClient _db;

  BillService({SupabaseClient? client})
      : _db = client ?? Supabase.instance.client;

  static const _select = 'id, session_id, payer_id, payer_upi, total_paise, '
      'profiles(display_name), '
      'bill_shares(user_id, amount_paise, paid_at, '
      'profiles(display_name, avatar_url))';

  String? get myId => _db.auth.currentUser?.id;

  Future<Bill?> getBill(String sessionId) async {
    final row = await _db
        .from('bills')
        .select(_select)
        .eq('session_id', sessionId)
        .maybeSingle();
    return row == null ? null : Bill.fromJson(row);
  }

  /// Emits the bill (or null) now and whenever it changes. Every write bumps
  /// the bill row, so watching bills alone covers share changes too.
  Stream<Bill?> watchBill(String sessionId) {
    return _db
        .from('bills')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .asyncMap((_) => getBill(sessionId));
  }

  Future<String> createBill({
    required String sessionId,
    required int totalPaise,
    required String payerUpi,
    required List<String> memberIds,
  }) =>
      _call(() async => await _db.rpc('create_bill', params: {
            'p_session_id': sessionId,
            'p_total_paise': totalPaise,
            'p_payer_upi': payerUpi.trim(),
            'p_member_ids': memberIds,
          }) as String);

  Future<void> setShares(String billId, Map<String, int> amountsByUser) =>
      _call(() => _db.rpc('set_bill_shares', params: {
            'p_bill_id': billId,
            'p_shares': [
              for (final e in amountsByUser.entries)
                {'user_id': e.key, 'amount_paise': e.value},
            ],
          }));

  Future<void> setPaid(String billId, String userId, bool paid) =>
      _call(() => _db.rpc('set_share_paid', params: {
            'p_bill_id': billId,
            'p_user_id': userId,
            'p_paid': paid,
          }));

  Future<void> deleteBill(String billId) =>
      _call(() => _db.rpc('delete_bill', params: {'p_bill_id': billId}));

  /// The signed-in person's saved UPI ID, if any.
  Future<String?> getMyUpi() async {
    final uid = myId;
    if (uid == null) return null;
    final row = await _db
        .from('payment_details')
        .select('upi_id')
        .eq('user_id', uid)
        .maybeSingle();
    return row?['upi_id'] as String?;
  }

  Future<void> saveMyUpi(String upiId) async {
    await _db.from('payment_details').upsert({
      'user_id': myId,
      'upi_id': upiId.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<T> _call<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      throw BillException(_map(e.message));
    } on BillException {
      rethrow;
    } catch (_) {
      throw const BillException(BillError.network);
    }
  }

  static BillError _map(String message) {
    if (message.contains('bill_exists')) return BillError.alreadyExists;
    if (message.contains('not_revealed')) return BillError.notRevealed;
    if (message.contains('invalid_upi')) return BillError.invalidUpi;
    if (message.contains('invalid_total')) return BillError.invalidTotal;
    if (message.contains('shares_must') || message.contains('negative_share')) {
      return BillError.sharesMustAddUp;
    }
    if (message.contains('not_payer') ||
        message.contains('not_allowed') ||
        message.contains('not_a_member')) {
      return BillError.notAllowed;
    }
    return BillError.network;
  }
}
