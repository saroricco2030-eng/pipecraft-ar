import 'dart:math' show sin, cos, sqrt, pi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/pipe_specs.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ar_measure_service.dart';
import '../bending/bending_calculator.dart';

const _angles = [30.0, 45.0, 60.0];
final _pipeOds = pipeSpecs.keys.toList();

// ─────────────────────────────────────────────────────────

class OffsetScreen extends StatefulWidget {
  const OffsetScreen({super.key});

  @override
  State<OffsetScreen> createState() => _OffsetScreenState();
}

class _OffsetScreenState extends State<OffsetScreen> {
  Machine _machine = Machine.robend4000;
  int _selectedOd = 15;
  final _heightCtrl = TextEditingController(text: '100');
  final _widthCtrl = TextEditingController(text: '50');
  final _preCtrl = TextEditingController(text: '150');
  final _postCtrl = TextEditingController(text: '150');
  double _selectedAngle = 45;
  OffsetResult? _result;
  List<bool> _stepsDone = [false, false, false, false, false];
  bool _measuring = false;

  double get _springBack => springBack[_machine]?[_selectedOd]?.toDouble() ?? 2.0;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _widthCtrl.dispose();
    _preCtrl.dispose();
    _postCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final h = double.tryParse(_heightCtrl.text);
    final w = double.tryParse(_widthCtrl.text);
    final pre = double.tryParse(_preCtrl.text);
    final post = double.tryParse(_postCtrl.text);
    if (h == null || w == null || pre == null || post == null) {
      setState(() => _result = null);
      return;
    }
    if (h <= 0 || w < 0 || pre < 0 || post < 0) {
      setState(() => _result = null);
      if (h <= 0 && h != 0) {
        _showValidationError('장애물 높이는 양수 값을 입력하세요');
      } else if (w < 0 || pre < 0 || post < 0) {
        _showValidationError('양수 값을 입력하세요');
      }
      return;
    }
    if (h == 0) {
      setState(() => _result = null);
      return;
    }

