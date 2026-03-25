import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/presmai_app_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MedicationRoutineScreen extends StatefulWidget {
  final List<dynamic> medications;

  const MedicationRoutineScreen({
    super.key,
    required this.medications,
  });

  @override
  State<MedicationRoutineScreen> createState() =>
      _MedicationRoutineScreenState();
}

class _MedicationRoutineScreenState extends State<MedicationRoutineScreen> {
  late final List<Map<String, dynamic>> _meds;

  late final List<String> _editedNames;
  late final List<String> _editedStrengths;
  late final List<String> _editedDays;

  late final List<bool> _editedMorning;
  late final List<bool> _editedAfternoon;
  late final List<bool> _editedNight;

  bool _isUpdatingAll = false;

  @override
  void initState() {
    super.initState();
    _meds = widget.medications
        .where((m) => m is Map<String, dynamic>)
        .map((m) => Map<String, dynamic>.from(m as Map<String, dynamic>))
        .toList();

    _editedNames =
        List<String>.generate(_meds.length, (i) => _meds[i]['name']?.toString() ?? '');
    _editedStrengths = List<String>.generate(
      _meds.length,
      (i) => _meds[i]['strength']?.toString() ?? '',
    );
    _editedDays = List<String>.generate(
      _meds.length,
      (i) => _meds[i]['days']?.toString() ?? '0',
    );

    _editedMorning = List<bool>.generate(
      _meds.length,
      (i) => _meds[i]['morning'] == true,
    );
    _editedAfternoon = List<bool>.generate(
      _meds.length,
      (i) => _meds[i]['afternoon'] == true,
    );
    _editedNight = List<bool>.generate(
      _meds.length,
      (i) => _meds[i]['night'] == true,
    );
  }

  Future<void> _updateMedicationApi({
    required String medicationId,
    required String name,
    required String? strength,
    required bool morning,
    required bool afternoon,
    required bool night,
    required int days,
  }) async {
    final auth = AuthService();
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');

    final baseUrl = dotenv.get('API_URL', fallback: 'http://localhost:8000');
    final uri =
        Uri.parse('$baseUrl/prescriptions/medications/$medicationId');

    final res = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'strength': strength,
        'morning': morning,
        'afternoon': afternoon,
        'night': night,
        'days': days,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Update failed (${res.statusCode}): ${res.body}');
    }
  }

  Future<void> _handleUpdateRoutine() async {
    if (_isUpdatingAll) return;
    if (_meds.isEmpty) return;

    // 1) Preflight validation (no API calls if any row is invalid)
    final List<Map<String, dynamic>> payloads = [];
    for (var i = 0; i < _meds.length; i++) {
      final rowNum = i + 1;
      final medicationId = _meds[i]['id']?.toString() ?? '';
      final name = _editedNames[i].trim();
      final strengthRaw = _editedStrengths[i].trim();
      final strength = strengthRaw.isEmpty ? null : strengthRaw;
      final daysRaw = _editedDays[i].trim();
      final days = int.tryParse(daysRaw);
      final morning = _editedMorning[i];
      final afternoon = _editedAfternoon[i];
      final night = _editedNight[i];
      final anyTime = morning || afternoon || night;

      if (medicationId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Row $rowNum: Medication id is missing.')),
        );
        return;
      }
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Row $rowNum: Medication name is required.')),
        );
        return;
      }
      if (days == null || days < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Row $rowNum: Days must be a number >= 0.')),
        );
        return;
      }
      if (!anyTime) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Row $rowNum: Select at least one time (Morning/Afternoon/Night).')),
        );
        return;
      }

      payloads.add({
        'medicationId': medicationId,
        'name': name,
        'strength': strength,
        'morning': morning,
        'afternoon': afternoon,
        'night': night,
        'days': days,
      });
    }

    // 2) API calls
    setState(() => _isUpdatingAll = true);
    try {
      for (final p in payloads) {
        await _updateMedicationApi(
          medicationId: p['medicationId'] as String,
          name: p['name'] as String,
          strength: p['strength'] as String?,
          morning: p['morning'] as bool,
          afternoon: p['afternoon'] as bool,
          night: p['night'] as bool,
          days: p['days'] as int,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication routine updated successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isUpdatingAll = false);
    }
  }

  void _navigateToTab(NavTab tab) {
    switch (tab) {
      case NavTab.chat:
        Navigator.pushReplacementNamed(context, '/chat');
        break;
      case NavTab.alerts:
        // Already on alerts tab route.
        break;
      case NavTab.archive:
        Navigator.pushReplacementNamed(context, '/archive');
        break;
      case NavTab.profile:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            PresmaiAppBar(
              title: 'Medication Routine',
            ),
            Expanded(
              child: _meds.isEmpty
                  ? Center(
                      child: Text(
                        'No medications found in the prescription.',
                        style: GoogleFonts.manrope(
                          color: AppColors.slate500,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(
                                  label: SizedBox(
                                    width: 220,
                                    child: Center(
                                      child: Text('Name'),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 140,
                                    child: Center(
                                      child: Text('Strength'),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 80,
                                    child: Center(
                                      child: Text('Morning'),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 80,
                                    child: Center(
                                      child: Text('Afternoon'),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 80,
                                    child: Center(
                                      child: Text('Night'),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 100,
                                    child: Center(
                                      child: Text('Days'),
                                    ),
                                  ),
                                ),
                              ],
                              rows: List.generate(_meds.length, (i) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: 220,
                                        child: TextFormField(
                                          enabled: !_isUpdatingAll,
                                          key: ValueKey('med_name_$i'),
                                          initialValue: _editedNames[i],
                                          onChanged: (v) => _editedNames[i] = v,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 140,
                                        child: TextFormField(
                                          enabled: !_isUpdatingAll,
                                          key: ValueKey('med_strength_$i'),
                                          initialValue: _editedStrengths[i],
                                          onChanged: (v) =>
                                              _editedStrengths[i] = v,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 80,
                                        child: Center(
                                          child: Checkbox(
                                            value: _editedMorning[i],
                                            onChanged: _isUpdatingAll
                                                ? null
                                                : (v) {
                                                    setState(() {
                                                      _editedMorning[i] =
                                                          v ?? false;
                                                    });
                                                  },
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 80,
                                        child: Center(
                                          child: Checkbox(
                                            value: _editedAfternoon[i],
                                            onChanged: _isUpdatingAll
                                                ? null
                                                : (v) {
                                                    setState(() {
                                                      _editedAfternoon[i] =
                                                          v ?? false;
                                                    });
                                                  },
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 80,
                                        child: Center(
                                          child: Checkbox(
                                            value: _editedNight[i],
                                            onChanged: _isUpdatingAll
                                                ? null
                                                : (v) {
                                                    setState(() {
                                                      _editedNight[i] =
                                                          v ?? false;
                                                    });
                                                  },
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 100,
                                        child: TextFormField(
                                          enabled: !_isUpdatingAll,
                                          key: ValueKey('med_days_$i'),
                                          initialValue: _editedDays[i],
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) => _editedDays[i] = v,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isUpdatingAll
                                      ? null
                                      : _handleUpdateRoutine,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  child: _isUpdatingAll
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.black,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Update',
                                          style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isUpdatingAll
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    backgroundColor: AppColors.slate200,
                                    foregroundColor: AppColors.slate900,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(
                                        color: AppColors.slate300,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
            BottomNavBar(
              currentTab: NavTab.alerts,
              onTabSelected: (tab) => _navigateToTab(tab),
            ),
          ],
        ),
      ),
    );
  }
}

