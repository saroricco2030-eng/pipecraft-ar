import 'dart:convert';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/extensions/build_context_ext.dart';
import '../../core/constants/pipe_specs.dart';
import '../../core/storage/prefs_keys.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ar_measure_service.dart';
import 'bend_entry.dart';
import 'bending_calculator.dart';
import 'route_painter.dart';
import 'widgets/sticky_input_bar.dart';

const _angles = [30.0, 45.0, 60.0, 90.0];

// ─────────────────────────────────────────────────────────

class BendingScreen extends StatefulWidget {
  final Machine machine;
  final int selectedOd;

  const BendingScreen({
    super.key,
    required this.machine,
    required this.selectedOd,
  });

  @override
  State<BendingScreen> createState() => _BendingScreenState();
}

class _BendingScreenState extends State<BendingScreen> {
  double _selectedAngle = 90;
  final _insertController = TextEditingController(text: '150');
  BendDirection? _selectedDirection;
  final List<BendEntry> _bends = [];
  final _scrollController = ScrollController();
  bool _measuring = false;
  bool _isLoading = true;
  final Set<int> _expandedCards = {};

  @override
  void initState() {
    super.initState();
    _insertController.addListener(_onInputChanged);
    _loadData();
  }

  @override
  void dispose() {
    _insertController.removeListener(_onInputChanged);
    _insertController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onInputChanged() => setState(() {});

  // ─── Preview calculations ───────────────────────────────

  int get _previewSetAngle {
    final sb = springBack[widget.machine]?[widget.selectedOd] ?? 2;
    return (_selectedAngle + sb).round();
  }

  int get _previewArcLength {
    final spec = pipeSpecs[widget.selectedOd];
    if (spec == null) return 0;
    return (spec.minRadius * (_selectedAngle * pi / 180)).round();
  }

  int get _previewConsumed {
    final insert = double.tryParse(_insertController.text) ?? 0;
    return (insert + _previewArcLength).round();
  }

  // ─── Persistence ──────────────────────────────────────

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(PrefsKeys.bendingData);
    if (json == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 1) 최상위 JSON이 깨졌으면 저장본 초기화
    List<dynamic> rawList;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) {
        throw const FormatException('root is not a list');
      }
      rawList = decoded;
    } catch (e) {
      debugPrint('BendingScreen: root JSON decode failed — clearing');
      await prefs.remove(PrefsKeys.bendingData);
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 2) 개별 엔트리 단위로 복구 — 하나 깨져도 나머지는 살림
    final entries = <BendEntry>[];
    int failed = 0;
    for (final e in rawList) {
      if (e is! Map<String, dynamic>) {
        failed++;
        continue;
      }
      try {
        entries.add(BendEntry.fromJson(e));
      } catch (err) {
        failed++;
        debugPrint('BendingScreen: skipped invalid entry ($err)');
      }
    }

    // 3) 일부만 유효하면 저장본 동기화 (다음 로딩 오버헤드 방지)
    if (failed > 0 && entries.isNotEmpty) {
      try {
        await prefs.setString(
          PrefsKeys.bendingData,
          jsonEncode(entries.map((b) => b.toJson()).toList()),
        );
      } catch (_) {
        // best-effort
      }
    }

    if (mounted) {
      setState(() {
        _bends.addAll(entries);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PrefsKeys.bendingData,
      jsonEncode(_bends.map((b) => b.toJson()).toList()),
    );
  }

  // ─── Direction label helpers (i18n) ─────────────────────

  String _dirLabel(BendDirection dir) => switch (dir) {
    BendDirection.up => context.l10n.bendingDirectionUp,
    BendDirection.down => context.l10n.bendingDirectionDown,
    BendDirection.left => context.l10n.bendingDirectionLeft,
    BendDirection.right => context.l10n.bendingDirectionRight,
  };

  String _dirShortLabel(BendDirection dir) => switch (dir) {
    BendDirection.up => context.l10n.bendingDirectionShortUp,
    BendDirection.down => context.l10n.bendingDirectionShortDown,
    BendDirection.left => context.l10n.bendingDirectionShortLeft,
    BendDirection.right => context.l10n.bendingDirectionShortRight,
  };

  // ─── Actions ────────────────────────────────────────────

  void _addBend() {
    final insert = double.tryParse(_insertController.text);
    if (insert == null || insert <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.bendingValidationInsertLength)),
      );
      return;
    }
    if (_selectedDirection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.bendingValidationSelectDirection)),
      );
      return;
    }
    final result = BendingCalculator.calculate(
      insertLength: insert,
      targetAngle: _selectedAngle,
      pipeOd: widget.selectedOd,
      machine: widget.machine,
    );
    HapticFeedback.mediumImpact();
    setState(() {
      _bends.add(
        BendEntry(
          pipeOd: widget.selectedOd,
          machine: widget.machine,
          insertLen: insert,
          angle: _selectedAngle,
          direction: _selectedDirection!,
          result: result,
        ),
      );
      _selectedDirection = null;
      _insertController.clear();
    });
    _saveData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _deleteBend(int i) {
    HapticFeedback.lightImpact();
    setState(() {
      _bends.removeAt(i);
      _expandedCards.remove(i);
    });
    _saveData();
  }

  void _confirmResetAll() {
    if (_bends.isEmpty) return;
    final c = context.appColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.bendingConfirmResetTitle),
        content: Text(context.l10n.bendingResetConfirmMessage(_bends.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              setState(() {
                _bends.clear();
                _expandedCards.clear();
                _selectedDirection = null;
                _insertController.clear();
              });
              _saveData();
            },
            child: Text(
              context.l10n.commonReset,
              style: TextStyle(color: c.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _copyBendInfo(int i, BendEntry entry) {
    HapticFeedback.lightImpact();
    final text = context.l10n.bendingCopyInfo(
      i + 1,
      entry.pipeOd,
      entry.angle.round(),
      _dirLabel(entry.direction),
      entry.result.setAngle.round(),
      entry.result.arcLength.round(),
      entry.insertLen.round(),
    );
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.commonCopiedToClipboard),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _copyAllSummary() {
    HapticFeedback.lightImpact();
    final lines = <String>[];
    for (var i = 0; i < _bends.length; i++) {
      final b = _bends[i];
      lines.add(
        context.l10n.bendingSummaryCopyLine(
          i + 1,
          b.pipeOd,
          b.angle.round(),
          _dirLabel(b.direction),
          b.result.setAngle.round(),
          b.insertLen.round(),
        ),
      );
    }
    final totalConsumed = _bends.fold<double>(
      0,
      (sum, b) => sum + b.result.consumedLength,
    );
    lines.add(context.l10n.bendingTotalConsumed(totalConsumed.round()));
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.bendingSummaryCopied),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(child: CircularProgressIndicator(color: c.primary)),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _buildHeroResultZone(c),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_bends.isNotEmpty) ...[
                    _buildRoutePreview(c),
                    const SizedBox(height: 10),
                    _buildSummaryCard(c),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _bends.length; i++)
                      Dismissible(
                        key: ValueKey('bend_${_bends[i].hashCode}_$i'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: c.danger,
                            borderRadius: BorderRadius.circular(cardRadius),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: Icon(Icons.delete_outline, color: c.onPrimary),
                        ),
                        onDismissed: (_) => _deleteBend(i),
                        child: _buildCompactBendCard(i, _bends[i], c),
                      ),
                  ] else ...[
                    const SizedBox(height: 40),
                    _buildEmptyState(c),
                  ],
                ],
              ),
            ),
          ),
          StickyInputBar(
            insertController: _insertController,
            angles: _angles,
            selectedAngle: _selectedAngle,
            onAngleChanged: (a) => setState(() => _selectedAngle = a),
            selectedDirection: _selectedDirection,
            onDirectionChanged: (d) => setState(() => _selectedDirection = d),
            onAdd: _addBend,
            onArMeasure: _measureForInsert,
            measuring: _measuring,
            insertHint: '0',
            addLabel: context.l10n.bendingAddButton,
            mmUnit: 'mm',
            arMeasuringLabel: context.l10n.arMeasuringLabel,
            directionLabelFor: context.l10n.bendingDirectionSelectionLabel(''),
          ),
        ],
      ),
    );
  }

  // ─── Hero Result Zone ──────────────────────────────────

  Widget _buildHeroResultZone(AppColors c) {
    final l = context.l10n;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.card, c.background],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Text(
            l.bendingHeroSetAngle,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: c.text3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$_previewSetAngle',
                style: TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                  letterSpacing: -2,
                  height: 1.0,
                ),
              ),
              Text(
                '°',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: c.text3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _heroSubItem(
                l.bendingHeroTarget,
                '${_selectedAngle.toInt()}°',
                c,
              ),
              const SizedBox(width: 24),
              _heroSubItem(l.bendingHeroArc, '${_previewArcLength}mm', c),
              const SizedBox(width: 24),
              _heroSubItem(l.bendingHeroConsumed, '${_previewConsumed}mm', c),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroSubItem(String label, String value, AppColors c) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: c.text3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'DM Mono',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: c.text,
          ),
        ),
      ],
    );
  }

  // ─── AR 측정 → 삽입 입력 필드에 넣기 ───────────────────

  Future<void> _measureForInsert() async {
    if (_measuring) return;
    setState(() => _measuring = true);
    final distance = await ArMeasure.measureWithUi(context);
    if (!mounted) return;
    if (distance != null) {
      setState(() {
        _insertController.text = distance.round().toString();
        _measuring = false;
      });
    } else {
      setState(() => _measuring = false);
    }
  }

  // ─── Compact Bend Card (접기/펼치기) ──────────────────

  Widget _buildCompactBendCard(int i, BendEntry entry, AppColors c) {
    final expanded = _expandedCards.contains(i);
    final sb = (entry.result.setAngle - entry.angle).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: cardDeco(c),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Collapsed header — always visible
          InkWell(
            onTap: () => setState(() {
              if (expanded) {
                _expandedCards.remove(i);
              } else {
                _expandedCards.add(i);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: entry.done ? c.accent : c.headerBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontFamily: 'DM Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: entry.done ? c.onPrimary : c.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.bendingCardAngleDir(
                            entry.angle.round(),
                            _dirShortLabel(entry.direction),
                          ),
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: c.text,
                          ),
                        ),
                        Text(
                          context.l10n.bendingCardInsertOd(
                            entry.insertLen.round(),
                            entry.pipeOd,
                          ),
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            color: c.text3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${entry.result.setAngle.round()}°',
                    style: TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: c.text3,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          if (expanded) ...[
            Divider(height: 1, color: c.border),
            // Result row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _resultCol(
                    context.l10n.bendingSetAngle,
                    '${entry.result.setAngle.round()}°',
                    c,
                    isAccent: true,
                  ),
                  Container(width: 1, height: 36, color: c.border),
                  _resultCol(
                    context.l10n.bendingArcLength,
                    '${entry.result.arcLength.round()} mm',
                    c,
                  ),
                  Container(width: 1, height: 36, color: c.border),
                  _resultCol(
                    context.l10n.bendingShorteningAmount,
                    '${entry.result.shortenLength.round()} mm',
                    c,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.border),
            // Steps
            _buildStepRow(
              entry,
              0,
              'A',
              context.l10n.bendingStepInsertMark(entry.insertLen.round()),
              context.l10n.bendingStepInsertHint(entry.insertLen.round()),
              c,
            ),
            _buildStepRow(
              entry,
              1,
              'B',
              context.l10n.bendingStepDirectionCheck(
                _dirLabel(entry.direction),
              ),
              context.l10n.bendingStepDirectionWarning,
              c,
            ),
            _buildStepRow(
              entry,
              2,
              'C',
              context.l10n.bendingStepSetAngle(entry.result.setAngle.round()),
              context.l10n.bendingStepAngleTarget(entry.angle.round(), sb),
              c,
            ),
            _buildStepRow(
              entry,
              3,
              'D',
              context.l10n.bendingStepAngleVerify,
              context.l10n.bendingStepAngleTolerance(entry.angle.round()),
              c,
            ),
            // Actions row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.copy, size: 16, color: c.text3),
                    tooltip: context.l10n.commonCopyTooltip,
                    onPressed: () => _copyBendInfo(i, entry),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: c.text3),
                    tooltip: context.l10n.commonDeleteTooltip,
                    onPressed: () => _deleteBend(i),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultCol(
    String label,
    String value,
    AppColors c, {
    bool isAccent = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              color: c.text3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DM Mono',
              fontSize: isAccent ? 24 : 14,
              fontWeight: FontWeight.w700,
              color: isAccent ? c.accent : c.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(
    BendEntry entry,
    int stepIndex,
    String letter,
    String title,
    String subtitle,
    AppColors c,
  ) {
    final checked = entry.stepsDone[stepIndex];
    return Semantics(
      label: '$title - step $letter',
      checked: checked,
      child: InkWell(
        onTap: () {
          setState(() => entry.stepsDone[stepIndex] = !checked);
          HapticFeedback.selectionClick();
          _saveData();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: checked ? c.accent : c.stepUnchecked,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: checked ? c.onPrimary : c.text2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                        decoration: checked ? TextDecoration.lineThrough : null,
                        decorationColor: c.text3,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: c.text3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                checked ? Icons.check_circle : Icons.circle_outlined,
                color: checked ? c.accent : c.text3,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────

  Widget _buildEmptyState(AppColors c) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.straighten,
            size: 64,
            color: c.text3.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.bendingEmptyTitle,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.text3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.bendingEmptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: c.text3.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Route Preview (Technical Drawing) ───────────────

  Widget _buildRoutePreview(AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.diagramBg,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: c.diagramBorder),
      ),
      height: 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: CustomPaint(
          painter: RoutePainter(bends: _bends, colors: c),
          size: Size.infinite,
        ),
      ),
    );
  }

  // ─── Summary Card ─────────────────────────────────────

  Widget _buildSummaryCard(AppColors c) {
    final total = _bends.length;
    final doneCount = _bends.where((b) => b.done).length;
    final totalConsumed = _bends.fold<double>(
      0,
      (sum, b) => sum + b.result.consumedLength,
    );

    return Container(
      decoration: cardDeco(c),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.bendingSummaryCardTitle,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.text,
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.bendingProgressCounter(doneCount, total),
                style: TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.accent,
                ),
              ),
              const SizedBox(width: 8),
              // 복사 (터치 타겟 48dp)
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: Icon(Icons.copy_rounded, size: 18, color: c.text3),
                  tooltip: context.l10n.bendingCopyAllTooltip,
                  onPressed: _copyAllSummary,
                  padding: EdgeInsets.zero,
                ),
              ),
              // 초기화 (터치 타겟 48dp)
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: Icon(
                    Icons.delete_sweep_rounded,
                    size: 20,
                    color: c.danger,
                  ),
                  tooltip: context.l10n.bendingConfirmResetTitle,
                  onPressed: _confirmResetAll,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.bendingTotalConsumed(totalConsumed.round()),
            style: TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 13,
              color: c.text2,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? doneCount / total : 0,
              minHeight: 6,
              backgroundColor: c.stepUnchecked,
              valueColor: AlwaysStoppedAnimation(c.accent),
            ),
          ),
        ],
      ),
    );
  }
}