    setState(() {
      _result = OffsetCalculator.calculate(
        obsHeight: h,
        obsWidth: w,
        preDist: pre,
        postDist: post,
        angle: _selectedAngle,
      );
      _stepsDone = [false, false, false, false, false];
    });
  }

  void _showValidationError(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _copyResult() {
    if (_result == null) return;
    final r = _result!;
    final setAngle = (_selectedAngle + _springBack).round();
    final text =
        '오프셋: B1=${r.b1Insert.round()}mm B2=${r.b2Insert.round()}mm'
        ' | 세팅 $setAngle° | 총소요 ${r.totalLength.round()}mm';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('클립보드에 복사되었습니다'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.card,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              'Offset Bending',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.text,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMachineToggle(c),
                  const SizedBox(height: 6),
                  _buildSpringBackInfo(c),
                  const SizedBox(height: 16),
                  _buildSectionLabel('관경 (MM)', c),
                  const SizedBox(height: 8),
                  _buildPipeChips(c),
                  const SizedBox(height: 16),
                  _buildInputCard(c),
                  const SizedBox(height: 16),
                  _buildSectionLabel('오프셋 각도', c),
                  const SizedBox(height: 8),
                  _buildAngleButtons(c),
                  const SizedBox(height: 20),
                  if (_result != null) ...[
                    _buildResultCard(_result!, c),
                    const SizedBox(height: 12),
                    _buildStepGuideCard(_result!, c),
                    const SizedBox(height: 12),
                    _buildOffsetDiagram(
                      _result!,
                      double.tryParse(_heightCtrl.text) ?? 0,
                      double.tryParse(_widthCtrl.text) ?? 0,
                      c,
                    ),
                  ] else ...[
                    _buildNoResultHint(c),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildArButton(c),
        ],
      ),
    );
  }

  // ─── 스프링백 정보 ─────────────────────────────────────

  Widget _buildSpringBackInfo(AppColors c) {
    final sb = springBack[_machine]?[_selectedOd]?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        '현재 보정: ${_machine.label} · ${_selectedOd}mm → +$sb°',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          color: c.text3,
        ),
      ),
    );
  }

  // ─── 결과 없음 안내 ────────────────────────────────────

  Widget _buildNoResultHint(AppColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: cardDeco(c),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 32, color: c.text3.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            '유효한 값을 입력하면 결과가 표시됩니다',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: c.text3,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 기기 선택 토글 ────────────────────────────────────

  Widget _buildMachineToggle(AppColors c) {
    return Container(
      decoration: cardDeco(c),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: Machine.values.map((m) {
          final selected = m == _machine;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _machine = m);
                _calculate();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(cardRadius - 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  m.label,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : c.text3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── 관경 칩 ───────────────────────────────────────────

  Widget _buildPipeChips(AppColors c) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pipeOds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final od = _pipeOds[i];
          final selected = od == _selectedOd;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedOd = od);
              _calculate();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? c.chipSelected : c.chipUnselected,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? c.chipSelected : c.border,
                ),
              ),
              child: Text(
                '$od',
                style: TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white) : c.text2,
                ),
              ),
            ),
          );
        },
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
          Row(
            children: [
              Expanded(child: _inputField('장애물 높이 (mm)', _heightCtrl, c)),
              const SizedBox(width: 12),
              Expanded(child: _inputField('장애물 폭 (mm)', _widthCtrl, c)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _inputField('앞 여유 (mm)', _preCtrl, c)),
              const SizedBox(width: 12),
              Expanded(child: _inputField('뒤 여유 (mm)', _postCtrl, c)),
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
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
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
          onChanged: (_) => _calculate(),
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
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedAngle = a);
                _calculate();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                    color: selected ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white) : c.text2,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── 결과 카드 ─────────────────────────────────────────

  Widget _buildResultCard(OffsetResult r, AppColors c) {
    final setAngle = (_selectedAngle + _springBack).round();

    return Container(
      width: double.infinity,
      decoration: cardDeco(c),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _bigResult('B1 삽입', '${r.b1Insert.round()} mm', c),
              ),
              Container(width: 1, height: 56, color: c.border),
              Expanded(
                child: _bigResult('B2 삽입', '${r.b2Insert.round()} mm', c),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: c.headerBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '세팅각도: $setAngle° (${_selectedAngle.round()}° + ${_springBack.round()}°)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DM Mono',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.accent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: c.border),
          const SizedBox(height: 12),
          Row(
            children: [
              _smallResult('경사 구간', '${r.offsetLength.round()} mm', c),
              Container(width: 1, height: 36, color: c.border),
              _smallResult('수평 이동', '${r.horizMove.round()} mm', c),
              Container(width: 1, height: 36, color: c.border),
              _smallResult('총 소요', '${r.totalLength.round()} mm', c),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _copyResult,
              icon: Icon(Icons.copy, size: 14, color: c.text3),
              label: Text(
                '결과 복사',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: c.text3,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigResult(String label, String value, AppColors c) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: c.text3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'DM Mono',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: c.accent,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _smallResult(String label, String value, AppColors c) {
    return Expanded(
      child: Column(
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
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 작업 순서 가이드 카드 ─────────────────────────────

  Widget _buildStepGuideCard(OffsetResult r, AppColors c) {
    final setAngle = (_selectedAngle + _springBack).round();

    final steps = [
      (
        'B1 마킹: ${r.b1Insert.round()}mm',
        '배관 끝에서 ${r.b1Insert.round()}mm 위치에 마킹',
      ),
      (
        'B1: $setAngle° 꺾기',
        '장애물 방향으로 $setAngle°에서 멈추세요',
      ),
      (
        'B2 마킹: ${r.b2Insert.round()}mm',
        '끝에서 ${r.b2Insert.round()}mm 위치에 마킹',
      ),
      (
        'B2: $setAngle° 반대 방향',
        'B1과 반대 방향으로 $setAngle°에서 멈추세요',
      ),
      (
        '평행도 확인',
        '양쪽 배관 평행 확인. 수평이동 ${r.horizMove.round()}mm',
      ),
    ];

    final doneCount = _stepsDone.where((s) => s).length;
    final allDone = doneCount == steps.length;

    return Container(
      decoration: cardDeco(c),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: c.headerBg,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text(
                  '작업 순서',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                if (allDone) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.accentBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '완료',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.accent,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '$doneCount/${steps.length}',
                  style: TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.accent,
                  ),
                ),
              ],
            ),
          ),

          // Steps
          for (var i = 0; i < steps.length; i++)
            _buildStepRow(
              i,
              '${i + 1}',
              steps[i].$1,
              steps[i].$2,
              c,
            ),
        ],
      ),
    );
  }

  Widget _buildStepRow(
    int index,
    String number,
    String title,
    String subtitle,
    AppColors c,
  ) {
    final checked = _stepsDone[index];
    return InkWell(
      onTap: () =>
          setState(() => _stepsDone[index] = !_stepsDone[index]),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                number,
                style: TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: checked ? Colors.white : c.text2,
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
                      decoration:
                          checked ? TextDecoration.lineThrough : null,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: c.headerBg,
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Text(
              '측면 다이어그램',
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
              painter: _OffsetPainter(
                result: r,
                angle: _selectedAngle,
                obsHeight: obsHeight,
                obsWidth: obsWidth,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 섹션 라벨 ─────────────────────────────────────────

  Widget _buildSectionLabel(String text, AppColors c) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: c.text2,
      ),
    );
  }

  // ─── AR 측정 → 필드 선택 바텀시트 ─────────────────────

  Future<void> _measureThenPickField() async {
    setState(() => _measuring = true);
    try {
      final distance = await ArMeasureService.getDistance();
      if (distance != null && mounted) {
        _showFieldPickerForDistance(distance);
      }
    } on CameraPermissionDeniedException {
      if (mounted) await _showPermissionDeniedDialog();
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AR 측정 오류: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AR 오류: $e')),
        );
      }
    }
    if (mounted) setState(() => _measuring = false);
  }

  void _showFieldPickerForDistance(double distance) {
    final c = context.appColors;
    final distStr = '${distance.round()} mm';
    final fields = [
      ('장애물 높이', _heightCtrl),
      ('장애물 폭', _widthCtrl),
      ('앞 여유', _preCtrl),
      ('뒤 여유', _postCtrl),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
                    '입력할 항목을 선택하세요',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: c.text3,
                    ),
                  ),
                ),
                Divider(height: 1, color: c.border),
                ...fields.map((f) => ListTile(
                      leading: Icon(Icons.straighten,
                          size: 20, color: c.primary),
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

  Future<void> _showPermissionDeniedDialog() async {
    final permanentlyDenied = await ArMeasureService.isPermanentlyDenied();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('카메라 권한 필요'),
        content: Text(
          permanentlyDenied
              ? 'AR 측정을 사용하려면 설정에서 카메라 권한을 허용해주세요.'
              : 'AR 측정을 사용하려면 카메라 권한이 필요합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          if (permanentlyDenied)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('설정으로 이동'),
            ),
        ],
      ),
    );
  }

  // ─── 하단 AR 버튼 ─────────────────────────────────────

  Widget _buildArButton(AppColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: c.background,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _measuring ? null : () => _measureThenPickField(),
          icon: _measuring
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.camera_alt_outlined, size: 20),
          label: Text(
            _measuring ? '측정 중...' : 'AR 측정으로 입력',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardRadius),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── _OffsetPainter ─────────────────────────────────────

