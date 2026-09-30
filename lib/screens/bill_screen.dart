import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/group.dart';
import '../services/bill_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../utils/links.dart';
import '../utils/money.dart';
import '../widgets/hangout_avatar.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_chips.dart';
import '../widgets/hangout_list.dart';

/// Splitting the bill for one hangout.
///
/// Whoever paid adds the total and who came; everyone else sees what they owe
/// and pays by UPI in one tap. Hangout never touches the money: the UPI app
/// does, and people mark themselves paid.
class BillScreen extends StatefulWidget {
  final String sessionId;
  final Group group;

  /// The winning place, for the UPI note and reminders.
  final String? placeName;

  final BillService? service;

  const BillScreen({
    super.key,
    required this.sessionId,
    required this.group,
    this.placeName,
    this.service,
  });

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  late final BillService _service = widget.service ?? BillService();
  late Stream<Bill?> _bill = _service.watchBill(widget.sessionId);

  /// Re-subscribes, which re-reads the bill. Called after every write too, so
  /// the screen stays right even if realtime is slow or off; the last bill
  /// stays on screen meanwhile.
  void _refresh() {
    if (mounted) setState(() => _bill = _service.watchBill(widget.sessionId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return StreamBuilder<Bill?>(
      stream: _bill,
      builder: (context, snap) {
        final Widget body;
        Widget? bottom;
        if (snap.hasError) {
          body = _Failed(onRetry: _refresh);
        } else if (snap.connectionState == ConnectionState.waiting &&
            !snap.hasData) {
          body = const Center(child: CircularProgressIndicator());
        } else if (snap.data == null) {
          return _NewBill(
            sessionId: widget.sessionId,
            group: widget.group,
            service: _service,
            onCreated: _refresh,
          );
        } else {
          final bill = snap.data!;
          body = BillView(
            bill: bill,
            myId: _service.myId,
            placeName: widget.placeName,
            onAction: (action, [share]) => _run(bill, action, share),
          );
          if (bill.payerId == _service.myId) {
            bottom = StickyActionBar(
              child: Row(
                children: [
                  Expanded(
                    child: HangoutButton(
                      label: l10n.billChangeAmounts,
                      block: true,
                      variant: HangoutButtonVariant.secondary,
                      onPressed: () => _editShares(bill),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  HangoutIconButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: l10n.billDelete,
                    iconColor: AppColors.danger,
                    onPressed: () => _delete(bill),
                  ),
                ],
              ),
            );
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: const HangoutBackButton(),
            title: Text(l10n.billTitle, style: AppTextStyles.title),
          ),
          body: body,
          bottomNavigationBar: bottom,
        );
      },
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _run(Bill bill, BillAction action, BillShare? share) async {
    switch (action) {
      case BillAction.pay:
        await _pay(bill, share!);
      case BillAction.markMePaid:
        await _setPaid(bill, share!.userId, true);
      case BillAction.markMeUnpaid:
        await _setPaid(bill, share!.userId, false);
      case BillAction.toggleShare:
        await _toggleShare(bill, share!);
      case BillAction.remind:
        await _remind(bill);
    }
  }

  Future<void> _pay(Bill bill, BillShare share) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final uri = upiPaymentUri(
      payeeUpi: bill.payerUpi,
      payeeName: bill.payerName,
      amountPaise: share.amountPaise,
      note: widget.placeName == null
          ? l10n.billUpiNote
          : l10n.billUpiNoteAt(widget.placeName!),
    );
    final opened = await openLink(
      context,
      uri,
      failMessage: l10n.billNoUpiApp(bill.payerUpi),
    );
    if (opened) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.billAfterPayHint(bill.payerName)),
        duration: const Duration(seconds: 6),
      ));
    }
  }

  Future<void> _setPaid(Bill bill, String userId, bool paid) async {
    HapticFeedback.selectionClick();
    try {
      await _service.setPaid(bill.id, userId, paid);
      _refresh();
    } on BillException catch (e) {
      _showError(e.error);
    }
  }

