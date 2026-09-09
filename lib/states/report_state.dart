import 'dart:async';

import 'package:flutter/material.dart';
import 'package:insulog/DTO/ENUMs/enum_registroGlicose.dart';
import 'package:insulog/globals.dart';
import 'package:insulog/services/api/data_service.dart';
import 'package:insulog/services/local/saved_login_service.dart';

class ReportDay {
  const ReportDay({
    required this.date,
    required this.day,
    required this.weekday,
    required this.shortWeekday,
    required this.totalDays,
  });

  final DateTime date;
  final int day;
  final String weekday;
  final String shortWeekday;
  final int totalDays;
}

class ReportRecordWeek {
  const ReportRecordWeek({
    required this.number,
    required this.startDay,
    required this.endDay,
    required this.days,
  });

  final int number;
  final int startDay;
  final int endDay;
  final List<ReportRecordDay> days;
}

class ReportRecordDay {
  const ReportRecordDay({required this.day, required this.records});

  final int day;
  final List<RegistroGlicose> records;
}

class ReportState extends ChangeNotifier {
  ReportState._() {
    _selectedMonthDays = _createSelectedMonthDays();
  }

  static final ReportState instance = ReportState._();

  factory ReportState() => instance;

  static const int visibleReportRecordsLimit = 4;

  final SavedLoginService _savedLoginService = SavedLoginService();
  List<RegistroGlicose> _reportRecords = [];
  bool _isReportListOpen = false;
  int _media = 0;
  int _totalBaixos = 0;
  int _totalNormais = 0;
  int _totalAlertas = 0;
  int _requestId = 0;

  List<RegistroGlicose> get visibleRecords => _isReportListOpen
      ? List.unmodifiable(_reportRecords)
      : _reportRecords.take(visibleReportRecordsLimit).toList();
  int get totalRecords => _reportRecords.length;
  int get totalBaixos => _totalBaixos;
  int get totalNormais => _totalNormais;
  int get totalAlertas => _totalAlertas;
  int get media => _media;
  bool get hasHiddenRecords =>
      _reportRecords.length > visibleReportRecordsLimit;
  bool get canShowMoreRecords => !_isReportListOpen && hasHiddenRecords;
  bool get canShowLessRecords => _isReportListOpen && hasHiddenRecords;

  final List<String> listaMeses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  static const List<String> _weekdays = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  static const List<String> _shortWeekdays = [
    'SEG',
    'TER',
    'QUA',
    'QUI',
    'SEX',
    'SAB',
    'DOM',
  ];

