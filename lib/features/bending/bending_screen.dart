import 'dart:convert';
import 'dart:math' show sin, cos;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/pipe_specs.dart';
import '../../core/models/bend_result.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';
import '../../services/ar_measure_service.dart';
import 'bending_calculator.dart';

const _angles = [30.0, 45.0, 60.0, 90.0];
final _pipeOds = pipeSpecs.keys.toList();
const _prefsKeyBends = 'bending_data';
const _prefsKeyMachine = 'bending_machine';
const _prefsKeyOd = 'bending_od';

// ─────────────────────────────────────────────────────────

class BendingScreen extends StatefulWidget {
  const BendingScreen({super.key});

  @override
  State<BendingScreen> createState() => _BendingScreenState();
}

class _BendingScreenState extends State<BendingScreen> {
  Machine _machine = Machine.robend4000;
  int _selectedOd = 15;
  double _selectedAngle = 90;
  final _insertController = TextEditingController(text: '150');
  BendDirection? _selectedDirection;
  final List<_BendEntry> _bends = [];
  final _scrollController = ScrollController();
  bool _measuring = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _insertController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Persistence ──────────────────────────────────────

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final machineIndex = prefs.getInt(_prefsKeyMachine);
    if (machineIndex != null && machineIndex < Machine.values.length) {
      _machine = Machine.values[machineIndex];
    }
    final od = prefs.getInt(_prefsKeyOd);
    if (od != null && pipeSpecs.containsKey(od)) {
      _selectedOd = od;
    }