  Future<void> _toggleShare(Bill bill, BillShare share) async {
    final l10n = context.l10n;
    final paid = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HangoutSheet(
        title: share.name,
        subtitle: formatRupees(share.amountPaise),
        child: share.paid
            ? HangoutButton(
                label: l10n.billMarkUnpaid,
                block: true,
                size: HangoutButtonSize.lg,
                variant: HangoutButtonVariant.secondary,
                onPressed: () => Navigator.pop(ctx, false),
              )
            : HangoutButton(
                label: l10n.billMarkPaid,
                block: true,
                size: HangoutButtonSize.lg,
                variant: HangoutButtonVariant.fresh,
                iconLeft: Icons.check_rounded,
                onPressed: () => Navigator.pop(ctx, true),
              ),
      ),
    );
    if (paid != null) await _setPaid(bill, share.userId, paid);
  }

  Future<void> _remind(Bill bill) async {
    final l10n = context.l10n;
    final text = widget.placeName == null
        ? l10n.billRemindMessage(bill.payerUpi)
        : l10n.billRemindMessageAt(widget.placeName!, bill.payerUpi);
    await openLink(context, whatsAppShareUri(text));
  }

  Future<void> _editShares(Bill bill) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EditSharesScreen(bill: bill, service: _service),
    ));
    _refresh();
  }

  Future<void> _delete(Bill bill) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.billDeleteTitle),
        content: Text(l10n.billDeleteBody, style: AppTextStyles.small),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel,
                style: AppTextStyles.smallStrong
                    .copyWith(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionDelete,
                style: AppTextStyles.smallStrong
                    .copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteBill(bill.id);
      _refresh();
    } on BillException catch (e) {
      _showError(e.error);
    }
  }

  void _showError(BillError error) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(billErrorText(context, error)),
      backgroundColor: AppColors.danger,
    ));
  }
}

String billErrorText(BuildContext context, BillError error) {
  final l10n = context.l10n;
  return switch (error) {
    BillError.alreadyExists => l10n.billAlreadyExists,
    BillError.invalidUpi => l10n.billUpiError,
    BillError.invalidTotal => l10n.billTotalError,
    BillError.sharesMustAddUp => l10n.billEditMustAddUp,
    BillError.notAllowed => l10n.billNotAllowed,
    BillError.notRevealed => l10n.billNotRevealed,
    BillError.network => l10n.errorGeneric,
  };
}

enum BillAction { pay, markMePaid, markMeUnpaid, toggleShare, remind }

// ─── An existing bill ─────────────────────────────────────────────────────────

/// Pure presentation of a bill, for the screen and for tests.
class BillView extends StatelessWidget {
  final Bill bill;
  final String? myId;
  final String? placeName;
  final void Function(BillAction action, [BillShare? share]) onAction;

  const BillView({
    super.key,
    required this.bill,
    required this.myId,
    required this.onAction,
    this.placeName,
  });

  bool get _iPaidTheBill => bill.payerId == myId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mine = myId == null ? null : bill.shareOf(myId!);
    final progress =
        bill.shares.isEmpty ? 0.0 : bill.paidCount / bill.shares.length;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.x2,
        AppSpacing.gutter,
        AppSpacing.x10 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        Text(
          formatRupees(bill.totalPaise),
          style: AppTextStyles.statNumber(40),
        ),
        const SizedBox(height: 2),
        Text(
          [
            _iPaidTheBill ? l10n.billPaidByYou : l10n.billPaidBy(bill.payerName),
            if (placeName != null) l10n.billAt(placeName!),
          ].join(' '),
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.x5),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: AppMotion.slow,
                  curve: AppMotion.easeOut,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceSunken,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accentFresh,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Text(
              l10n.billSettledProgress(bill.paidCount, bill.shares.length),
              style: AppTextStyles.smallStrong,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x6),
        if (_iPaidTheBill)
          _CollectCard(bill: bill, onRemind: () => onAction(BillAction.remind))
        else if (mine != null && !mine.paid)
          _OweCard(
            bill: bill,
            share: mine,
            onPay: () => onAction(BillAction.pay, mine),
            onPaid: () => onAction(BillAction.markMePaid, mine),
          )
        else if (mine != null)
          _SettledCard(onUndo: () => onAction(BillAction.markMeUnpaid, mine)),
        const SizedBox(height: AppSpacing.x8),
        SectionHeader(title: l10n.billSharesTitle),
        const SizedBox(height: AppSpacing.x2),
        HangoutListGroup(
          children: [
            for (final s in bill.shares) _shareRow(context, s),
          ],
        ),
      ],
    );
  }

  Widget _shareRow(BuildContext context, BillShare s) {
    final l10n = context.l10n;
    final isPayer = s.userId == bill.payerId;
    final isMe = s.userId == myId;
    final canMark = _iPaidTheBill && !isPayer;

    return HangoutListRow(
      leading: HangoutAvatar(name: s.name, imageUrl: s.avatarUrl, size: 40),
      title: isMe ? l10n.nameYou(s.name) : s.name,
      subtitle: isPayer
          ? l10n.billStatusPayer
          : (s.paid ? l10n.billStatusPaid : l10n.billStatusOwes),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatRupees(s.amountPaise),
            style: AppTextStyles.bodyStrong.copyWith(
              color: s.paid ? AppColors.textMuted : AppColors.textStrong,
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Icon(
            s.paid ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 20,
            color: s.paid ? AppColors.accentFresh : AppColors.sand400,
          ),
        ],
      ),
      showChevron: canMark,
      onTap: canMark ? () => onAction(BillAction.toggleShare, s) : null,
    );
  }
}

