import 'dart:async';

import 'package:flutter/material.dart';
import 'package:insulog/DTO/ENUMs/enum_form_registroGlicose.dart';
import 'package:insulog/DTO/ENUMs/enum_periodo_registroGlicose.dart';
import 'package:insulog/DTO/ENUMs/enum_registroGlicose.dart';
import 'package:insulog/DTO/ENUMs/enum_registroInsulina.dart';
import 'package:insulog/widgets/app_notification.dart';
import 'package:insulog/globals.dart';
import 'package:insulog/services/api/data_service.dart';
import 'package:insulog/services/local/saved_login_service.dart';

class GlucoseRecordFormScreenState extends ChangeNotifier {
  final _controller = PageController();
  PageController get controller => _controller;

  int step = 0;
  late List<RegistroGlicose> registrosGlicose = [];
  late List<RegistroInsulina> registrosInsulina = [];
  late List<EnumPeriodo> periodos = [];
  String mediaGlicose = '';
  final SavedLoginService _savedLoginService = SavedLoginService();

  final TextEditingController _glucoseImputController = TextEditingController();
  final TextEditingController _insulinaImputController =
      TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  final String userId = Globals().userId.toString();
  int? _editingRegistroId;
  int _nivelGlicose = 0;
  int _periodoId = 0;
  DateTime _horaDoRegistro = DateTime.now();
  DateTime _dataDoRegistro = DateTime.now();
  int _unidadeInsulina = 0;
  int _tipoInsulinaId = 0;
  String _observacao = '';
  bool _criarLembrete = false;
  Timer? _glucoseHoldTimer;
  bool _glucoseHoldChangedValue = false;
  Timer? _insulinaHoldTimer;
  bool _insulinaHoldChangedValue = false;

  int get nivelGlicose => _nivelGlicose;
  int get periodoId => _periodoId;
  DateTime get horaDoRegistro => _horaDoRegistro;
  DateTime get dataDoRegistro => _dataDoRegistro;
  int get unidadeInsulina => _unidadeInsulina;
  int get tipoInsulinaId => _tipoInsulinaId;
  String get observacao => _observacao;
  bool get criarLembrete => _criarLembrete;
  bool get isEditing => _editingRegistroId != null;

  bool _isErroGlicose = false;
  bool _isErroInsulina = false;
  bool _isErroPeriodo = false;

  bool get isErroGlicose => _isErroGlicose;
  bool get isErroInsulina => _isErroInsulina;
  bool get isErroPeriodo => _isErroPeriodo;

  bool get glicosePreenchida => _nivelGlicose > 0;
  bool get periodoPreenchido => _periodoId > 0;
  bool get insulinaPreenchida => _unidadeInsulina > 0 && _tipoInsulinaId > 0;
  bool get insulinaNaoInformada =>
      _unidadeInsulina == 0 && _tipoInsulinaId == 0;
  bool get insulinaIncompleta =>
      (_unidadeInsulina > 0 && _tipoInsulinaId == 0) ||
      (_unidadeInsulina == 0 && _tipoInsulinaId > 0);

  bool get isCanRegister {
    return glicosePreenchida &&
        periodoPreenchido &&
        (insulinaNaoInformada || insulinaPreenchida);
  }

  NewRegistroGlicose get novoRegistro => NewRegistroGlicose(
    idUsuario: userId,
    nivelGlicose: _nivelGlicose,
    periodoId: _periodoId,
    horaDoRegistro: _horaDoRegistro,
    dataDoRegistro: _dataDoRegistro,
    unidadeInsulina: _unidadeInsulina,
    tipoInsulinaId: _tipoInsulinaId,
    observacao: _observacao,
  );

  TextEditingController get glucoseImputController => _glucoseImputController;
  TextEditingController get insulinaImputController => _insulinaImputController;
  TextEditingController get observacaoController => _observacaoController;

  void iniciarEdicao(int idRegistro, NewRegistroGlicose registro) {
    _editingRegistroId = idRegistro;
    _nivelGlicose = registro.nivelGlicose.clamp(0, 999).toInt();
    _glucoseImputController.text = _nivelGlicose == 0
        ? ''
        : _nivelGlicose.toString();
    _periodoId = registro.periodoId;
    _horaDoRegistro = registro.horaDoRegistro;
    _dataDoRegistro = registro.dataDoRegistro;
    _unidadeInsulina = registro.unidadeInsulina.clamp(0, 999).toInt();
    _insulinaImputController.text = _unidadeInsulina == 0
        ? ''
        : _unidadeInsulina.toString();
    _tipoInsulinaId = registro.tipoInsulinaId;
    _observacao = registro.observacao;
    _observacaoController.text = registro.observacao;
    _isErroGlicose = false;
    _isErroInsulina = false;
    _isErroPeriodo = false;
    notifyListeners();
  }

  String dataFormatada() {
    return '${_dataDoRegistro.day.toString().padLeft(2, '0')}/'
        '${_dataDoRegistro.month.toString().padLeft(2, '0')}/'
        '${_dataDoRegistro.year}';
  }