class _OffsetPainter extends CustomPainter {
  final OffsetResult result;
  final double angle;
  final double obsHeight;
  final double obsWidth;

  _OffsetPainter({
    required this.result,
    required this.angle,
    required this.obsHeight,
    required this.obsWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const pad = 20.0;
    const pw = 6.0;

    // 전체 배관 길이 기준 스케일
    final total = result.totalLength;
    if (total <= 0) return;
    final sc = (w - pad * 2) / total;

    final baseY = h * 0.68;
    final liftH = (obsHeight * sc * 3).clamp(20.0, h * 0.45);
    final topY = baseY - liftH;

    final pre = result.b1Insert;
    final offLen = result.offsetLength;
    final overW = obsWidth * sc;
    final postDist = total - pre - offLen * 2 - obsWidth;

    // ── 장애물 박스 ──
    final obsX = pad + (pre + offLen * cos(angle * pi / 180) * 0.6) * sc;
    final obsRect = Rect.fromLTWH(obsX, topY - 6, overW, baseY - topY + 6);
    canvas.drawRect(obsRect, Paint()..color = const Color(0x18FF6B6B));
    canvas.drawRect(
      obsRect,
      Paint()
        ..color = const Color(0x55FF6B6B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    _drawText(canvas, '장애물', Offset(obsX + overW / 2, topY - 14),
        const Color(0xFFFF6B6B), 9,
        bold: true);

    // ── 배관 경로 ──
    double cx = pad, cy = baseY;

    // 시작 포인트
    _drawDot(canvas, Offset(cx, cy), 6, const Color(0xFF4A9EFF));

    // pre 구간
    final preEnd = cx + pre * sc;
    _drawPipe(canvas, Offset(cx, cy), Offset(preEnd, cy), pw);
    cx = preEnd;
    _drawDot(canvas, Offset(cx, cy), 6, const Color(0xFF4A9EFF));
    _drawText(canvas, 'B1', Offset(cx, cy + 14), const Color(0xFFFFD60A), 9,
        bold: true);

    // B1 상승 구간 (bezier)
    final riseX = offLen * sc * cos(angle * pi / 180) * 0.6;
    final riseEndY = topY;
    final path1 = Path()
      ..moveTo(cx, cy)
      ..quadraticBezierTo(
          cx + riseX * 0.35, cy + (riseEndY - cy) * 0.55, cx + riseX, riseEndY);
    canvas.drawPath(
      path1,
      Paint()
        ..color = const Color(0xFF4A9EFF)
        ..strokeWidth = pw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    _drawText(canvas, '${angle.round()}°', Offset(cx + 3, cy - 8),
        const Color(0xFF4A9EFF), 8,
        bold: true);

    cx += riseX;
    cy = riseEndY;
    _drawDot(canvas, Offset(cx, cy), 6, const Color(0xFF4A9EFF));

    // 장애물 위 통과 구간
    _drawPipe(canvas, Offset(cx, cy), Offset(cx + overW, cy), pw);
    cx += overW;
    _drawDot(canvas, Offset(cx, cy), 6, const Color(0xFF4A9EFF));

    // B2 하강 구간
    _drawText(canvas, 'B2', Offset(cx, cy - 10), const Color(0xFFFFD60A), 9,
        bold: true);
    final dropEndY = baseY;
    final path2 = Path()
      ..moveTo(cx, cy)
      ..quadraticBezierTo(cx + riseX * 0.65, cy + (dropEndY - cy) * 0.55,
          cx + riseX, dropEndY);
    canvas.drawPath(
      path2,
      Paint()
        ..color = const Color(0xFF4A9EFF)
        ..strokeWidth = pw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    _drawText(canvas, '${angle.round()}°', Offset(cx + 3, cy + 14),
        const Color(0xFF4A9EFF), 8,
        bold: true);

    cx += riseX;
    cy = dropEndY;
    _drawDot(canvas, Offset(cx, cy), 6, const Color(0xFF4A9EFF));

    // post 구간
    final postEnd = cx + postDist * sc;
    _drawPipe(canvas, Offset(cx, cy), Offset(postEnd, cy), pw);
    _drawDot(canvas, Offset(postEnd, cy), 6, const Color(0xFF4A9EFF));

    // H 치수선 (점선)
    final dimX = pad + pre * sc - 12;
    _drawDashedLine(
        canvas, Offset(dimX, baseY), Offset(dimX, topY), const Color(0x66FFD60A));
    _drawText(canvas, 'H${obsHeight.round()}',
        Offset(dimX - 4, (baseY + topY) / 2), const Color(0xFFFFD60A), 8,
        bold: true);
  }

  void _drawPipe(Canvas canvas, Offset from, Offset to, double pw) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = const Color(0xFFB87333)
        ..strokeWidth = pw
        ..strokeCap = StrokeCap.round,
    );
    final a = (to - from).direction;
    final dx = -sin(a) * pw * 0.3;
    final dy = cos(a) * pw * 0.3;
    canvas.drawLine(
      from + Offset(dx, dy),
      to + Offset(dx, dy),
      Paint()
        ..color = const Color(0xFFD4956A)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawDot(Canvas canvas, Offset center, double r, Color c) {
    canvas.drawCircle(center, r, Paint()..color = c);
    canvas.drawCircle(
      center + Offset(-r * 0.2, -r * 0.25),
      r * 0.35,
      Paint()..color = const Color(0x33FFFFFF),
    );
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Color color) {
    const dashLen = 4.0, gapLen = 4.0;
    final dx = to.dx - from.dx, dy = to.dy - from.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final ux = dx / len, uy = dy / len;
    double d = 0;
    bool drawing = true;
    while (d < len) {
      final segLen = drawing ? dashLen : gapLen;
      final end = (d + segLen).clamp(0.0, len);
      if (drawing) {
        canvas.drawLine(
          Offset(from.dx + ux * d, from.dy + uy * d),
          Offset(from.dx + ux * end, from.dy + uy * end),
          Paint()
            ..color = color
            ..strokeWidth = 1,
        );
      }
      d += segLen;
      drawing = !drawing;
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color,
      double size,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontFamily: bold ? 'DM Mono' : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_OffsetPainter old) =>
      old.result != result ||
      old.angle != angle ||
      old.obsHeight != obsHeight ||
      old.obsWidth != obsWidth;
}