class _OweCard extends StatelessWidget {
  final Bill bill;
  final BillShare share;
  final VoidCallback onPay;
  final VoidCallback onPaid;

  const _OweCard({
    required this.bill,
    required this.share,
    required this.onPay,
    required this.onPaid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final amount = formatRupees(share.amountPaise);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlAll,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.billYouOwe(bill.payerName, amount), style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            l10n.billPayTo(bill.payerUpi),
            style: AppTextStyles.small,
          ),
          const SizedBox(height: AppSpacing.x5),
          HangoutButton(
            label: l10n.billPayWithUpi(amount),
            size: HangoutButtonSize.lg,
            block: true,
            onPressed: share.amountPaise > 0 ? onPay : null,
          ),
          const SizedBox(height: AppSpacing.x2),
          HangoutButton(
            label: l10n.billIvePaid,
            block: true,
            variant: HangoutButtonVariant.secondary,
            iconLeft: Icons.check_rounded,
            onPressed: onPaid,
          ),
        ],
      ),
    );
  }
}

class _SettledCard extends StatelessWidget {
  final VoidCallback onUndo;

  const _SettledCard({required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: const BoxDecoration(
        color: AppColors.accentFreshTint,
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.accentFresh),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(l10n.billYoureSettled, style: AppTextStyles.bodyStrong),
          ),
          HangoutButton(
            label: l10n.actionUndo,
            size: HangoutButtonSize.sm,
            variant: HangoutButtonVariant.ghost,
            onPressed: onUndo,
          ),
        ],
      ),
    );
  }
}