  String horaFormatada() {
    return '${_horaDoRegistro.hour.toString().padLeft(2, '0')}:'
        '${_horaDoRegistro.minute.toString().padLeft(2, '0')}';
  }

  String periodoNome() {
    switch (_periodoId) {
      case 1:
        return 'Jejum';
      case 2:
        return 'Pré-prandial';
      case 3:
        return 'Pós-prandial';
      case 4:
        return 'Noturno';
      default:
        return '!!!';
    }
  }

  String tipoInsulinaNome() {
    switch (_tipoInsulinaId) {
      case 1:
        return 'Ultra-Rápida';
      case 2:
        return 'Rápida';
      case 3:
        return 'Lenta';
      default:
        return '!!!';
    }
  }

  String returnTextPeriodo() {
    switch (_periodoId) {
      case 1:
        return 'VARIAS HORAS SEM COMER';
      case 2:
        return 'ANTES DE COMER';
      case 3:
        return 'DEPOIS DE COMER';
      case 4:
        return 'ANTES DE DORMIR';
      default:
        return 'SELECIONE UM PERÍODO';
    }
  }

  void usarRegistro(int glucoseValue) {
    _setNivelGlicose(glucoseValue);
    if (step == 0) {
      next(null);
    }
  }

  void usarRegistroInsulina(RegistroInsulina registro) {
    if (!insulinaPreenchida) {
      if (step == 2) {
        next(null);
      }
    }
    _setUnidadeInsulina(registro.unidadeInsulina);
    atualizarTipoInsulina(registro.idTipoInsulina, false);
  }

  void atualizarNivelGlicose(String value) {
    _setNivelGlicose(int.tryParse(value) ?? 0, atualizarController: false);
  }

  void incrementarNivelGlicose() {
    if (_glucoseHoldChangedValue) {
      _glucoseHoldChangedValue = false;
      return;
    }

    _setNivelGlicose(_nivelGlicose + 1);
  }

  void decrementarNivelGlicose() {
    if (_glucoseHoldChangedValue) {
      _glucoseHoldChangedValue = false;
      return;
    }

    _setNivelGlicose(_nivelGlicose - 1);
  }

  void iniciarIncrementoContinuoGlicose() {
    _iniciarAlteracaoContinuaGlicose(10);
  }

  void iniciarDecrementoContinuoGlicose() {
    _iniciarAlteracaoContinuaGlicose(-10);
  }

  void pararAlteracaoContinuaGlicose() {
    _glucoseHoldTimer?.cancel();
    _glucoseHoldTimer = null;
  }

  void incrementarUnidadeInsulina() {
    if (_insulinaHoldChangedValue) {
      _insulinaHoldChangedValue = false;
      return;
    }

    _setUnidadeInsulina(_unidadeInsulina + 1);
  }

  void decrementarUnidadeInsulina() {
    if (_insulinaHoldChangedValue) {
      _insulinaHoldChangedValue = false;
      return;
    }

    _setUnidadeInsulina(_unidadeInsulina - 1);
  }

  void iniciarIncrementoContinuoInsulina() {
    _iniciarAlteracaoContinuaInsulina(1);
  }

  void iniciarDecrementoContinuoInsulina() {
    _iniciarAlteracaoContinuaInsulina(-1);
  }

  void pararAlteracaoContinuaInsulina() {
    _insulinaHoldTimer?.cancel();
    _insulinaHoldTimer = null;
  }

