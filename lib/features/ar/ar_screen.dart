import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/ar_measure_service.dart';

const _bgColor = Color(0xFFF5F3F0);
const _red = Color(0xFFC8102E);
const _cardRadius = 12.0;
const _prefsKey = 'ar_measurements';

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
    final json = prefs.getString(_prefsKey);
    if (json != null) {
      final list = (jsonDecode(json) as List).cast<num>();
      if (mounted) {
        setState(() {
          _measurements.addAll(list.map((e) => e.toDouble()));
        });
      }
    }
  }

  Future<void> _saveMeasurements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_measurements));
  }

  Future<void> _startMeasure() async {
    setState(() => _measuring = true);
    try {
      final distance = await ArMeasureService.getDistance();
      if (distance != null && mounted) {
        setState(() {
          _measurements.insert(0, distance);
          _measuring = false;
        });
        _saveMeasurements();
        return;
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

  void _deleteMeasurement(int i) {
    setState(() => _measurements.removeAt(i));
    _saveMeasurements();
  }

  void _clearAll() {
    setState(() => _measurements.clear());
    _saveMeasurements();
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
              'AR 측정',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          if (_measurements.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFF999999)),
              tooltip: '전체 삭제',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _measurements.isEmpty
                ? _buildEmptyState()
                : _buildMeasurementList(),
          ),
          _buildMeasureButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.straighten,
            size: 64,
            color: Color(0xFFCCCCCC),
          ),
          SizedBox(height: 16),
          Text(
            '측정 기록이 없습니다',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF999999),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '아래 버튼을 눌러 AR 측정을 시작하세요',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: Color(0xFFBBBBBB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _measurements.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final dist = _measurements[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${_measurements.length - i}',
                  style: const TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _red,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Semantics(
                  label: '측정값 ${dist.round()} 밀리미터',
                  child: Text(
                    '${dist.round()} mm',
                    style: const TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Color(0xFF999999)),
                tooltip: '복사',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: dist.round().toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('클립보드에 복사되었습니다'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF999999)),
                tooltip: '삭제',
                onPressed: () => _deleteMeasurement(i),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeasureButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: _bgColor,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _measuring ? null : _startMeasure,
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
            _measuring ? '측정 중...' : 'AR 측정 시작',
            style: const TextStyle(
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