class _CollectCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onRemind;

  const _CollectCard({required this.bill, required this.onRemind});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final waiting = bill.shares.length - bill.paidCount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: bill.settled ? AppColors.accentFreshTint : AppColors.surface,
        borderRadius: AppRadius.xlAll,
        boxShadow: bill.settled ? const [] : AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            bill.settled ? l10n.billAllSettled : l10n.billWaitingOn(waiting),
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 4),
          Text(l10n.billCollectAt(bill.payerUpi), style: AppTextStyles.small),
          if (!bill.settled) ...[
            const SizedBox(height: AppSpacing.x4),
            HangoutButton(
              label: l10n.billRemind,
              block: true,
              variant: HangoutButtonVariant.secondary,
              iconLeft: Icons.chat_bubble_outline_rounded,
              onPressed: onRemind,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── A new bill ───────────────────────────────────────────────────────────────

class _NewBill extends StatefulWidget {
  final String sessionId;
  final Group group;
  final BillService service;
  final VoidCallback onCreated;

  const _NewBill({
    required this.sessionId,
    required this.group,
    required this.service,
    required this.onCreated,
  });

  @override
  State<_NewBill> createState() => _NewBillState();
}

class _NewBillState extends State<_NewBill> {
  final _total = TextEditingController();
  final _upi = TextEditingController();
  late final Set<String> _came = {
    for (final m in widget.group.members) m.userId,
  };

  bool _showErrors = false;
  bool _saving = false;

  String? get _myId => widget.service.myId;

  @override
  void initState() {
    super.initState();
    _total.addListener(() => setState(() {}));
    widget.service.getMyUpi().then((upi) {
      if (mounted && upi != null && _upi.text.isEmpty) _upi.text = upi;
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _total.dispose();
    _upi.dispose();
    super.dispose();
  }

  int? get _totalPaise => parseRupees(_total.text);
  bool get _upiOk => isValidUpiId(_upi.text);
  int get _people => {..._came, if (_myId != null) _myId!}.length;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_totalPaise == null || !_upiOk) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.createBill(
        sessionId: widget.sessionId,
        totalPaise: _totalPaise!,
        payerUpi: _upi.text,
        memberIds: _came.toList(),
      );
      widget.onCreated(); // The bill replaces this form.
    } on BillException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      // Someone beat us to it: show their bill instead of this form.
      if (e.error == BillError.alreadyExists) widget.onCreated();
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(billErrorText(context, e.error)),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = _totalPaise;
    final split = total == null ? null : splitEvenly(total, _people);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: const HangoutBackButton(),
        title: Text(l10n.billTitle, style: AppTextStyles.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.x2,
          AppSpacing.gutter,
          AppSpacing.x8,
        ),
        children: [
          Text(l10n.billNewIntro, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.x6),
          _Label(l10n.billTotalLabel),
          TextField(
            controller: _total,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: AppTextStyles.h3,
            decoration: InputDecoration(
              hintText: l10n.billTotalHint,
              prefixText: '₹ ',
              prefixStyle: AppTextStyles.h3,
              errorText: _showErrors && total == null
                  ? l10n.billTotalError
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          _Label(l10n.billUpiLabel),
          TextField(
            controller: _upi,
            enabled: !_saving,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) {
              if (_showErrors) setState(() {});
            },
            decoration: InputDecoration(
              hintText: l10n.billUpiHint,
              helperText: l10n.billUpiHelper,
              helperMaxLines: 2,
              errorMaxLines: 2,
              errorText: _showErrors && !_upiOk ? l10n.billUpiError : null,
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          SectionHeader(title: l10n.billWhoCameTitle),
          const SizedBox(height: AppSpacing.x2),
          HangoutListGroup(
            children: [
              for (final m in widget.group.members)
                _memberRow(context, m),
            ],
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (split != null && split.isNotEmpty) ...[
              Text(
                split.first == split.last
                    ? l10n.billEachAmount(_people, formatRupees(split.first))
                    : l10n.billEachUneven(
                        formatRupees(split.first),
                        formatRupees(split.last),
                        _people,
                      ),
                textAlign: TextAlign.center,
                style: AppTextStyles.smallStrong,
              ),
              const SizedBox(height: AppSpacing.x2),
            ],
            HangoutButton(
              label: total == null
                  ? l10n.billCreateButtonEmpty
                  : l10n.billCreateButton(formatRupees(total)),
              size: HangoutButtonSize.lg,
              block: true,
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberRow(BuildContext context, GroupMember m) {
    final l10n = context.l10n;
    final isMe = m.userId == _myId;
    final came = isMe || _came.contains(m.userId);

    return HangoutListRow(
      leading: HangoutAvatar(name: m.displayName, imageUrl: m.avatarUrl, size: 40),
      title: isMe ? l10n.nameYou(m.displayName) : m.displayName,
      subtitle: isMe ? l10n.billYouPaid : null,
      trailing: Checkbox(
        value: came,
        onChanged: isMe || _saving
            ? null
            : (v) => setState(() {
                  v == true ? _came.add(m.userId) : _came.remove(m.userId);
                }),
      ),
      onTap: isMe || _saving
          ? null
          : () => setState(() {
                came ? _came.remove(m.userId) : _came.add(m.userId);
              }),
    );
  }
}

// ─── Custom amounts ───────────────────────────────────────────────────────────

/// The payer's escape hatch from an even split: set what each person owes.
/// Saves only when the amounts add up to the total exactly.
class EditSharesScreen extends StatefulWidget {
  final Bill bill;
  final BillService service;

  const EditSharesScreen({super.key, required this.bill, required this.service});

  @override
  State<EditSharesScreen> createState() => _EditSharesScreenState();
}

class _EditSharesScreenState extends State<EditSharesScreen> {
  late final Map<String, TextEditingController> _fields = {
    for (final s in widget.bill.shares)
      s.userId: TextEditingController(text: _editable(s.amountPaise))
        ..addListener(() => setState(() {})),
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _editable(int paise) {
    final rupees = paise ~/ 100;
    final rest = paise % 100;
    return rest == 0 ? '$rupees' : '$rupees.${rest.toString().padLeft(2, '0')}';
  }

  /// Like [parseRupees], but zero is allowed: someone who didn't eat.
  static int? _parse(String text) {
    final t = text.trim();
    if (t.isEmpty || RegExp(r'^0+(\.0{0,2})?$').hasMatch(t)) return 0;
    return parseRupees(t);
  }

  Map<String, int?> get _amounts =>
      {for (final e in _fields.entries) e.key: _parse(e.value.text)};

  void _evenly() {
    final ids = [for (final s in widget.bill.shares) s.userId];
    final parts = splitEvenly(widget.bill.totalPaise, ids.length);
    for (var i = 0; i < ids.length; i++) {
      _fields[ids[i]]!.text = _editable(parts[i]);
    }
  }

  Future<void> _save(Map<String, int> amounts) async {
    setState(() => _saving = true);
    try {
      await widget.service.setShares(widget.bill.id, amounts);
      if (mounted) Navigator.of(context).pop();
    } on BillException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(billErrorText(context, e.error)),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final amounts = _amounts;
    final valid = amounts.values.every((a) => a != null);
    final sum = valid ? amounts.values.fold<int>(0, (a, b) => a + b!) : null;
    final diff = sum == null ? null : widget.bill.totalPaise - sum;

    final (String status, Color color) = switch (diff) {
      null => (l10n.billEditAmountError, AppColors.danger),
      0 => (l10n.billEditAddsUp, AppColors.avocado700),
      > 0 => (l10n.billEditLeft(formatRupees(diff)), AppColors.warning),
      _ => (l10n.billEditOver(formatRupees(-diff)), AppColors.danger),
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: const HangoutBackButton(),
        title: Text(l10n.billEditTitle, style: AppTextStyles.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.x2,
          AppSpacing.gutter,
          AppSpacing.x8,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.billEditTotal(formatRupees(widget.bill.totalPaise)),
                  style: AppTextStyles.bodyStrong,
                ),
              ),
              HangoutButton(
                label: l10n.billEditEvenly,
                size: HangoutButtonSize.sm,
                variant: HangoutButtonVariant.ghost,
                onPressed: _saving ? null : _evenly,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          for (final s in widget.bill.shares) ...[
            // One node for TalkBack: "Friend 2, ₹ 600, edit box".
            MergeSemantics(
              child: Row(
              children: [
                HangoutAvatar(name: s.name, imageUrl: s.avatarUrl, size: 36),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: Text(
                    s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong,
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                SizedBox(
                  width: 132,
                  child: TextField(
                    controller: _fields[s.userId],
                    enabled: !_saving,
                    textAlign: TextAlign.end,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      isDense: true,
                      errorText: amounts[s.userId] == null ? '' : null,
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                    ),
                  ),
                ),
              ],
            ),
            ),
            const SizedBox(height: AppSpacing.x3),
          ],
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: AppTextStyles.smallStrong.copyWith(color: color),
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            HangoutButton(
              label: l10n.actionSave,
              size: HangoutButtonSize.lg,
              block: true,
              loading: _saving,
              onPressed: diff == 0
                  ? () => _save({
                        for (final e in amounts.entries) e.key: e.value!,
                      })
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.x2),
        child: Text(text, style: AppTextStyles.smallStrong),
      );
}

class _Failed extends StatelessWidget {
  final VoidCallback onRetry;

  const _Failed({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.billLoadFailed, style: AppTextStyles.bodyStrong),
          const SizedBox(height: 4),
          Text(l10n.errorCheckConnection, style: AppTextStyles.small),
          const SizedBox(height: AppSpacing.x3),
          HangoutButton(
            label: l10n.actionTryAgain,
            size: HangoutButtonSize.sm,
            variant: HangoutButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
