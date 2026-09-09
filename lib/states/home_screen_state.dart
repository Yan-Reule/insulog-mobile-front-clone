import 'dart:async';

import 'package:flutter/material.dart';
import 'package:insulog/DTO/ENUMs/enum_registroGlicose.dart';
import 'package:insulog/globals.dart';
import 'package:insulog/screens/glucose_record_form_screen.dart';
import 'package:insulog/services/api/data_service.dart';
import 'package:insulog/widgets/app_notification.dart';
import 'package:insulog/services/local/saved_login_service.dart';
import 'package:insulog/widgets/custom_button_widget.dart';

class HomeScreenState extends ChangeNotifier {
  HomeScreenState._();

  static final HomeScreenState instance = HomeScreenState._();

  factory HomeScreenState() => instance;

  static const int visibleRecordsLimit = 4;

  final SavedLoginService _savedLoginService = SavedLoginService();
  late List<RegistroGlicose> registrosGlicose = [];

  bool isListOpen = false;
  bool get isListOp => isListOpen;
  List<RegistroGlicose> get visibleRecords => returnList();
  bool get hasHiddenRecords => registrosGlicose.length > visibleRecordsLimit;
  bool get canShowMoreRecords => !isListOpen && hasHiddenRecords;
  bool get canShowLessRecords => isListOpen && hasHiddenRecords;
  String mediaGlicose = '';
  String statusMediaDiariaDescricao = '';
  int _statusMedia = 3;
  int colorStatusMedia = 0xfffefefe;
  String _recordSelectedId = '';

  String get recordSelectedId => _recordSelectedId;

  int get statusMedia => _statusMedia;

  List<RegistroGlicose> returnList() {
    if (isListOpen) {
      return registrosGlicose;
    }

    return registrosGlicose.take(visibleRecordsLimit).toList();
  }

  bool isRecordSelected(RegistroGlicose record) {
    return _recordSelectedId == record.id.toString();
  }

  void onTapRecord(RegistroGlicose record) {
    _recordSelectedId = '';
    notifyListeners();
  }

