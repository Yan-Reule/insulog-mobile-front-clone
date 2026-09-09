import 'package:flutter/material.dart';
import 'package:insulog/DTO/ENUMs/clock_alarm_draft.dart';
import 'package:insulog/DTO/ENUMs/enum_clock_register.dart';
import 'package:insulog/globals.dart';
import 'package:insulog/services/api/data_service.dart';
import 'package:insulog/services/local/alarm_platform_service.dart';
import 'package:insulog/services/local/saved_login_service.dart';
import 'package:insulog/widgets/custom_button_widget.dart';
import 'package:insulog/widgets/app_notification.dart';

class ClockState extends ChangeNotifier {
  ClockState._();

  static final ClockState instance = ClockState._();

  factory ClockState() => instance;

  List<EnumClockRegister> _registros = [];

  final SavedLoginService _savedLoginService = SavedLoginService();
  final AlarmPlatformService _alarmPlatformService =
      AlarmPlatformService.instance;
  int? _recordSelectedId;
  bool _isLoading = false;
  bool _isSaving = false;
  int? _editingAlarmId;
  String? _errorMessage;
  final Set<int> _updatingAlarmIds = <int>{};
  ClockAlarmDraft _novoAlarme = ClockAlarmDraft.defaults(
    idUsuario: Globals().userId,
  );

  int? get recordSelectedId => _recordSelectedId;
  List<EnumClockRegister> get registros => _registros;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isEditing => _editingAlarmId != null;
  String? get errorMessage => _errorMessage;
  ClockAlarmDraft get novoAlarme => _novoAlarme;

  void initializeNewAlarm() {
    _editingAlarmId = null;
    _novoAlarme = ClockAlarmDraft.defaults(idUsuario: Globals().userId);
  }

  void initializeAlarmEditing(EnumClockRegister alarm) {
    _editingAlarmId = alarm.idAlarme;
    _novoAlarme = ClockAlarmDraft(
      idUsuario: alarm.idUsuario,
      dataHora: alarm.dataHora,
      periodoId: alarm.periodo,
      registroId: alarm.idRegistro,
      diasSemana: List<String>.unmodifiable(alarm.diasSemana),
      ativo: alarm.ativo,
      vibracao: alarm.temVibracao,
      som: alarm.temSom,
    );
  }

