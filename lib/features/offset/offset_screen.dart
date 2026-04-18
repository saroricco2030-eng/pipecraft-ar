import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/pipe_specs.dart';
import '../../core/input/single_decimal_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/extensions/build_context_ext.dart';
import '../../services/ar_measure_service.dart';
import '../bending/bending_calculator.dart';
import 'offset_painter.dart';

const _angles = [30.0, 45.0, 60.0];

// ─────────────────────────────────────────────────────────

class OffsetScreen extends StatefulWidget {
  final Machine machine;
  final int selectedOd;

  const OffsetScreen({
    super.key,
    required this.machine,
    required this.selectedOd,
  });

  @override
  State<OffsetScreen> createState() => _OffsetScreenState();
}

class _OffsetScreenState extends State<OffsetScreen> {
  final _heightCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _preCtrl = TextEditingController();
  final _postCtrl = TextEditingController();
  double _selectedAngle = 45;
  OffsetResult? _result;
  List<bool> _stepsDone = [false, false, false, false, false];
  bool _measuring = false;

  /// 입력 키 이벤트 디바운스. 매 키스트로크마다 계산·리페인트 방지.
  Timer? _debounce;
  static const _debounceDelay = Duration(milliseconds: 160);

  double get _springBack =>
      springBack[widget.machine]?[widget.selectedOd]?.toDouble() ?? 2.0;