  Future<void> onLongPressRecord(
    RegistroGlicose record,
    BuildContext context,
    Size size,
  ) async {
    _recordSelectedId = record.id.toString();
    notifyListeners();

    await showDialog(
      context: context,
      builder: (context) {
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
                  border: Border(
                    top: BorderSide(color: Color(record.colorStatus), width: 6),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: size.width * 0.12,
                          height: size.width * 0.12,
                          decoration: BoxDecoration(
                            color: Color(record.colorStatus).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.water_drop,
                            color: Color(record.colorStatus),
                            size: size.width * 0.065,
                          ),
                        ),
                        SizedBox(width: size.width * 0.035),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detalhes do registro',
                                style: TextStyle(
                                  fontSize: size.width * 0.052,
                                  color: const Color(0xFF171717),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: size.height * 0.004),
                              Text(
                                _formatDate(record.horaDoRegistro),
                                style: TextStyle(
                                  fontSize: size.width * 0.038,
                                  color: const Color(0xFF6B6B6B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          onPressed: () => Navigator.pop(context),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Glicose',
                            style: TextStyle(
                              fontSize: size.width * 0.038,
                              color: const Color(0xFF6B6B6B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: size.height * 0.004),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: record.nivelGlicose.toString(),
                                  style: TextStyle(
                                    fontSize: size.width * 0.115,
                                    color: const Color(0xFF171717),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: ' mg/dL',
                                  style: TextStyle(
                                    fontSize: size.width * 0.045,
                                    color: const Color(0xFF4C4C4C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusChip(record, size),
                        ],
                      ),
                    ),
                    SizedBox(height: size.height * 0.018),
                    _buildInfoRow(
                      size,
                      icon: Icons.restaurant,
                      label: 'Periodo',
                      value: record.periodo.isEmpty
                          ? 'Nao informado'
                          : record.periodo,
                    ),
                    _buildInfoRow(
                      size,
                      icon: Icons.access_time,
                      label: 'Hora',
                      value: record.horaFormatada,
                    ),
                    _buildInfoRow(
                      size,
                      icon: Icons.calendar_today,
                      label: 'Data',
                      value: _formatDate(record.horaDoRegistro),
                    ),
                    _buildInfoRow(
                      size,
                      icon: Icons.tag,
                      label: 'Identificador',
                      value: '#${record.id}',
                    ),
                    SizedBox(height: size.height * 0.018),
                    SizedBox(
                      width: double.infinity,
                      height: size.height * 0.052,
                      child: _EditRegistroButton(
                        size: size,
                        onEdit: () => _editRegistroGlicose(record, context),
                      ),
                    ),
                    SizedBox(height: size.height * 0.009),
                    SizedBox(
                      width: double.infinity,
                      height: size.height * 0.052,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            210,
                            44,
                            44,
                          ),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () =>
                            _showDeleteRegistroDialog(record, context, size),
                        child: Text(
                          'Excluir ',
                          style: TextStyle(
                            fontSize: size.width * 0.043,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

    _recordSelectedId = '';
    notifyListeners();
  }

  Future<void> _showDeleteRegistroDialog(
    RegistroGlicose record,
    BuildContext parentContext,
    Size size,
  ) async {
    final deleted = await showDialog<bool>(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _DeleteRegistroDialog(
          size: size,
          onDelete: () => _deleteRegistroGlicose(record),
        );
      },
    );

    if (deleted == true && parentContext.mounted) {
      Navigator.pop(parentContext);
    }
  }

  Future<void> _deleteRegistroGlicose(RegistroGlicose record) async {
    await DataService().deleteRegistroGlicose(record.id);
    await refreshRecords();
  }

  Future<void> _editRegistroGlicose(
    RegistroGlicose record,
    BuildContext context,
  ) async {
    final navigator = Navigator.of(context);
    final registro = await DataService().fetchRegistroGlicoseById(record.id);

    if (!context.mounted) {
      return;
    }

    navigator.pop();

    final result = await navigator.pushNamed(
      '/glucoseRecordForm',
      arguments: GlucoseRecordFormEditArgs(
        idRegistro: record.id,
        registro: registro,
      ),
    );

    if (result == true) {
      await refreshRecords();
    }
  }

  Widget _buildStatusChip(RegistroGlicose record, Size size) {
    final statusText = record.statusDescricao.isEmpty
        ? 'Status nao informado'
        : record.statusDescricao;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.035,
        vertical: size.height * 0.012,
      ),
      decoration: BoxDecoration(
        color: Color(record.colorStatus).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: size.width * 0.028,
            height: size.width * 0.028,
            decoration: BoxDecoration(
              color: Color(record.colorStatus),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: size.width * 0.025),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: Color(record.colorStatus),
                fontSize: size.width * 0.04,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    Size size, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.014),
      child: Row(
        children: [
          Icon(icon, size: size.width * 0.052, color: const Color(0xFF6B6B6B)),
          SizedBox(width: size.width * 0.025),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF6B6B6B),
                fontSize: size.width * 0.04,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: const Color(0xFF171717),
                fontSize: size.width * 0.04,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();

    return '$day/$month/$year';
  }

  void setListOpen(bool isOpen) {
    isListOpen = isOpen;
  }

  Future<void> openScreen(BuildContext context) async {
    final credenciais = await _savedLoginService.getCredentials();

    if (credenciais != null) {
      Globals().setUserId(credenciais.userId);
      Globals().setUsername(credenciais.username);
    }

    AppNotification.success(context, 'Login realizado com sucesso!');

    await refreshRecords();
  }

  Future<void> refreshRecords() async {
    var userId = Globals().userId;

    if (userId <= 0) {
      final credenciais = await _savedLoginService.getCredentials();
      userId = credenciais?.userId ?? 0;
    }

    if (userId <= 0) {
      return;
    }

    try {
      final dados = await DataService().fetchData(
        userId,
        'registros-glicose',
        true,
      );

      registrosGlicose = dados.registros;
      mediaGlicose = dados.mediaDiaria.toString();
      statusMediaDiariaDescricao = dados.statusMediaDiariaDescricao;
      _statusMedia = dados.statusMediaDiaria;

      switch (_statusMedia) {
        case 0:
          colorStatusMedia = 0xFFFFC81e;
          break;
        case 1:
          colorStatusMedia = 0xFF3ea75f;
          break;
        case 2:
          colorStatusMedia = 0xFFD62828;
          break;
        default:
          colorStatusMedia = 0xFF808080;
          break;
      }

      notifyListeners();
    } on DataException catch (e) {
      debugPrint(e.toString());
    }
  }

  String returnNameLogin() {
    return Globals().username;
  }

  String returnFirstNameCaractere() {
    final username = Globals().username.trim();

    if (username.isEmpty) {
      return '';
    }

    return username[0].toUpperCase();
  }

  String returnCurrentDateLabel() {
    const weekDays = [
      'Segunda-feira',
      'Terca-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sabado',
      'Domingo',
    ];
    const months = [
      'janeiro',
      'fevereiro',
      'marco',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    final now = DateTime.now();
    final weekDay = weekDays[now.weekday - 1];
    final month = months[now.month - 1];

    return '$weekDay, ${now.day} de $month';
  }

  void showMoreRecords() {
    if (!canShowMoreRecords) {
      return;
    }

    setListOpen(true);
    notifyListeners();
  }

  void showLessRecords() {
    if (!canShowLessRecords) {
      return;
    }

    setListOpen(false);
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    await _savedLoginService.clearCredentials();
    Globals().clearUsername();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}

class _EditRegistroButton extends StatefulWidget {
  final Size size;
  final Future<void> Function() onEdit;

  const _EditRegistroButton({required this.size, required this.onEdit});

  @override
  State<_EditRegistroButton> createState() => _EditRegistroButtonState();
}

class _EditRegistroButtonState extends State<_EditRegistroButton> {
  bool _isLoading = false;

  Future<void> _handleEdit() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onEdit();
    } on DataException catch (e) {
      if (mounted) {
        AppNotification.error(context, e.message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomButtonWidget(
      text: 'Editar Registro',
      isLoading: _isLoading,
      loadingColor: Colors.white,
      isFontBold: true,
      textSize: widget.size.width * 0.043,
      textColor: Colors.white,
      onpressTextColor: Colors.white,
      bgColor: const Color.fromARGB(255, 59, 109, 244),
      onpressBgColor: const Color.fromARGB(255, 41, 87, 210),
      borderRadius: BorderRadius.circular(10),
      onPressed: _isLoading ? null : _handleEdit,
    );
  }
}

class _DeleteRegistroDialog extends StatefulWidget {
  final Size size;
  final Future<void> Function() onDelete;

  const _DeleteRegistroDialog({required this.size, required this.onDelete});

  @override
  State<_DeleteRegistroDialog> createState() => _DeleteRegistroDialogState();
}

class _DeleteRegistroDialogState extends State<_DeleteRegistroDialog> {
  static const int _totalSeconds = 10;

  Timer? _timer;
  int _remainingSeconds = _totalSeconds;
  bool _isDeleting = false;
  String? _errorMessage;

  double get _progress => (_totalSeconds - _remainingSeconds) / _totalSeconds;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isDeleting) {
        return;
      }

      if (_remainingSeconds <= 1) {
        setState(() {
          _remainingSeconds = 0;
        });
        _confirmDelete();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });
    });
  }

  Future<void> _confirmDelete() async {
    if (_isDeleting) {
      return;
    }

    _timer?.cancel();

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await widget.onDelete();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on DataException catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorMessage = e.message;
        });
      }
    }
  }

  void _cancelDelete() {
    _timer?.cancel();
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size.width * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Excluir registro?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF171717),
                fontSize: size.width * 0.055,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: size.height * 0.018),
            Text(
              _isDeleting ? 'Excluindo...' : '$_remainingSeconds',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFD62828),
                fontSize: size.width * (_isDeleting ? 0.09 : 0.18),
                fontWeight: FontWeight.w800,
              ),
            ),
            LinearProgressIndicator(
              value: _progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 6,
              color: const Color(0xFFD62828),
              backgroundColor: const Color(0xFFFFD6D6),
            ),
            SizedBox(height: size.height * 0.016),
            Text(
              'Ao fim da contagem, o registro sera excluido.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF6B6B6B),
                fontSize: size.width * 0.038,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: size.height * 0.012),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFD62828),
                  fontSize: size.width * 0.036,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            SizedBox(height: size.height * 0.024),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: size.height * 0.052,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B6B6B),
                        side: const BorderSide(color: Color(0xFFBDBDBD)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isDeleting ? null : _cancelDelete,
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: size.width * 0.03),
                Expanded(
                  child: SizedBox(
                    height: size.height * 0.052,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD62828),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isDeleting ? null : _confirmDelete,
                      child: _isDeleting
                          ? SizedBox(
                              width: size.width * 0.045,
                              height: size.width * 0.045,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: size.width * 0.04,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
