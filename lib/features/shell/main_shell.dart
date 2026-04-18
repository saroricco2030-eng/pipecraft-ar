import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/pipe_specs.dart';
import '../../core/extensions/build_context_ext.dart';
import '../../core/storage/prefs_keys.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../ar/ar_screen.dart';
import '../bending/bending_screen.dart';
import '../offset/offset_screen.dart';

/// 3-탭 네비게이션 + 공용 설정 스트립(기기/관경) 셸.
///
/// 기기·관경 선택은 전역 공유 상태로 `SharedPreferences`에 저장되며,
/// 각 탭은 `IndexedStack`로 감싸 상태를 유지한다.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  Machine _machine = Machine.robend4000;
  int _selectedOd = 15;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ─── SharedPreferences (global + 기존 키 마이그레이션) ─
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    int? machineIdx = prefs.getInt(PrefsKeys.machine);
    int? od = prefs.getInt(PrefsKeys.od);

    // Phase 1 → Phase 2 키 이동 (1회성)
    if (machineIdx == null) {
      machineIdx = prefs.getInt(PrefsKeys.legacyMachine);
      if (machineIdx != null) {
        await prefs.setInt(PrefsKeys.machine, machineIdx);
        await prefs.remove(PrefsKeys.legacyMachine);
      }
    }
    if (od == null) {
      od = prefs.getInt(PrefsKeys.legacyOd);
      if (od != null) {
        await prefs.setInt(PrefsKeys.od, od);
        await prefs.remove(PrefsKeys.legacyOd);
      }
    }

    if (!mounted) return;
    setState(() {
      if (machineIdx != null && machineIdx < Machine.values.length) {
        _machine = Machine.values[machineIdx];
      }
      if (od != null && pipeSpecs.containsKey(od)) {
        _selectedOd = od;
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefsKeys.machine, _machine.index);
    await prefs.setInt(PrefsKeys.od, _selectedOd);
  }

  void _onMachineChanged(Machine m) {
    setState(() => _machine = m);
    _saveSettings();
  }

  void _onOdChanged(int od) {
    setState(() => _selectedOd = od);
    _saveSettings();
  }

  String _appBarTitle(BuildContext context) => switch (_index) {
    0 => context.l10n.appTitle,
    1 => context.l10n.offsetScreenTitle,
    2 => context.l10n.arScreenTitle,
    _ => context.l10n.appTitle,
  };

  // ─── Build ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final l = context.l10n;
    final themeCtrl = ThemeController.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.card,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 48,
        title: _AppBarTitle(title: _appBarTitle(context), accent: c.primary),
        actions: [
          if (themeCtrl != null) _ThemeToggleAction(controller: themeCtrl),
        ],
      ),
      body: Column(
        children: [
          // Settings Strip은 밴딩/오프셋 탭에서만 (AR에는 불필요)
          if (_index < 2)
            _SettingsStrip(
              machine: _machine,
              selectedOd: _selectedOd,
              onTap: _showSettingsSheet,
            ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                BendingScreen(machine: _machine, selectedOd: _selectedOd),
                OffsetScreen(machine: _machine, selectedOd: _selectedOd),
                const ArScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: c.navBar,
        indicatorColor: c.primary.withValues(alpha: 0.1),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.straighten_outlined),
            selectedIcon: Icon(Icons.straighten, color: c.primary),
            label: l.navBending,
          ),
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route, color: c.primary),
            label: l.navOffset,
          ),
          NavigationDestination(
            icon: const Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt, color: c.primary),
            label: l.navAr,
          ),
        ],
      ),
    );
  }

  // ─── 설정 바텀시트 ────────────────────────────────────
  void _showSettingsSheet() {
    final c = context.appColors;
    final l = context.l10n;
    final pipeOds = pipeSpecs.keys.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: c.text3.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.settingsSelectTitle,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel(text: l.settingsPillMachine, color: c.text3),
                    const SizedBox(height: 8),
                    _MachineSelector(
                      selected: _machine,
                      onChanged: (m) {
                        _onMachineChanged(m);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel(text: l.settingsPillDiameter, color: c.text3),
                    const SizedBox(height: 8),
                    _OdSelector(
                      ods: pipeOds,
                      selected: _selectedOd,
                      onChanged: (od) {
                        _onOdChanged(od);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── AppBar 타이틀 + 브랜드 점 ───────────────────────────
class _AppBarTitle extends StatelessWidget {
  final String title;
  final Color accent;
  const _AppBarTitle({required this.title, required this.accent});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: c.text,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _ThemeToggleAction extends StatelessWidget {
  final ThemeController controller;
  const _ThemeToggleAction({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final l = context.l10n;
    return IconButton(
      icon: Icon(
        switch (controller.themeMode) {
          ThemeMode.light => Icons.light_mode,
          ThemeMode.dark => Icons.dark_mode,
          _ => Icons.brightness_auto,
        },
        color: c.text2,
        size: 20,
      ),
      tooltip: switch (controller.themeMode) {
        ThemeMode.light => l.themeLightMode,
        ThemeMode.dark => l.themeDarkMode,
        _ => l.themeSystemMode,
      },
      onPressed: controller.onCycleTheme,
    );
  }
}

// ─── Settings Strip (기기 · 관경 · 스프링백) ───────────
class _SettingsStrip extends StatelessWidget {
  final Machine machine;
  final int selectedOd;
  final VoidCallback onTap;

  const _SettingsStrip({
    required this.machine,
    required this.selectedOd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final l = context.l10n;
    final sb = springBack[machine]?[selectedOd]?.toInt() ?? 0;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.headerBg,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          _SettingsPill(
            label: l.settingsPillMachine,
            value: machine.shortLabel,
            onTap: onTap,
          ),
          const SizedBox(width: 8),
          _SettingsPill(
            label: l.settingsPillDiameter,
            value: '${selectedOd}mm',
            onTap: onTap,
          ),
          const Spacer(),
          Text(
            l.settingsSpringbackShort(sb),
            style: TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 11,
              color: c.text3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPill extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingsPill({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'DM Mono',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: c.text3),
          ],
        ),
      ),
    );
  }
}

// ─── 시트 내부 컴포넌트들 ────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
      color: color,
    ),
  );
}

class _MachineSelector extends StatelessWidget {
  final Machine selected;
  final ValueChanged<Machine> onChanged;

  const _MachineSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
      children: Machine.values.map((m) {
        final isSelected = m == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: m == Machine.values.last ? 0 : 8),
            child: Semantics(
              label: m.label,
              selected: isSelected,
              button: true,
              child: GestureDetector(
                onTap: () => onChanged(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? c.primary : c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? c.primary : c.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    m.label,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? c.onPrimary : c.text2,
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
}

class _OdSelector extends StatelessWidget {
  final List<int> ods;
  final int selected;
  final ValueChanged<int> onChanged;

  const _OdSelector({
    required this.ods,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ods.map((od) {
        final isSelected = od == selected;
        return Semantics(
          label: '${od}mm pipe',
          selected: isSelected,
          button: true,
          child: GestureDetector(
            onTap: () => onChanged(od),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? c.chipSelected : c.chipUnselected,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? c.chipSelected : c.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$od',
                style: TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? c.chipSelectedText : c.text2,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