  @override
  void dispose() {
    _debounce?.cancel();
    _heightCtrl.dispose();
    _widthCtrl.dispose();
    _preCtrl.dispose();
    _postCtrl.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, _calculate);
  }

  void _calculate() {
    if (!mounted) return;
    final h = double.tryParse(_heightCtrl.text);
    final w = double.tryParse(_widthCtrl.text);
    final pre = double.tryParse(_preCtrl.text);
    final post = double.tryParse(_postCtrl.text);

    // 값 부재 or NaN/Infinity 방어
    if (h == null || w == null || pre == null || post == null ||
        !h.isFinite || !w.isFinite || !pre.isFinite || !post.isFinite) {
      setState(() => _result = null);
      return;
    }
    if (h <= 0) {
      setState(() => _result = null);
      if (h < 0) _showValidationError(context.l10n.offsetValidationHeightPositive);
      return;
    }
    if (w < 0 || pre < 0 || post < 0) {
      setState(() => _result = null);
      _showValidationError(context.l10n.offsetValidationPositive);
      return;
    }

    try {
      final result = OffsetCalculator.calculate(
        obsHeight: h,
        obsWidth: w,
        preDist: pre,
        postDist: post,
        angle: _selectedAngle,
      );
      setState(() {
        _result = result;
        _stepsDone = [false, false, false, false, false];
      });
    } on ArgumentError {
      // 각도 0°/90° 등 예외적 케이스 — UI는 null 결과로 복귀
      setState(() => _result = null);
    }
  }

  void _showValidationError(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _confirmResetInputs() {
    final c = context.appColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.offsetConfirmResetTitle),
        content: Text(context.l10n.offsetResetConfirmMessage),
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
                _heightCtrl.clear();
                _widthCtrl.clear();
                _preCtrl.clear();
                _postCtrl.clear();
                _result = null;
                _stepsDone = [false, false, false, false, false];
              });
            },
            child: Text(context.l10n.commonReset,
                style: TextStyle(color: c.primary)),
          ),
        ],
      ),
    );
  }

  void _copyResult() {
    if (_result == null) return;
    HapticFeedback.lightImpact();
    final r = _result!;
    final setAngle = (_selectedAngle + _springBack).round();
    final text = context.l10n.offsetCopyText(
        r.b1Insert.round(), r.b2Insert.round(), setAngle, r.totalLength.round());
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.commonCopiedToClipboard),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final r = _result;

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          // Hero Result (고정, 스크롤 밖)
          if (r != null) _buildHeroResult(r, c),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (r != null) ...[
                    _buildOffsetDiagram(
                      r,
                      double.tryParse(_heightCtrl.text) ?? 0,
                      double.tryParse(_widthCtrl.text) ?? 0,
                      c,
                    ),
                    const SizedBox(height: 10),
                    _buildCompactStepGuide(r, c),
                    const SizedBox(height: 12),
                  ],
                  // 입력 카드 — 항상 노출 (토글 제거)
                  _buildInputCard(c),
                  const SizedBox(height: 12),
                  _buildAngleButtons(c),
                ],
              ),
            ),
          ),
          _buildArButton(c),
        ],
      ),
    );
  }

  // ─── Hero Result Zone ────────────────────────────────────

  Widget _buildHeroResult(OffsetResult r, AppColors c) {
    final setAngle = (_selectedAngle + _springBack).round();
    final l = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          // B1 / B2 큰 수치
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // B1
              Column(
                children: [
                  Text(
                    l.offsetResultB1Insert,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.text3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${r.b1Insert.round()}',
                          style: TextStyle(
                            fontFamily: 'DM Mono',
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: c.accent,
                          ),
                        ),
                        TextSpan(
                          text: 'mm',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            color: c.text3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              // B2
              Column(
                children: [
                  Text(
                    l.offsetResultB2Insert,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.text3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${r.b2Insert.round()}',
                          style: TextStyle(
                            fontFamily: 'DM Mono',
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: c.accent,
                          ),
                        ),
                        TextSpan(
                          text: 'mm',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            color: c.text3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mini stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniStat(l.offsetMiniStatSetAngle, '$setAngle°', c.accent, c),
              const SizedBox(width: 20),
              _buildMiniStat(
                  l.offsetMiniStatSlope, '${r.offsetLength.round()}mm', c.text, c),
              const SizedBox(width: 20),
              _buildMiniStat(
                  l.offsetMiniStatTotal, '${r.totalLength.round()}mm', c.text, c),
            ],
          ),
          const SizedBox(height: 8),
          // 복사 버튼
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _copyResult,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy, size: 14, color: c.text3),
                    const SizedBox(width: 4),
                    Text(
                      l.offsetCopyResultButton,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: c.text3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color valueColor, AppColors c) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: c.text3,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Compact Step Guide ──────────────────────────────────

  Widget _buildCompactStepGuide(OffsetResult r, AppColors c) {
    final setAngle = (_selectedAngle + _springBack).round();
    final l = context.l10n;

    final steps = [
      (title: l.offsetStepB1MarkShort, value: '${r.b1Insert.round()}mm'),
      (title: l.offsetStepB1BendShort, value: '$setAngle°'),
      (title: l.offsetStepB2MarkShort, value: '${r.b2Insert.round()}mm'),
      (title: l.offsetStepB2BendShort, value: '$setAngle°'),
      (title: l.offsetStepParallelShort, value: ''),
    ];

    return Container(
      decoration: cardDeco(c),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _buildCompactStepRow(
              index: i,
              title: steps[i].title,
              value: steps[i].value,
              isLast: i == steps.length - 1,
              c: c,
            ),
        ],
      ),
    );
  }

  Widget _buildCompactStepRow({
    required int index,
    required String title,
    required String value,
    required bool isLast,
    required AppColors c,
  }) {
    final done = _stepsDone[index];

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _stepsDone[index] = !_stepsDone[index]);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            // 번호 원
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done ? c.accent : c.headerBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: done ? c.onPrimary : c.text2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 타이틀
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: c.text3,
                ),
              ),
            ),
            // 값
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                ),
              )
            else
              Icon(Icons.check_rounded, size: 20, color: c.accent),
          ],
        ),
      ),
    );
  }


  // ─── 입력 카드 ─────────────────────────────────────────

  Widget _buildInputCard(AppColors c) {
    return Container(
      decoration: cardDeco(c),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                icon: Icon(Icons.refresh_rounded, size: 16, color: c.text3),
                tooltip: context.l10n.offsetConfirmResetTitle,
                onPressed: _confirmResetInputs,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                  child: _inputField(
                      context.l10n.offsetLabelObstacleHeight, _heightCtrl, c)),
              const SizedBox(width: 12),
              Expanded(
                  child: _inputField(
                      context.l10n.offsetLabelObstacleWidth, _widthCtrl, c)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _inputField(
                      context.l10n.offsetLabelPreClearance, _preCtrl, c)),
              const SizedBox(width: 12),
              Expanded(
                  child: _inputField(
                      context.l10n.offsetLabelPostClearance, _postCtrl, c)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: c.text3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            const SingleDecimalFormatter(),
            const MaxValueFormatter(),
            LengthLimitingTextInputFormatter(8),
          ],
          style: TextStyle(
            fontFamily: 'DM Mono',
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: c.text,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: '0',
            hintStyle: TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 22,
              color: c.text3.withValues(alpha: 0.4),
            ),
          ),
          onChanged: (_) => _onInputChanged(),
        ),
      ],
    );
  }

  // ─── 각도 선택 ─────────────────────────────────────────

  Widget _buildAngleButtons(AppColors c) {
    return Row(
      children: _angles.map((a) {
        final selected = a == _selectedAngle;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: a == _angles.last ? 0 : 8),
            child: Semantics(
              label: '${a.toInt()}° angle',
              selected: selected,
              button: true,
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedAngle = a);
                  _calculate();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  decoration: BoxDecoration(
                    color: selected ? c.chipSelected : c.chipUnselected,
                    borderRadius: BorderRadius.circular(cardRadius),
                    border: Border.all(
                      color: selected ? c.chipSelected : c.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${a.toInt()}°',
                    style: TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? c.chipSelectedText : c.text2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── 측면 다이어그램 ───────────────────────────────────

  Widget _buildOffsetDiagram(
      OffsetResult r, double obsHeight, double obsWidth, AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.headerBg,
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Text(
              context.l10n.offsetDiagramTitle,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c.text2,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Container(
            color: c.diagramBg,
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: OffsetPainter(
                result: r,
                angle: _selectedAngle,
                obsHeight: obsHeight,
                obsWidth: obsWidth,
                obstacleLabel: context.l10n.offsetDiagramObstacleLabel,
                colors: c,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  // ─── AR 측정 → 필드 선택 바텀시트 ─────────────────────

  Future<void> _measureThenPickField() async {
    if (_measuring) return;
    setState(() => _measuring = true);
    final distance = await ArMeasure.measureWithUi(context);
    if (!mounted) return;
    setState(() => _measuring = false);
    if (distance != null) {
      _autoApplyToFirstEmpty(distance);
    }
  }

  /// AR 측정값을 [자동으로] 첫 빈 필드에 적용.
  /// 모든 필드가 이미 차 있으면 [폭] 필드로 fallback.
  /// SnackBar [변경] 액션으로 다른 필드로 옮길 수 있음.
  void _autoApplyToFirstEmpty(double distance) {
    final l = context.l10n;
    final rounded = distance.round().toString();

    final candidates = [
      (ctrl: _heightCtrl, name: l.offsetLabelObstacleHeight),
      (ctrl: _widthCtrl, name: l.offsetLabelObstacleWidth),
      (ctrl: _preCtrl, name: l.offsetLabelPreClearance),
      (ctrl: _postCtrl, name: l.offsetLabelPostClearance),
    ];

    final target = candidates.firstWhere(
      (f) => f.ctrl.text.isEmpty,
      orElse: () => candidates[1], // 전부 차있으면 폭에 덮어쓰기 (자주 바뀌는 값)
    );

    HapticFeedback.lightImpact();
    setState(() {
      target.ctrl.text = rounded;
    });
    _calculate();

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
              l.offsetArAutoAppliedFormat(distance.round(), target.name)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: l.commonChange,
            onPressed: () {
              if (!mounted) return;
              _showFieldPickerForDistance(distance);
            },
          ),
        ),
      );
  }

  void _showFieldPickerForDistance(double distance) {
    final c = context.appColors;
    final distStr = '${distance.round()} mm';
    final fields = [
      (context.l10n.offsetLabelObstacleHeight, _heightCtrl),
      (context.l10n.offsetLabelObstacleWidth, _widthCtrl),
      (context.l10n.offsetLabelPreClearance, _preCtrl),
      (context.l10n.offsetLabelPostClearance, _postCtrl),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grab handle
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(top: 4, bottom: 8),
                    decoration: BoxDecoration(
                      color: c.text3.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    distStr,
                    style: TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    context.l10n.offsetSelectFieldHint,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: c.text3,
                    ),
                  ),
                ),
                Divider(height: 1, color: c.border),
                ...fields.map((f) => ListTile(
                      leading:
                          Icon(Icons.straighten, size: 20, color: c.primary),
                      title: Text(
                        f.$1,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 15,
                          color: c.text,
                        ),
                      ),
                      trailing: Text(
                        f.$2.text.isEmpty ? '-' : '${f.$2.text} mm',
                        style: TextStyle(
                          fontFamily: 'DM Mono',
                          fontSize: 13,
                          color: c.text3,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          f.$2.text = distance.round().toString();
                        });
                        _calculate();
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 하단 AR 버튼 ─────────────────────────────────────

  Widget _buildArButton(AppColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: c.background,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _measuring ? null : () => _measureThenPickField(),
          icon: _measuring
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.onPrimary,
                  ),
                )
              : const Icon(Icons.camera_alt_outlined, size: 20),
          label: Text(
            _measuring
                ? context.l10n.arMeasuringLabel
                : context.l10n.arMeasureInputLabel,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: c.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