    final json = prefs.getString(_prefsKeyBends);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        final entries = <_BendEntry>[];
        for (final e in list) {
          if (e is Map<String, dynamic>) {
            entries.add(_BendEntry.fromJson(e));
          }
        }
        if (mounted) setState(() => _bends.addAll(entries));
      } catch (e) {
        // 손상된 데이터 삭제 — 다음 저장 시 덮어씌움
        debugPrint('BendingScreen: 저장 데이터 손상 — $e');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_prefsKeyBends);
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyMachine, _machine.index);
    await prefs.setInt(_prefsKeyOd, _selectedOd);
    await prefs.setString(
      _prefsKeyBends,
      jsonEncode(_bends.map((b) => b.toJson()).toList()),
    );
  }

  // ─── Actions ────────────────────────────────────────────

  void _addBend() {
    final insert = double.tryParse(_insertController.text);
    if (insert == null || insert <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삽입길이를 입력하세요 (1mm 이상)')),
      );
      return;
    }
    if (_selectedDirection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('꺾는 방향을 선택하세요 (위/아래/좌/우)')),
      );
      return;
    }
    final result = BendingCalculator.calculate(
      insertLength: insert,
      targetAngle: _selectedAngle,
      pipeOd: _selectedOd,
      machine: _machine,
    );
    setState(() {
      _bends.add(_BendEntry(
        pipeOd: _selectedOd,
        machine: _machine,
        insertLen: insert,
        angle: _selectedAngle,
        direction: _selectedDirection!,
        result: result,
      ));
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
    setState(() => _bends.removeAt(i));
    _saveData();
  }

  void _prepareNextBend() {
    setState(() {
      _selectedDirection = null;
      _insertController.clear();
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _confirmResetAll() {
    if (_bends.isEmpty) return;
    final c = context.appColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('초기화'),
        content: Text('${_bends.length}개의 꺾기 데이터가 삭제됩니다. 초기화할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _bends.clear();
                _selectedDirection = null;
                _insertController.clear();
              });
              _saveData();
            },
            child: Text('초기화', style: TextStyle(color: c.primary)),
          ),
        ],
      ),
    );
  }

  void _copyBendInfo(int i, _BendEntry entry) {
    final text =
        '${i + 1}번 꺾기: ${entry.pipeOd}mm ${entry.angle.round()}° ${entry.direction.label}'
        ' | 세팅 ${entry.result.setAngle.round()}° | 호 ${entry.result.arcLength.round()}mm'
        ' | 삽입 ${entry.insertLen.round()}mm';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('클립보드에 복사되었습니다'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _copyAllSummary() {
    final lines = <String>[];
    for (var i = 0; i < _bends.length; i++) {
      final b = _bends[i];
      lines.add(
        '${i + 1}번: ${b.pipeOd}mm ${b.angle.round()}° ${b.direction.label}'
        ' | 세팅 ${b.result.setAngle.round()}° | 삽입 ${b.insertLen.round()}mm',
      );
    }
    final totalConsumed =
        _bends.fold<double>(0, (sum, b) => sum + b.result.consumedLength);
    lines.add('총 소비: ${totalConsumed.round()}mm');
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('전체 현황이 복사되었습니다'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final themeCtrl = ThemeController.of(context);

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
              'PIPECRAFT AR',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.text,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          if (themeCtrl != null)
            IconButton(
              icon: Icon(
                switch (themeCtrl.themeMode) {
                  ThemeMode.light => Icons.light_mode,
                  ThemeMode.dark => Icons.dark_mode,
                  _ => Icons.brightness_auto,
                },
                color: c.text2,
                size: 20,
              ),
              tooltip: switch (themeCtrl.themeMode) {
                ThemeMode.light => '라이트 모드',
                ThemeMode.dark => '다크 모드',
                _ => '시스템 설정',
              },
              onPressed: themeCtrl.onCycleTheme,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  _buildInsertCard(c),
                  const SizedBox(height: 16),
                  _buildSectionLabel('목표 각도', c),
                  const SizedBox(height: 8),
                  _buildAngleButtons(c),
                  const SizedBox(height: 16),
                  _buildSectionLabel('꺾는 방향', c),
                  const SizedBox(height: 8),
                  _buildDirectionPad(c),
                  const SizedBox(height: 20),
                  _buildAddBendButton(c),
                  if (_bends.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSummaryCard(c),
                    const SizedBox(height: 12),
                    _buildRoutePreview(c),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _bends.length; i++)
                      _buildBendCard(i, _bends[i], c),
                  ] else ...[
                    const SizedBox(height: 40),
                    _buildEmptyState(c),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildBottomBar(c),
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

  // ─── 빈 상태 ───────────────────────────────────────────

  Widget _buildEmptyState(AppColors c) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.straighten, size: 64, color: c.text3.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            '꺾기를 추가하세요',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.text3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '위에서 삽입길이와 방향을 선택한 후\n꺾기 추가 버튼을 눌러주세요',
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
                _saveData();
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
              _saveData();
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

  // ─── 삽입 길이 입력 ────────────────────────────────────

  Widget _buildInsertCard(AppColors c) {
    return Container(
      decoration: cardDeco(c),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '삽입 길이 (mm)',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: c.text3,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _insertController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              LengthLimitingTextInputFormatter(8),
            ],
            style: TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 28,
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
                fontSize: 28,
                color: c.text3.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
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
              onTap: () => setState(() => _selectedAngle = a),
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

  // ─── 방향 선택 D패드 ──────────────────────────────────

  Widget _buildDirectionPad(AppColors c) {
    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 52 * 3 + 8 * 2,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 52),
                    const SizedBox(width: 8),
                    _dirButton(BendDirection.up, c),
                    const SizedBox(width: 8),
                    const SizedBox(width: 52),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dirButton(BendDirection.left, c),
                    const SizedBox(width: 8),
                    _centerCell(c),
                    const SizedBox(width: 8),
                    _dirButton(BendDirection.right, c),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 52),
                    const SizedBox(width: 8),
                    _dirButton(BendDirection.down, c),
                    const SizedBox(width: 8),
                    const SizedBox(width: 52),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_selectedDirection != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '${_selectedDirection!.emoji} ${_selectedDirection!.label}',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
          ),
      ],
    );
  }

  Widget _dirButton(BendDirection dir, AppColors c) {
    final selected = _selectedDirection == dir;
    final icon = switch (dir) {
      BendDirection.up => Icons.arrow_upward,
      BendDirection.down => Icons.arrow_downward,
      BendDirection.left => Icons.arrow_back,
      BendDirection.right => Icons.arrow_forward,
    };
    return Semantics(
      label: '${dir.label} 방향 선택',
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: () => setState(() => _selectedDirection = dir),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: selected ? c.primary : c.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 24, color: selected ? Colors.white : c.text),
        ),
      ),
    );
  }

  Widget _centerCell(AppColors c) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      child: Text(
        '방향',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c.text3,
        ),
      ),
    );
  }

  // ─── 꺾기 추가 버튼 ───────────────────────────────────

  Widget _buildAddBendButton(AppColors c) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _addBend,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          '꺾기 추가',
          style: TextStyle(
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
    );
  }

  // ─── 경로 미리보기 ─────────────────────────────────────

  Widget _buildRoutePreview(AppColors c) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.diagramBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.diagramBorder),
          ),
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              painter: _RoutePainter(bends: _bends),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(const Color(0xFFB87333), '배관', c),
            const SizedBox(width: 12),
            _legendItem(const Color(0xFFFF6B6B), '꺾임', c),
            const SizedBox(width: 12),
            _legendItem(const Color(0xFF2ECC71), '완료', c),
            const SizedBox(width: 12),
            _legendItem(const Color(0xFF4A9EFF), '포인트', c),
            const SizedBox(width: 12),
            _legendItem(const Color(0xFFFFD60A), '마킹위치', c),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label, AppColors c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            color: c.text2,
          ),
        ),
      ],
    );
  }

  // ─── 전체 현황 카드 ───────────────────────────────────

  Widget _buildSummaryCard(AppColors c) {
    final total = _bends.length;
    final doneCount = _bends.where((b) => b.done).length;
    final totalConsumed =
        _bends.fold<double>(0, (sum, b) => sum + b.result.consumedLength);

    return Container(
      decoration: cardDeco(c),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '전체 현황',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.text,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.copy, size: 16, color: c.text3),
                tooltip: '전체 복사',
                onPressed: _copyAllSummary,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(width: 4),
              Text(
                '$doneCount/$total 완료',
                style: TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '총 소비 배관 길이: ${totalConsumed.round()} mm',
            style: TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 13,
              color: c.text2,
            ),
          ),
          const SizedBox(height: 10),
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

  // ─── 꺾기 카드 ────────────────────────────────────────

  Widget _buildBendCard(int i, _BendEntry entry, AppColors c) {
    final sb = (entry.result.setAngle - entry.angle).round();
    final bendCenter = entry.insertLen + entry.result.arcLength / 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cardDeco(c),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            color: c.headerBg,
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 0),
            child: Row(
              children: [
                Text(
                  '${i + 1}번째 꺾기',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                if (entry.done) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                IconButton(
                  icon: Icon(Icons.copy, size: 16, color: c.text3),
                  tooltip: '복사',
                  onPressed: () => _copyBendInfo(i, entry),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: c.text3),
                  onPressed: () => _deleteBend(i),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: c.headerBg,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(
              '${entry.pipeOd}mm · ${entry.angle.round()}° · ${entry.direction.label} · ${entry.insertLen.round()}mm',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                color: c.text2,
              ),
            ),
          ),

          // ── Result ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text('세팅각도',
                              style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  color: c.text3)),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.result.setAngle.round()}°',
                            style: TextStyle(
                              fontFamily: 'DM Mono',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: c.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: c.border),
                    Expanded(
                      child: Column(
                        children: [
                          Text('호길이',
                              style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  color: c.text3)),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.result.arcLength.round()} mm',
                            style: TextStyle(
                              fontFamily: 'DM Mono',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: c.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: c.border),
                    Expanded(
                      child: Column(
                        children: [
                          Text('단축량',
                              style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  color: c.text3)),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.result.shortenLength.round()} mm',
                            style: TextStyle(
                              fontFamily: 'DM Mono',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: c.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.headerBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '소비길이: 삽입 ${entry.insertLen.round()} + 호 ${entry.result.arcLength.round()} = ${entry.result.consumedLength.round()}',
                    style: TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 12,
                      color: c.text2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),

          // ── Marking ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '마킹 위치: 끝에서 ${entry.insertLen.round()}mm',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '    꺾임 중심: ${bendCenter.round()}mm',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: c.text2,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),

          // ── Steps ──
          _buildStepRow(entry, 0, 'A',
              '배관에 ${entry.insertLen.round()}mm 마킹', '끝에서 정확히 재서 마킹펜으로 표시', c),
          _buildStepRow(
              entry,
              1,
              'B',
              '${entry.direction.emoji} ${entry.direction.label} 방향 확인',
              '방향이 틀리면 수정 불가!', c),
          _buildStepRow(
              entry,
              2,
              'C',
              '눈금 ${entry.result.setAngle.round()}°에서 멈추기',
              '목표 ${entry.angle.round()}° + 스프링백 $sb°', c),
          _buildStepRow(entry, 3, 'D', '각도계로 실제 꺾임 확인',
              '${entry.angle.round()}° ± 2° 이내면 OK', c),
        ],
      ),
    );
  }

  Widget _buildStepRow(
    _BendEntry entry,
    int stepIndex,
    String letter,
    String title,
    String subtitle,
    AppColors c,
  ) {
    final checked = entry.stepsDone[stepIndex];
    return InkWell(
      onTap: () {
        setState(() => entry.stepsDone[stepIndex] = !checked);
        _saveData();
      },
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
                letter,
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

  // ─── 권한 거부 다이얼로그 ──────────────────────────────

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

  // ─── 하단 바 ───────────────────────────────────────────

  Widget _buildBottomBar(AppColors c) {
    return Container(
      color: c.background,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_bends.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _confirmResetAll,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.text2,
                          side: BorderSide(color: c.border),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(cardRadius),
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          '초기화',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _prepareNextBend,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(cardRadius),
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          '다음 꺾기 추가',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _buildArButton(c),
          ],
        ),
      ),
    );
  }

  // ─── 하단 AR 버튼 ─────────────────────────────────────

  Widget _buildArButton(AppColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _measuring
              ? null
              : () async {
                  setState(() => _measuring = true);
                  try {
                    final distance = await ArMeasureService.getDistance();
                    if (distance != null && mounted) {
                      setState(() {
                        _insertController.text = distance.round().toString();
                      });
                    }
                  } on CameraPermissionDeniedException {
                    if (mounted) await _showPermissionDeniedDialog();
                  } on PlatformException {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('AR 측정 중 오류가 발생했습니다')),
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('AR 오류가 발생했습니다. 다시 시도해주세요')),
                      );
                    }
                  }
                  if (mounted) setState(() => _measuring = false);
                },
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