  int get selectedDay => _selectedDay;
  int _selectedDay = 0;

  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month);
  late List<ReportDay> _selectedMonthDays;
  Timer? _monthHoldTimer;
  bool _monthHoldChangedValue = false;

  String get selectedMonth => listaMeses[_selectedDate.month - 1];

  int get selectedYear => _selectedDate.year;

  List<ReportDay> get selectedMonthDays => _selectedMonthDays;

  bool get canGoToNextMonth {
    final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1);
    return nextMonth.year <= DateTime.now().year;
  }

  void setDay(int day) {
    if (day < 1 || day > _selectedMonthDays.length) {
      throw ArgumentError('Invalid day: $day');
    }

    if (_selectedDay == day) {
      _selectedDay = 0;
    } else {
      _selectedDay = day;
    }
    notifyListeners();
    unawaited(refreshReportRecords());
  }

  void nextMonth() {
    if (_monthHoldChangedValue) {
      _monthHoldChangedValue = false;
      return;
    }

    _changeMonth(1);
  }

  void previousMonth() {
    if (_monthHoldChangedValue) {
      _monthHoldChangedValue = false;
      return;
    }

    _changeMonth(-1);
  }

  void startNextMonthHold() {
    _startMonthHold(1);
  }

  void startPreviousMonthHold() {
    _startMonthHold(-1);
  }

  void stopMonthHold() {
    _monthHoldTimer?.cancel();
    _monthHoldTimer = null;
  }

  void _startMonthHold(int offset) {
    stopMonthHold();
    _monthHoldChangedValue = false;

    _monthHoldTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      _monthHoldChangedValue = true;
      _changeMonth(offset);
    });
  }

  void _changeMonth(int offset) {
    final newDate = DateTime(_selectedDate.year, _selectedDate.month + offset);

    if (newDate.year > DateTime.now().year) {
      return;
    }

    _selectedDate = newDate;
    _selectedDay = 0;
    _isReportListOpen = false;
    _selectedMonthDays = _createSelectedMonthDays();
    notifyListeners();
    unawaited(refreshReportRecords());
  }

  List<ReportDay> _createSelectedMonthDays() {
    final lastDay = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    ).day;

    return List<ReportDay>.unmodifiable(
      List<ReportDay>.generate(lastDay, (index) {
        final date = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          index + 1,
        );

        return ReportDay(
          date: date,
          day: date.day,
          weekday: _weekdays[date.weekday - 1],
          shortWeekday: _shortWeekdays[date.weekday - 1],
          totalDays: lastDay,
        );
      }),
    );
  }

  List<ReportRecordWeek> groupRecordsByWeek(List<RegistroGlicose> records) {
    final recordsByWeekAndDay = <int, Map<int, List<RegistroGlicose>>>{};
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month);
    final lastDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    ).day;

    for (final record in records) {
      final recordDate = record.horaDoRegistro;
      if (recordDate.year != _selectedDate.year ||
          recordDate.month != _selectedDate.month) {
        continue;
      }

      final weekNumber =
          ((recordDate.day + firstDayOfMonth.weekday - 2) ~/ 7) + 1;
      final recordsByDay = recordsByWeekAndDay.putIfAbsent(
        weekNumber,
        () => {},
      );
      recordsByDay.putIfAbsent(recordDate.day, () => []).add(record);
    }

    return recordsByWeekAndDay.entries
        .map((entry) {
          final startDay =
              1 +
              ((entry.key - 1) * 7) -
              (firstDayOfMonth.weekday - DateTime.monday);
          final normalizedStartDay = startDay < 1 ? 1 : startDay;
          final endDay =
              normalizedStartDay +
              (DateTime.sunday -
                  DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    normalizedStartDay,
                  ).weekday);

          return ReportRecordWeek(
            number: entry.key,
            startDay: normalizedStartDay,
            endDay: endDay > lastDayOfMonth ? lastDayOfMonth : endDay,
            days: entry.value.entries
                .map(
                  (dayEntry) => ReportRecordDay(
                    day: dayEntry.key,
                    records: List.unmodifiable(dayEntry.value),
                  ),
                )
                .toList(growable: false),
          );
        })
        .toList(growable: false);
  }

  Future<void> refreshReportRecords() async {
    final currentRequestId = ++_requestId;
    var userId = Globals().userId;
    if (userId <= 0) {
      final credentials = await _savedLoginService.getCredentials();
      userId = credentials?.userId ?? 0;
    }
    if (userId <= 0) return;

    final selectedDay = _selectedDay;
    final start = selectedDay == 0
        ? DateTime(_selectedDate.year, _selectedDate.month)
        : DateTime(_selectedDate.year, _selectedDate.month, selectedDay);
    final end = selectedDay == 0
        ? DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59)
        : DateTime(
            _selectedDate.year,
            _selectedDate.month,
            selectedDay,
            23,
            59,
            59,
          );
    try {
      final response = await DataService().fetchHistoricoGlicose(
        userId,
        dataInicio: start,
        dataFim: end,
      );
      if (currentRequestId != _requestId) return;

      _reportRecords = response.registros;
      _media = response.media;
      _totalBaixos = response.totalBaixos;
      _totalNormais = response.totalNormais;
      _totalAlertas = response.totalAlertas;
      _isReportListOpen = false;
      notifyListeners();
    } on DataException catch (error) {
      debugPrint(error.toString());
    }
  }

  void showMoreRecords() {
    if (!canShowMoreRecords) return;
    _isReportListOpen = true;
    notifyListeners();
  }

  void showLessRecords() {
    if (!canShowLessRecords) return;
    _isReportListOpen = false;
    notifyListeners();
  }

  void openReport() {
    _selectedDay = 0;
    _isReportListOpen = false;
    _reportRecords = [];
    _media = 0;
    _totalBaixos = 0;
    _totalNormais = 0;
    _totalAlertas = 0;
    notifyListeners();
    unawaited(refreshReportRecords());
  }

  void leaveReport() {
    stopMonthHold();
    _selectedDay = 0;
    _isReportListOpen = false;
    _requestId++;
  }

  @override
  void dispose() {
    stopMonthHold();
    super.dispose();
  }

  String returnCurrentDateLabel(ReportRecordWeek week) {
    return 'SEMANA ${week.number}: DIA ${week.startDay} ATÉ DIA ${week.endDay}';
  }

  String returnDayLabel(ReportRecordDay day) {
    return 'DIA ${day.day}';
  }
}
