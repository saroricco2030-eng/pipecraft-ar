import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/extensions/build_context_ext.dart';
import '../../core/storage/prefs_keys.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ar_measure_service.dart';

class ArScreen extends StatefulWidget {
  const ArScreen({super.key});

  @override
  State<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> {
  final List<double> _measurements = [];
  bool _measuring = false;

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(PrefsKeys.arMeasurements);
    if (json == null) return;

    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) throw const FormatException('not a list');

      // 개별 엘리먼트 단위 복구 — 하나 깨져도 나머지는 살림
      final valid = <double>[];
      for (final e in decoded) {
        if (e is num) {
          final v = e.toDouble();
          if (v.isFinite && v >= 0) valid.add(v);
        }
      }

      // 깨진 엔트리 있었으면 저장본 동기화
      if (valid.length != decoded.length) {
        await prefs.setString(PrefsKeys.arMeasurements, jsonEncode(valid));
      }

      if (mounted) setState(() => _measurements.addAll(valid));
    } catch (e) {
      debugPrint('ArScreen: JSON decode failed — clearing');
      await prefs.remove(PrefsKeys.arMeasurements);
    }
  }

  Future<void> _saveMeasurements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.arMeasurements, jsonEncode(_measurements));
  }

  Future<void> _startMeasure() async {
    if (_measuring) return;
    setState(() => _measuring = true);
    final distance = await ArMeasure.measureWithUi(context);
    if (!mounted) return;
    if (distance != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        _measurements.insert(0, distance);
        _measuring = false;
      });
      _saveMeasurements();
    } else {
      setState(() => _measuring = false);
    }
  }

  void _deleteMeasurement(int i) {
    HapticFeedback.lightImpact();
    setState(() => _measurements.removeAt(i));
    _saveMeasurements();
  }

  void _confirmClearAll() {
    if (_measurements.isEmpty) return;
    final c = context.appColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.arConfirmClearAllTitle),
        content: Text(context.l10n.arClearAllConfirmMessage(_measurements.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              setState(() => _measurements.clear());
              _saveMeasurements();
            },
            child: Text(context.l10n.commonDelete, style: TextStyle(color: c.primary)),
          ),
        ],
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
              context.l10n.arScreenTitle,
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
        actions: [
          if (_measurements.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: c.text3),
              tooltip: context.l10n.arDeleteAllTooltip,
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _measurements.isEmpty
                ? _buildEmptyState(c)
                : _buildMeasurementList(c),
          ),
          _buildMeasureButton(c),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColors c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.straighten,
            size: 64,
            color: c.text3.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.arEmptyTitle,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.text3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.arEmptyHint,
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

  Widget _buildMeasurementList(AppColors c) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _measurements.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final dist = _measurements[i];
        return Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(cardRadius),
            boxShadow: [
              BoxShadow(
                color: c.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              // 넘버 배지 36dp
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${_measurements.length - i}',
                  style: TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // 큰 숫자 — 한눈에
              Expanded(
                child: Semantics(
                  label: context.l10n.arMeasurementLabel(dist.round()),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${dist.round()}',
                          style: TextStyle(
                            fontFamily: 'DM Mono',
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: c.text,
                            height: 1.0,
                          ),
                        ),
                        TextSpan(
                          text: ' mm',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: c.text3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 복사 (터치 타겟 48dp)
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: Icon(Icons.copy_rounded, size: 20, color: c.text3),
                  tooltip: context.l10n.commonCopyTooltip,
                  onPressed: () => _copyMeasurement(dist),
                ),
              ),
              // 삭제 (터치 타겟 48dp)
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 20, color: c.text3),
                  tooltip: context.l10n.commonDeleteTooltip,
                  onPressed: () => _deleteMeasurement(i),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 단일 측정값 복사 — 단위(mm) 포함된 문자열
  void _copyMeasurement(double dist) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: '${dist.round()} mm'));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.commonCopiedToClipboard),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  Widget _buildMeasureButton(AppColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: c.background,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _measuring ? null : _startMeasure,
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
            _measuring ? context.l10n.arMeasuringLabel : context.l10n.arStartMeasureButton,
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
              borderRadius: BorderRadius.circular(cardRadius),
            ),
          ),
        ),
      ),
    );
  }
}