// ─── BendDirection ──────────────────────────────────────

enum BendDirection { up, down, left, right }

extension BendDirectionX on BendDirection {
  String get emoji =>
      const {'up': '⬆️', 'down': '⬇️', 'left': '⬅️', 'right': '➡️'}[name]!;
  String get label => const {
        'up': '위쪽(↑)',
        'down': '아래쪽(↓)',
        'left': '왼쪽(←)',
        'right': '오른쪽(→)',
      }[name]!;
}

// ─── _BendEntry ─────────────────────────────────────────

class _BendEntry {
  final int pipeOd;
  final Machine machine;
  final double insertLen;
  final double angle;
  final BendDirection direction;
  final BendResult result;
  final List<bool> stepsDone;

  bool get done => stepsDone.every((s) => s);

  _BendEntry({
    required this.pipeOd,
    required this.machine,
    required this.insertLen,
    required this.angle,
    required this.direction,
    required this.result,
    List<bool>? stepsDone,
  }) : stepsDone = stepsDone ?? [false, false, false, false];

  Map<String, dynamic> toJson() => {
        'pipeOd': pipeOd,
        'machine': machine.index,
        'insertLen': insertLen,
        'angle': angle,
        'direction': direction.name,
        'stepsDone': stepsDone,
      };

  factory _BendEntry.fromJson(Map<String, dynamic> json) {
    final machine = Machine.values[json['machine'] as int];
    final pipeOd = json['pipeOd'] as int;
    final insertLen = (json['insertLen'] as num).toDouble();
    final angle = (json['angle'] as num).toDouble();
    final direction = BendDirection.values.byName(json['direction'] as String);
    final steps = (json['stepsDone'] as List?)
        ?.map((e) => e as bool)
        .toList();

    final result = BendingCalculator.calculate(
      insertLength: insertLen,
      targetAngle: angle,
      pipeOd: pipeOd,
      machine: machine,
    );

    return _BendEntry(
      pipeOd: pipeOd,
      machine: machine,
      insertLen: insertLen,
      angle: angle,
      direction: direction,
      result: result,
      stepsDone: steps,
    );
  }
}

