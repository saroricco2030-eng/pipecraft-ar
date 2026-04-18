import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/input/single_decimal_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../bend_entry.dart';

/// 밴딩 화면 하단 고정 입력 바.
///
/// [현장 5초 룰]
/// - 스크롤과 무관하게 항상 엄지존에 입력·CTA 노출
/// - 두 줄: (입력 | 각도 | AR), (방향 | 추가)
/// - 터치 타겟 48dp (장갑 환경 고려 — CLAUDE.md)
class StickyInputBar extends StatelessWidget {
  final TextEditingController insertController;
  final List<double> angles;
  final double selectedAngle;
  final ValueChanged<double> onAngleChanged;
  final BendDirection? selectedDirection;
  final ValueChanged<BendDirection> onDirectionChanged;
  final VoidCallback onAdd;
  final VoidCallback onArMeasure;
  final bool measuring;

  // 라벨 (i18n)
  final String insertHint;
  final String addLabel;
  final String mmUnit;
  final String arMeasuringLabel;
  final String directionLabelFor;

  const StickyInputBar({
    super.key,
    required this.insertController,
    required this.angles,
    required this.selectedAngle,
    required this.onAngleChanged,
    required this.selectedDirection,
    required this.onDirectionChanged,
    required this.onAdd,
    required this.onArMeasure,
    required this.measuring,
    required this.insertHint,
    required this.addLabel,
    required this.mmUnit,
    required this.arMeasuringLabel,
    required this.directionLabelFor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border)),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRow1(c),
              const SizedBox(height: 8),
              _buildRow2(c),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 줄 1: Input · 각도 칩 · AR ─────────────────────
  Widget _buildRow1(AppColors c) {
    return Row(
      children: [
        // 입력 필드 (큰 숫자)
        Expanded(
          flex: 3,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.headerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: insertController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      const SingleDecimalFormatter(),
                      const MaxValueFormatter(),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                      height: 1.1,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: insertHint,
                      hintStyle: TextStyle(
                        fontFamily: 'DM Mono',
                        fontSize: 22,
                        color: c.text3.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                Text(
                  mmUnit,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: c.text3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 각도 chip group
        Expanded(
          flex: 4,
          child: _AngleChipGroup(
            angles: angles,
            selected: selectedAngle,
            onChanged: onAngleChanged,
          ),
        ),
        const SizedBox(width: 6),
        // AR 버튼
        _SquareIconButton(
          icon: measuring ? null : Icons.camera_alt_rounded,
          progress: measuring,
          onTap: measuring ? null : onArMeasure,
          bg: c.card,
          fg: c.primary,
          borderColor: c.border,
        ),
      ],
    );
  }

  // ─── 줄 2: 방향 · 추가 CTA ──────────────────────────
  Widget _buildRow2(AppColors c) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _DirectionChipGroup(
            selected: selectedDirection,
            onChanged: onDirectionChanged,
            labelFor: directionLabelFor,
          ),
        ),
        const SizedBox(width: 8),
        // Add CTA — 가장 큰 터치 영역
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                addLabel,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 각도 칩 그룹 ──────────────────────────────────────
class _AngleChipGroup extends StatelessWidget {
  final List<double> angles;
  final double selected;
  final ValueChanged<double> onChanged;

  const _AngleChipGroup({
    required this.angles,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
      children: [
        for (final a in angles)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: a == angles.last ? 0 : 4),
              child: Semantics(
                label: '${a.toInt()}° angle',
                selected: a == selected,
                button: true,
                child: _ChipButton(
                  selected: a == selected,
                  onTap: () => onChanged(a),
                  bg: a == selected ? c.chipSelected : c.chipUnselected,
                  fg: a == selected ? c.chipSelectedText : c.text2,
                  borderColor: a == selected ? c.chipSelected : c.border,
                  child: Text(
                    '${a.toInt()}°',
                    style: TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color:
                          a == selected ? c.chipSelectedText : c.text2,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── 방향 칩 그룹 ──────────────────────────────────────
class _DirectionChipGroup extends StatelessWidget {
  final BendDirection? selected;
  final ValueChanged<BendDirection> onChanged;
  final String labelFor;

  const _DirectionChipGroup({
    required this.selected,
    required this.onChanged,
    required this.labelFor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
      children: [
        for (final d in BendDirection.values)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: d == BendDirection.values.last ? 0 : 4,
              ),
              child: Semantics(
                label: '$labelFor ${d.name}',
                selected: d == selected,
                button: true,
                child: _ChipButton(
                  selected: d == selected,
                  onTap: () => onChanged(d),
                  bg: d == selected ? c.primary : c.chipUnselected,
                  fg: d == selected ? c.onPrimary : c.text,
                  borderColor: d == selected ? c.primary : c.border,
                  child: Icon(
                    d.icon,
                    size: 20,
                    color: d == selected ? c.onPrimary : c.text,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── 공용 칩 버튼 (고정 높이 52dp — 여백 포함 가상 56dp+ 히트존) ──
class _ChipButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;
  final Color borderColor;
  final Widget child;

  const _ChipButton({
    required this.selected,
    required this.onTap,
    required this.bg,
    required this.fg,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

// ─── AR square 아이콘 버튼 ─────────────────────────────
class _SquareIconButton extends StatelessWidget {
  final IconData? icon;
  final bool progress;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;
  final Color borderColor;

  const _SquareIconButton({
    required this.icon,
    required this.progress,
    required this.onTap,
    required this.bg,
    required this.fg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: progress
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            : Icon(icon, size: 22, color: fg),
      ),
    );
  }
}