  void _iniciarAlteracaoContinuaGlicose(int valor) {
    pararAlteracaoContinuaGlicose();
    _glucoseHoldChangedValue = false;

    _glucoseHoldTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      _glucoseHoldChangedValue = true;
      _setNivelGlicose(_nivelGlicose + valor);
    });
  }

  void _iniciarAlteracaoContinuaInsulina(int valor) {
    pararAlteracaoContinuaInsulina();
    _insulinaHoldChangedValue = false;

    _insulinaHoldTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      _insulinaHoldChangedValue = true;
      _setUnidadeInsulina(_unidadeInsulina + valor);
    });
  }

  void _setNivelGlicose(int value, {bool atualizarController = true}) {
    _nivelGlicose = value.clamp(0, 999).toInt();

    if (atualizarController) {
      _glucoseImputController.text = _nivelGlicose == 0
          ? ''
          : _nivelGlicose.toString();
    }

    validaCampos(field: 'glicose');

    notifyListeners();
  }

  void _setUnidadeInsulina(int value, {bool atualizarController = true}) {
    _unidadeInsulina = value.clamp(0, 999).toInt();

    if (atualizarController) {
      _insulinaImputController.text = _unidadeInsulina == 0
          ? ''
          : _unidadeInsulina.toString();
    }
    validaCampos(field: 'insulina');
    notifyListeners();
  }

  void atualizarPeriodo(int value) {
    if (_periodoId == 0) {
      if (step == 1) {
        next(null);
      }
    }

    _periodoId = value;

    validaCampos(field: 'periodo');

    notifyListeners();
  }

  void atualizarHoraDoRegistro(DateTime value) {
    _horaDoRegistro = value;
    notifyListeners();
  }

  void atualizarDataDoRegistro(DateTime value) {
    _dataDoRegistro = value;
    notifyListeners();
  }

  void atualizarUnidadeInsulina(String value) {
    _setUnidadeInsulina(int.tryParse(value) ?? 0, atualizarController: false);
  }

  void atualizarTipoInsulina(int value, bool isFromBotton) {
    if (_tipoInsulinaId == value && isFromBotton) {
      _tipoInsulinaId = 0;
      validaCampos(field: 'insulina');
      notifyListeners();
      return;
    }

    _tipoInsulinaId = value;
    validaCampos(field: 'insulina');
    notifyListeners();
  }

  void atualizarObservacao(String value) {
    _observacao = value;
    notifyListeners();
  }

  void atualizarCriarLembrete(bool value) {
    _criarLembrete = value;
    notifyListeners();
  }

  void setErroGlicose(bool value) {
    _isErroGlicose = value;
  }

  void setErroInsulina(bool value) {
    _isErroInsulina = value;
  }

  void setErroPeriodo(bool value) {
    _isErroPeriodo = value;
  }

  void validaCampos({bool isFromRegister = false, required String field}) {
    switch (field) {
      case 'glicose':
        if (glicosePreenchida) {
          setErroGlicose(false);
        } else if (isFromRegister) {
          setErroGlicose(true);
        }
        break;
      case 'periodo':
        if (periodoPreenchido) {
          setErroPeriodo(false);
        } else if (isFromRegister) {
          setErroPeriodo(true);
        }
        break;
      case 'insulina':
        if (insulinaNaoInformada || insulinaPreenchida) {
          setErroInsulina(false);
        } else if (isFromRegister && insulinaIncompleta) {
          setErroInsulina(true);
        }
        break;
    }
  }

  Future<void> register(BuildContext context) async {
    validaCampos(isFromRegister: true, field: 'glicose');
    validaCampos(isFromRegister: true, field: 'periodo');
    validaCampos(isFromRegister: true, field: 'insulina');

    notifyListeners();
    if (_isErroGlicose || _isErroPeriodo || _isErroInsulina) {
      // _goToFirstErrorStep();

      AppNotification.warning(
        context,
        'Revise os campos destacados antes de continuar.',
      );
      notifyListeners();
      return;
    }

    if (!isCanRegister) {
      return;
    }

    try {
      final registro = NewRegistroGlicose(
        idUsuario: userId,
        nivelGlicose: _nivelGlicose,
        periodoId: _periodoId,
        horaDoRegistro: _horaDoRegistro,
        dataDoRegistro: _dataDoRegistro,
        unidadeInsulina: _unidadeInsulina,
        tipoInsulinaId: _tipoInsulinaId,
        observacao: _observacao,
        lembrete: _criarLembrete
            ? LembreteRegistroGlicose(
                criar: true,
                dataDoLembrete: _dataDoRegistro,
                horaDoLembrete: _horaDoRegistro,
                periodoId: _periodoId,
              )
            : null,
      );

      if (isEditing) {
        await DataService().updateRegistroGlicose(
          _editingRegistroId!,
          registro,
        );

        if (context.mounted) {
          Navigator.pop(context, true);
        }

        return;
      }

      await DataService().createRegistroGlicose(registro, context);
    } on DataException catch (e) {
      _showApiError(context, e.message);
    }
  }

  void _showApiError(BuildContext context, String message) {
    AppNotification.error(context, message);
  }

  void next(BuildContext? context) {
    if (step < 3) {
      step++;
      _controller.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    } else if (context != null && step == 3) {
      register(context);
    }
  }

  // void _goToFirstErrorStep() {
  //   if (_isErroGlicose) {
  //     _goToStep(0);
  //   } else if (_isErroPeriodo) {
  //     _goToStep(1);
  //   } else if (_isErroInsulina) {
  //     _goToStep(2);
  //   }
  // }

  // void _goToStep(int value) {
  //   step = value;
  //   _controller.animateToPage(
  //     step,
  //     duration: const Duration(milliseconds: 300),
  //     curve: Curves.easeInOut,
  //   );
  // }

  void back() {
    if (step > 0) {
      step--;
      _controller.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
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
        false,
      );

      registrosGlicose = dados.registros;
      notifyListeners();
    } on DataException catch (e) {
      debugPrint(e.toString());
    }

    try {
      final dados2 = await DataService().fetchInsulinaData(userId);

      registrosInsulina = dados2.registros;

      notifyListeners();
    } on DataException catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _glucoseImputController.dispose();
    _insulinaImputController.dispose();
    _observacaoController.dispose();
    pararAlteracaoContinuaGlicose();
    pararAlteracaoContinuaInsulina();
    super.dispose();
  }
}