// ─── _RoutePainter ──────────────────────────────────────

class _RoutePainter extends CustomPainter {
  final List<_BendEntry> bends;
  _RoutePainter({required this.bends});

  @override
  void paint(Canvas canvas, Size size) {
    if (bends.isEmpty) return;

    final w = size.width;
    final h = size.height;
    const pad = 22.0;
    final n = bends.length;
    final seg = ((w - pad * 2) / (n * 2 + 1)).clamp(0.0, 52.0);
    const pw = 7.0;

    double cx = pad, cy = h / 2;

    // 중앙 기준선
    canvas.drawLine(
      Offset(0, h / 2),
      Offset(w, h / 2),
      Paint()
        ..color = const Color(0xFF2A2A2E)
        ..strokeWidth = 1,
    );

    // 시작 포인트
    _drawDot(canvas, Offset(cx, cy), 6, const Color(0xFF4A9EFF));

    for (int i = 0; i < bends.length; i++) {
      final b = bends[i];
      final pipeColor =
          b.done ? const Color(0xFF2ECC71) : const Color(0xFFB87333);
      final pipeHighlight =
          b.done ? const Color(0xFF4EDD9A) : const Color(0xFFD4956A);
      final bendColor =
          b.done ? const Color(0xFF2ECC71) : const Color(0xFFFF6B6B);

      // 직선 배관 세그먼트
      _drawPipe(
          canvas, Offset(cx, cy), Offset(cx + seg, cy), pw, pipeColor, pipeHighlight);

      // 마킹 위치 점 (노란색)
      final markRatio = b.insertLen / (b.insertLen + b.result.arcLength);
      final markX = cx + markRatio * seg * 0.85;
      _drawDot(canvas, Offset(markX, cy), 4, const Color(0xFFFFD60A));

      cx += seg;

      // 꺾임 포인트
      _drawDot(canvas, Offset(cx, cy), 7, bendColor);

      // 방향에 따른 꺾임 벡터
      final double dY = b.direction == BendDirection.up
          ? -1.0
          : b.direction == BendDirection.down
              ? 1.0
              : 0.0;
      final double dX = b.direction == BendDirection.left
          ? -0.4
          : b.direction == BendDirection.right
              ? 0.4
              : 0.0;
      final bLen = (seg * 0.7).clamp(0.0, 34.0);

      // 꺾임 곡선 (quadratic bezier)
      final path = Path()
        ..moveTo(cx, cy)
        ..quadraticBezierTo(
          cx + dX * bLen * 0.4,
          cy + dY * bLen * 0.5,
          cx + seg * 0.4 + dX * bLen * 0.3,
          cy + dY * bLen,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = bendColor
          ..strokeWidth = pw
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // 각도 라벨
      _drawText(
        canvas,
        '${b.angle.round()}°',
        Offset(
            cx + seg * 0.1, cy + dY * (bLen + 13) + (dY >= 0 ? 11 : -2)),
        const Color(0xFFFFD60A),
        9,
        bold: true,
      );

      // 방향 이모지
      _drawText(
        canvas,
        b.direction.emoji,
        Offset(cx + seg * 0.55,
            cy + dY * bLen + (dY > 0 ? 13 : dY < 0 ? -3 : 5)),
        const Color(0x66FFFFFF),
        11,
      );

      cx = cx + seg * 0.4 + dX * bLen * 0.3;
      cy = cy + dY * bLen;
    }

    // 끝 직선
    _drawPipe(canvas, Offset(cx, cy), Offset(cx + seg, cy), pw,
        const Color(0xFFB87333), const Color(0xFFD4956A));
    _drawDot(canvas, Offset(cx + seg, cy), 6, const Color(0xFF4A9EFF));
  }

  void _drawPipe(Canvas canvas, Offset from, Offset to, double pw, Color c,
      Color hi) {
    canvas.drawLine(
        from,
        to,
        Paint()
          ..color = c
          ..strokeWidth = pw
          ..strokeCap = StrokeCap.round);
    final angle = (to - from).direction;
    final dx = -sin(angle) * pw * 0.3;
    final dy = cos(angle) * pw * 0.3;
    canvas.drawLine(
        from + Offset(dx, dy),
        to + Offset(dx, dy),
        Paint()
          ..color = hi
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
  }

  void _drawDot(Canvas canvas, Offset center, double r, Color c) {
    canvas.drawCircle(center, r, Paint()..color = c);
    canvas.drawCircle(
      center + Offset(-r * 0.2, -r * 0.25),
      r * 0.35,
      Paint()..color = const Color(0x33FFFFFF),
    );
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
  bool shouldRepaint(_RoutePainter old) =>
      old.bends.length != bends.length ||
      !_listsEqual(old.bends, bends);

  static bool _listsEqual(List<_BendEntry> a, List<_BendEntry> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i]) || a[i].done != b[i].done) return false;
    }
    return true;
  }
}
