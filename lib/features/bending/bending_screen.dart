import 'dart:math' show sin, cos;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/pipe_specs.dart';
import '../../core/models/bend_result.dart';
import '../../services/ar_measure_service.dart';
import 'bending_calculator.dart';

// ─── Design Tokens ──────────────────────────────────────
const _bgColor = Color(0xFFF5F3F0);
const _red = Color(0xFFC8102E);
const _green = Color(0xFF1A7A4A);
const _greenBg = Color(0xFFEBF7F1);
const _text = Color(0xFF18181B);
const _text2 = Color(0xFF71717A);
const _text3 = Color(0xFFA1A1AA);
const _border = Color(0xFFE4E2DE);
const _headerBg = Color(0xFFF8F6F3);
const _cardRadius = 12.0;

const _angles = [30.0, 45.0, 60.0, 90.0];
final _pipeOds = pipeSpecs.keys.toList();

BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_cardRadius),
      border: Border.all(color: _border, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

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

  @override
  void dispose() {
    _insertController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Actions ────────────────────────────────────────────

  void _addBend() {
    final insert = double.tryParse(_insertController.text);
    if (insert == null || insert <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삽입길이를 입력하세요')),
      );
      return;
    }
    if (_selectedDirection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('꺾는 방향을 선택하세요')),
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

  void _resetAll() {
    setState(() {
      _bends.clear();
      _selectedDirection = null;
      _insertController.clear();
    });
  }

  // ─── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'PIPECRAFT AR',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
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
                  _buildMachineToggle(),
                  const SizedBox(height: 16),
                  _buildSectionLabel('관경 (MM)'),
                  const SizedBox(height: 8),
                  _buildPipeChips(),
                  const SizedBox(height: 16),
                  _buildInsertCard(),
                  const SizedBox(height: 16),
                  _buildSectionLabel('목표 각도'),
                  const SizedBox(height: 8),
                  _buildAngleButtons(),
                  const SizedBox(height: 16),
                  _buildSectionLabel('꺾는 방향'),
                  const SizedBox(height: 8),
                  _buildDirectionPad(),
                  const SizedBox(height: 20),
                  _buildAddBendButton(),
                  if (_bends.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSummaryCard(),
                    const SizedBox(height: 12),
                    _buildRoutePreview(),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _bends.length; i++)
                      _buildBendCard(i, _bends[i]),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ─── 기기 선택 토글 ────────────────────────────────────

  Widget _buildMachineToggle() {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: Machine.values.map((m) {
          final selected = m == _machine;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _machine = m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? _red : Colors.transparent,
                  borderRadius: BorderRadius.circular(_cardRadius - 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  m.label,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _text3,
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

  Widget _buildPipeChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pipeOds.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final od = _pipeOds[i];
          final selected = od == _selectedOd;
          return GestureDetector(
            onTap: () => setState(() => _selectedOd = od),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? _text : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? _text : _border,
                ),
              ),
              child: Text(
                '$od',
                style: TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : _text2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── 삽입 길이 입력 ────────────────────────────────────

  Widget _buildInsertCard() {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '삽입 길이 (mm)',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _text3,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _insertController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: _text,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: '0',
              hintStyle: TextStyle(
                fontFamily: 'DM Mono',
                fontSize: 28,
                color: Color(0xFFCCCCCC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 각도 선택 ─────────────────────────────────────────

  Widget _buildAngleButtons() {
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
                  color: selected ? _text : Colors.white,
                  borderRadius: BorderRadius.circular(_cardRadius),
                  border: Border.all(
                    color: selected ? _text : _border,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${a.toInt()}°',
                  style: TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _text2,
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

  Widget _buildDirectionPad() {
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
                    _dirButton(BendDirection.up),
                    const SizedBox(width: 8),
                    const SizedBox(width: 52),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dirButton(BendDirection.left),
                    const SizedBox(width: 8),
                    _centerCell(),
                    const SizedBox(width: 8),
                    _dirButton(BendDirection.right),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 52),
                    const SizedBox(width: 8),
                    _dirButton(BendDirection.down),
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
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _text,
              ),
            ),
          ),
      ],
    );
  }

  Widget _dirButton(BendDirection dir) {
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
            color: selected ? _red : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _red : _border,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 24, color: selected ? Colors.white : _text),
        ),
      ),
    );
  }

  Widget _centerCell() {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      child: const Text(
        '방향',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _text3,
        ),
      ),
    );
  }

  // ─── 꺾기 추가 버튼 ───────────────────────────────────

  Widget _buildAddBendButton() {
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
          backgroundColor: _red,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
          ),
        ),
      ),
    );
  }

  // ─── 경로 미리보기 ─────────────────────────────────────

  Widget _buildRoutePreview() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A2A2E)),
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
            _legendItem(const Color(0xFFB87333), '배관'),
            const SizedBox(width: 12),
            _legendItem(const Color(0xFFFF6B6B), '꺾임'),
            const SizedBox(width: 12),
            _legendItem(const Color(0xFF2ECC71), '완료'),
            const SizedBox(width: 12),
            _legendItem(const Color(0xFF4A9EFF), '포인트'),
            const SizedBox(width: 12),
            _legendItem(const Color(0xFFFFD60A), '마킹위치'),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
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
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            color: _text2,
          ),
        ),
      ],
    );
  }

  // ─── 전체 현황 카드 ───────────────────────────────────

  Widget _buildSummaryCard() {
    final total = _bends.length;
    final doneCount = _bends.where((b) => b.done).length;
    final totalConsumed =
        _bends.fold<double>(0, (sum, b) => sum + b.result.consumedLength);

    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '전체 현황',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
              ),
              const Spacer(),
              Text(
                '$doneCount/$total 완료',
                style: const TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '총 소비 배관 길이: ${totalConsumed.round()} mm',
            style: const TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 13,
              color: _text2,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? doneCount / total : 0,
              minHeight: 6,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: const AlwaysStoppedAnimation(_green),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 꺾기 카드 ────────────────────────────────────────

  Widget _buildBendCard(int i, _BendEntry entry) {
    final sb = (entry.result.setAngle - entry.angle).round();
    final bendCenter = entry.insertLen + entry.result.arcLength / 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDeco(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            color: _headerBg,
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 0),
            child: Row(
              children: [
                Text(
                  '${i + 1}번째 꺾기',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
                if (entry.done) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _greenBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '✓ 완료',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _green,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: _text3),
                  onPressed: () => _deleteBend(i),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: _headerBg,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(
              '${entry.pipeOd}mm · ${entry.angle.round()}° · ${entry.direction.label} · ${entry.insertLen.round()}mm',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                color: _text2,
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
                          const Text('세팅각도',
                              style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  color: _text3)),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.result.setAngle.round()}°',
                            style: const TextStyle(
                              fontFamily: 'DM Mono',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: _green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: _border),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('호길이',
                              style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  color: _text3)),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.result.arcLength.round()} mm',
                            style: const TextStyle(
                              fontFamily: 'DM Mono',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: _border),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('단축량',
                              style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  color: _text3)),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.result.shortenLength.round()} mm',
                            style: const TextStyle(
                              fontFamily: 'DM Mono',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _text,
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
                    color: _headerBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '소비길이: 삽입 ${entry.insertLen.round()} + 호 ${entry.result.arcLength.round()} = ${entry.result.consumedLength.round()}',
                    style: const TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 12,
                      color: _text2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),

          // ── Marking ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✏️ 마킹 위치: 끝에서 ${entry.insertLen.round()}mm',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '    꺾임 중심: ${bendCenter.round()}mm',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: _text2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),

          // ── Steps ──
          _buildStepRow(entry, 0, 'A',
              '배관에 ${entry.insertLen.round()}mm 마킹', '끝에서 정확히 재서 마킹펜으로 표시'),
          _buildStepRow(
              entry,
              1,
              'B',
              '${entry.direction.emoji} ${entry.direction.label} 방향 확인',
              '방향이 틀리면 수정 불가!'),
          _buildStepRow(
              entry,
              2,
              'C',
              '눈금 ${entry.result.setAngle.round()}°에서 멈추기',
              '목표 ${entry.angle.round()}° + 스프링백 $sb°'),
          _buildStepRow(entry, 3, 'D', '각도계로 실제 꺾임 확인',
              '${entry.angle.round()}° ± 2° 이내면 OK'),
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
  ) {
    final checked = entry.stepsDone[stepIndex];
    return InkWell(
      onTap: () =>
          setState(() => entry.stepsDone[stepIndex] = !checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: checked ? _green : const Color(0xFFEEEEEE),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: checked ? Colors.white : _text2,
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
                      color: _text,
                      decoration:
                          checked ? TextDecoration.lineThrough : null,
                      decorationColor: _text3,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: _text3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              checked ? Icons.check_circle : Icons.circle_outlined,
              color: checked ? _green : _text3,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ─── 섹션 라벨 ─────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: _text2,
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

  Widget _buildBottomBar() {
    return Container(
      color: _bgColor,
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
                        onPressed: _resetAll,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _text2,
                          side: const BorderSide(color: _border),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(_cardRadius),
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
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(_cardRadius),
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
            _buildArButton(),
          ],
        ),
      ),
    );
  }

  // ─── 하단 AR 버튼 ─────────────────────────────────────

  Widget _buildArButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () async {
            try {
              final distance = await ArMeasureService.getDistance();
              if (distance != null && mounted) {
                setState(() {
                  _insertController.text = distance.round().toString();
                });
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
          },
          icon: const Icon(Icons.camera_alt_outlined, size: 20),
          label: const Text(
            'AR 측정으로 입력',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_cardRadius),
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
  final List<bool> stepsDone = [false, false, false, false];

  bool get done => stepsDone.every((s) => s);

  _BendEntry({
    required this.pipeOd,
    required this.machine,
    required this.insertLen,
    required this.angle,
    required this.direction,
    required this.result,
  });
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