  Future<void> saveAlarm(BuildContext context) async {
    if (_isSaving) {
      return;
    }

    var userId = Globals().userId;
    if (userId <= 0) {
      final credenciais = await _savedLoginService.getCredentials();
      userId = credenciais?.userId ?? 0;
    }

    if (userId <= 0) {
      if (context.mounted) {
        _showMessage(context, 'Usuário não identificado. Entre novamente.');
      }
      return;
    }

    const validDays = {'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'};
    final days = _novoAlarme.diasSemana
        .map((day) => day.trim().toUpperCase())
        .where(validDays.contains)
        .toSet()
        .toList(growable: false);

    if (days.isEmpty) {
      if (context.mounted) {
        _showMessage(context, 'Selecione pelo menos um dia da semana.');
      }
      return;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final alarm = _novoAlarme.copyWith(
        idUsuario: userId,
        diasSemana: days,
        // Novos alarmes desta tela são independentes. Na edição, um vínculo
        // já existente precisa ser preservado.
        registroId: isEditing ? _novoAlarme.registroId : 0,
      );
      if (isEditing) {
        await DataService().updateClockAlarmDetails(_editingAlarmId!, alarm);
        await _alarmPlatformService.scheduleDraft(_editingAlarmId!, alarm);
      } else {
        await DataService().createClockAlarm(alarm);
      }

      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } on DataException catch (e) {
      _errorMessage = e.message;
      if (context.mounted) {
        _showMessage(context, e.message);
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _showMessage(BuildContext context, String message) {
    AppNotification.error(context, message);
  }

  void updateNewAlarmHour(int hour) {
    if (_novoAlarme.hora == hour) {
      return;
    }

    final current = _novoAlarme.dataHora;
    _novoAlarme = _novoAlarme.copyWith(
      dataHora: DateTime(
        current.year,
        current.month,
        current.day,
        hour,
        current.minute,
      ),
    );
    notifyListeners();
  }

  void updateNewAlarmMinute(int minute) {
    if (_novoAlarme.minuto == minute) {
      return;
    }

    final current = _novoAlarme.dataHora;
    _novoAlarme = _novoAlarme.copyWith(
      dataHora: DateTime(
        current.year,
        current.month,
        current.day,
        current.hour,
        minute,
      ),
    );
    notifyListeners();
  }

  void updateNewAlarmSound(bool enabled) {
    if (_novoAlarme.som == enabled) {
      return;
    }

    _novoAlarme = _novoAlarme.copyWith(som: enabled);
    notifyListeners();
  }

  void updateNewAlarmVibration(bool enabled) {
    if (_novoAlarme.vibracao == enabled) {
      return;
    }

    _novoAlarme = _novoAlarme.copyWith(vibracao: enabled);
    notifyListeners();
  }

  void updateNewAlarmActive(bool enabled) {
    if (_novoAlarme.ativo == enabled) {
      return;
    }

    _novoAlarme = _novoAlarme.copyWith(ativo: enabled);
    notifyListeners();
  }

  void updateNewAlarmDays(List<String> days) {
    if (_sameDays(_novoAlarme.diasSemana, days)) {
      return;
    }

    _novoAlarme = _novoAlarme.copyWith(
      diasSemana: List<String>.unmodifiable(days),
    );
    notifyListeners();
  }

  void updateNewAlarmPeriod(int periodId) {
    if (_novoAlarme.periodoId == periodId) {
      return;
    }

    _novoAlarme = _novoAlarme.copyWith(periodoId: periodId);
    notifyListeners();
  }

  void updateNewAlarmRecord(int recordId) {
    if (_novoAlarme.registroId == recordId) {
      return;
    }

    _novoAlarme = _novoAlarme.copyWith(registroId: recordId);
    notifyListeners();
  }

  bool _sameDays(List<String> currentDays, List<String> newDays) {
    if (currentDays.length != newDays.length) {
      return false;
    }

    for (var index = 0; index < currentDays.length; index++) {
      if (currentDays[index] != newDays[index]) {
        return false;
      }
    }

    return true;
  }

  String nomePeriodo(int periodoId) {
    switch (periodoId) {
      case 1:
        return 'Jejum';
      case 2:
        return 'Pré-Prandial';
      case 3:
        return 'Pós-Prandial';
      case 4:
        return 'Noturna';
      default:
        return '';
    }
  }

  bool isUpdatingAlarm(int idAlarme) {
    return _updatingAlarmIds.contains(idAlarme);
  }

  bool isRecordSelected(EnumClockRegister record) {
    return _recordSelectedId == record.idAlarme;
  }

  void onTapRecord(EnumClockRegister record) {
    _recordSelectedId = null;
    notifyListeners();
  }

  Future<void> refreshClockRecords() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    var userId = Globals().userId;

    if (userId <= 0) {
      final credenciais = await _savedLoginService.getCredentials();
      userId = credenciais?.userId ?? 0;
    }

    if (userId <= 0) {
      _isLoading = false;
      _errorMessage = 'Usuario nao identificado.';
      notifyListeners();
      return;
    }

    try {
      final dados = await DataService().fetchClockData(userId);

      setRegistros(dados.registros);
      await _alarmPlatformService.syncAlarms(dados.registros);
    } on DataException catch (e) {
      _errorMessage = e.message;
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String formataHora(DateTime dataHora) {
    final local = dataHora.toLocal();
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  String formataData(DateTime dataHora) {
    final local = dataHora.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    return '$dia/$mes/${local.year}';
  }

  String formataDiasSemana(List<String> diasSemana) {
    if (diasSemana.isEmpty) {
      return 'Uma vez';
    }

    const labels = {
      'DOM': 'Dom',
      'SEG': 'Seg',
      'TER': 'Ter',
      'QUA': 'Qua',
      'QUI': 'Qui',
      'SEX': 'Sex',
      'SAB': 'Sab',
    };
    return diasSemana.map((day) => labels[day] ?? day).join(', ');
  }

  String infoLembrete(bool isReturnHora) {
    final alarmesAtivos = _registros.where((record) => record.ativo).toList();
    if (alarmesAtivos.isEmpty) {
      return 'Sem Lembretes ativos';
    }

    final agora = DateTime.now();
    alarmesAtivos.sort(
      (a, b) =>
          _proximaOcorrencia(a, agora).compareTo(_proximaOcorrencia(b, agora)),
    );
    final proximoAlarme = alarmesAtivos.first;

    final hora = formataHora(proximoAlarme.dataHora);
    final diasSemana = formataDiasSemana(proximoAlarme.diasSemana);

    if (isReturnHora) {
      return hora;
    } else {
      return diasSemana;
    }
  }

  DateTime _proximaOcorrencia(EnumClockRegister alarme, DateTime agora) {
    const diasDaSemana = {
      'SEG': DateTime.monday,
      'TER': DateTime.tuesday,
      'QUA': DateTime.wednesday,
      'QUI': DateTime.thursday,
      'SEX': DateTime.friday,
      'SAB': DateTime.saturday,
      'DOM': DateTime.sunday,
    };
    final horario = alarme.dataHora.toLocal();
    final diasValidos = alarme.diasSemana
        .map((dia) => diasDaSemana[dia.trim().toUpperCase()])
        .whereType<int>()
        .toSet();

    for (var deslocamento = 0; deslocamento <= 7; deslocamento++) {
      final data = agora.add(Duration(days: deslocamento));
      final candidata = DateTime(
        data.year,
        data.month,
        data.day,
        horario.hour,
        horario.minute,
      );
      final diaCompativel =
          diasValidos.isEmpty || diasValidos.contains(candidata.weekday);
      if (diaCompativel && candidata.isAfter(agora)) {
        return candidata;
      }
    }

    // O intervalo acima sempre encontra uma ocorrência semanal válida.
    throw StateError('Não foi possível calcular a próxima ocorrência.');
  }

  void setRegistros(List<EnumClockRegister> registros) {
    _registros = List<EnumClockRegister>.from(registros)
      ..sort((a, b) {
        final minutosA = a.dataHora.hour * 60 + a.dataHora.minute;
        final minutosB = b.dataHora.hour * 60 + b.dataHora.minute;

        return minutosA.compareTo(minutosB);
      });

    notifyListeners();
  }

  Future<void> updateAlarmStatus(EnumClockRegister record, bool ativo) async {
    if (_updatingAlarmIds.contains(record.idAlarme)) {
      return;
    }

    _updatingAlarmIds.add(record.idAlarme);
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedAlarm = await DataService().updateClockAlarm(
        record.idAlarme,
        record.copyWith(ativo: ativo),
      );
      final index = _registros.indexWhere(
        (alarm) => alarm.idAlarme == record.idAlarme,
      );

      if (index >= 0) {
        _registros[index] = updatedAlarm;
      }
      if (ativo) {
        await _alarmPlatformService.scheduleAlarm(updatedAlarm);
      } else {
        await _alarmPlatformService.cancelAlarm(record.idAlarme);
      }
    } on DataException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } finally {
      _updatingAlarmIds.remove(record.idAlarme);
      notifyListeners();
    }
  }

  Future<void> deleteClockAlarm(EnumClockRegister record) async {
    await DataService().deleteClockAlarm(record.idAlarme);
    await _alarmPlatformService.cancelAlarm(record.idAlarme);
    _registros.removeWhere((alarm) => alarm.idAlarme == record.idAlarme);
    notifyListeners();
  }

  Future<void> onLongPressRecord(
    EnumClockRegister record,
    BuildContext context,
    Size size,
  ) async {
    final icone = switch (record.periodo) {
      1 => Icons.wb_twilight,
      2 => Icons.restaurant,
      3 => Icons.local_dining,
      4 => Icons.nights_stay,
      _ => Icons.error,
    };

    _recordSelectedId = record.idAlarme;
    notifyListeners();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.07),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size.width * 0.04),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: size.height * 0.78,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(size.width * 0.05),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(size.width * 0.04),
                  // border: Border(
                  //   top: BorderSide(color: Color(record.colorStatus), width: 6),
                  // ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: size.width * 0.12,
                          height: size.width * 0.12,
                          decoration: BoxDecoration(
                            // color: Color(record.colorStatus).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icone,
                            color: Color(0xFF3EA75F),
                            size: size.width * 0.12,
                          ),
                        ),
                        SizedBox(width: size.width * 0.035),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Detalhes',
                              style: TextStyle(
                                fontSize: size.width * 0.065,
                                color: const Color(0xFF171717),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: Icon(Icons.close, size: size.width * 0.08),
                          color: const Color(0xFF6B6B6B),
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.024),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.045,
                        vertical: size.height * 0.018,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(size.width * 0.03),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Horario',
                                style: TextStyle(
                                  fontSize: size.width * 0.045,
                                  color: const Color(0xFF6B6B6B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: size.height * 0.004),
                              Text(
                                formataHora(record.dataHora),
                                style: TextStyle(
                                  fontSize: size.width * 0.07,
                                  color: const Color(0xFF171717),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Periodo',
                                style: TextStyle(
                                  fontSize: size.width * 0.045,
                                  color: const Color(0xFF6B6B6B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: size.height * 0.004),
                              Text(
                                nomePeriodo(record.periodo),
                                style: TextStyle(
                                  fontSize: size.width * 0.06,
                                  color: const Color(0xFF171717),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: size.height * 0.018),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.045,
                        vertical: size.height * 0.018,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(size.width * 0.03),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Dias da Semana',
                            style: TextStyle(
                              fontSize: size.width * 0.045,
                              color: const Color(0xFF6B6B6B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: size.height * 0.004),
                          Text(
                            formataDiasSemana(record.diasSemana),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: size.width * 0.055,
                              color: const Color(0xFF171717),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: size.height * 0.018),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.045,
                        vertical: size.height * 0.018,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(size.width * 0.03),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            record.ativo ? 'Alarme ativo' : 'Alarme inativo',
                            style: TextStyle(
                              fontSize: size.width * 0.06,
                              color: const Color(0xFF3EA75F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: size.height * 0.018),
                    SizedBox(
                      width: double.infinity,
                      height: size.height * 0.052,
                      child: CustomButtonWidget(
                        text: 'Editar Alarme',
                        isFontBold: true,
                        textSize: size.width * 0.043,
                        textColor: Colors.white,
                        onpressTextColor: Colors.white,
                        bgColor: const Color.fromARGB(255, 59, 109, 244),
                        onpressBgColor: const Color.fromARGB(255, 41, 87, 210),
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          final updated = await Navigator.pushNamed(
                            context,
                            '/clock_register',
                            arguments: record,
                          );

                          if (updated == true && context.mounted) {
                            await refreshClockRecords();
                          }
                        },
                      ),
                    ),
                    SizedBox(height: size.height * 0.009),
                    SizedBox(
                      width: double.infinity,
                      height: size.height * 0.052,
                      child: _DeleteAlarmButton(
                        size: size,
                        onDelete: () async {
                          await deleteClockAlarm(record);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    _recordSelectedId = null;
    notifyListeners();
  }
}

class _DeleteAlarmButton extends StatefulWidget {
  final Size size;
  final Future<void> Function() onDelete;

  const _DeleteAlarmButton({required this.size, required this.onDelete});

  @override
  State<_DeleteAlarmButton> createState() => _DeleteAlarmButtonState();
}

class _DeleteAlarmButtonState extends State<_DeleteAlarmButton> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    if (_isDeleting) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await widget.onDelete();
    } on DataException catch (e) {
      if (mounted) {
        AppNotification.error(context, e.message);

        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 210, 44, 44),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: _isDeleting ? null : _handleDelete,
      child: _isDeleting
          ? SizedBox(
              width: widget.size.width * 0.045,
              height: widget.size.width * 0.045,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Excluir',
              style: TextStyle(
                fontSize: widget.size.width * 0.043,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
