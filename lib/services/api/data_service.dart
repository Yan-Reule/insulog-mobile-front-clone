import 'package:flutter/material.dart';
import 'package:insulog/DTO/ENUMs/clock_alarm_draft.dart';
import 'package:insulog/DTO/ENUMs/enum_clock_register.dart';
import 'package:insulog/DTO/ENUMs/enum_form_registroGlicose.dart';
import 'package:insulog/DTO/ENUMs/enum_historico_registro_glicose.dart';
import 'package:insulog/DTO/ENUMs/enum_registroGlicose.dart';
import 'package:insulog/DTO/ENUMs/enum_registroInsulina.dart';
import 'package:insulog/services/api/api_service.dart';
import 'package:insulog/utils/api_date_time_formatter.dart';

class DataService {
  DataService._();

  static final DataService _instance = DataService._();

  factory DataService() => _instance;

  final ApiService _apiService = ApiService();

  Future<HistoricoRegistroGlicoseResponse> fetchHistoricoGlicose(
    int idUsuario, {
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      final response = await _apiService.get(
        'registros-glicose/usuario/$idUsuario/historico',
        queryParameters: {
          'dataInicio': ApiDateTimeFormatter.format(dataInicio),
          'dataFim': ApiDateTimeFormatter.format(dataFim),
        },
      );

      if (response is Map<String, dynamic>) {
        return HistoricoRegistroGlicoseResponse.fromJson(response);
      }

      throw DataException('Resposta inesperada da API.');
    } on ApiException catch (e) {
      throw DataException(e.message, statusCode: e.statusCode);
    } on DataException {
      rethrow;
    } catch (e) {
      throw DataException('Erro ao buscar histórico: $e');
    }
  }

  Future<RegistrosGlicoseResponse> fetchData(
    int idUsuario,
    String route,
    bool isToday,
  ) async {
    try {
      final hoje = DateTime.now();
      final inicioDoDia = DateTime(hoje.year, hoje.month, hoje.day);
      final fimDoDia = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);

      final response = await _apiService.get(
        '$route/usuario/$idUsuario',
        queryParameters: {
          'dataInicio': isToday
              ? ApiDateTimeFormatter.format(inicioDoDia)
              : null,
          'dataFim': isToday ? ApiDateTimeFormatter.format(fimDoDia) : null,
          "quantidade": !isToday ? 6 : null,
        },
      );

      if (response is Map<String, dynamic>) {
        return RegistrosGlicoseResponse.fromJson(response);
      }

      if (response is List) {
        return RegistrosGlicoseResponse.fromList(response);
      }

      throw DataException('Resposta inesperada da API.');
    } on ApiException catch (e) {
      throw DataException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw DataException('Erro ao buscar dados: $e');
    }
  }

  Future<EnumClockRegisterResponse> fetchClockData(int idUsuario) async {
    try {
      final response = await _apiService.get('alarmes/usuario/$idUsuario');

      if (response is Map<String, dynamic>) {
        return EnumClockRegisterResponse.fromJson(response);
      }

      if (response is List) {
        return EnumClockRegisterResponse.fromList(response);
      }

      throw DataException('Resposta inesperada da API.');
    } on ApiException catch (e) {
      throw DataException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw DataException('Erro ao buscar dados: $e');
    }
  }

  Future<void> createClockAlarm(ClockAlarmDraft alarm) async {
    try {
      await _apiService.post('alarmes', alarm.toCreateJson());
    } on ApiException catch (e) {
      throw DataException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw DataException('Erro ao criar alarme: $e');
    }
  }

  Future<EnumClockRegister> updateClockAlarm(
    int idAlarme,
    EnumClockRegister alarm,
  ) async {
    try {
      final response = await _apiService.put(
        'alarmes/$idAlarme',
        alarm.toUpdateJson(),
      );

      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response['alarme'];
        final alarmJson = data is Map<String, dynamic> ? data : response;

        return EnumClockRegister.fromJson(alarmJson);
      }

      throw DataException('Resposta inesperada da API.');
    } on ApiException catch (e) {
      throw DataException(e.message, statusCode: e.statusCode);
    } on DataException {
      rethrow;
    } catch (e) {
      throw DataException('Erro ao atualizar alarme: $e');
    }
  }

  Future<void> updateClockAlarmDetails(
    int idAlarme,
    ClockAlarmDraft alarm,
  ) async {
    try {
      await _apiService.put('alarmes/$idAlarme', alarm.toUpdateJson());
    } on ApiException catch (e) {
      throw DataException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw DataException('Erro ao atualizar alarme: $e');
    }
  }

  Future<void> deleteClockAlarm(int idAlarme) async {
    try {
      await _apiService.delete('alarmes/$idAlarme');
    } on ApiException catch (e) {
      throw DataException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw DataException('Erro ao excluir alarme: $e');
    }
  }

  Future<RegistroInsulinaResponse> fetchInsulinaData(
    int idUsuario, {
    int quantidade = 4,
  }) async {
    try {
      final response = await _apiService.get(
        'registros-insulina/usuario/$idUsuario',
        queryParameters: {'quantidade': quantidade},
      );

      if (response is Map<String, dynamic>) {
        return RegistroInsulinaResponse.fromJson(response);
      }

      if (response is List) {
        return RegistroInsulinaResponse.fromList(response);
      }

      throw DataException('Resposta inesperada da API.');
    } on ApiException catch (e) {
      throw DataException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw DataException('Erro ao buscar dados: $e');
    }
  }

  Future<void> createRegistroGlicose(
    NewRegistroGlicose novoRegistro,
    BuildContext context,
  ) async {
    try {
      await _apiService.post('registros-glicose', novoRegistro.toJson());
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      throw DataException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw DataException('Erro ao criar registro: $e');
    }
  }

  Future<void> updateRegistroGlicose(
    int idRegistro,
    NewRegistroGlicose registro,
  ) async {
    try {
      await _apiService.put('registros-glicose/$idRegistro', registro.toJson());
    } on ApiException catch (e) {
      throw DataException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw DataException('Erro ao atualizar registro: $e');
    }
  }

  Future<NewRegistroGlicose> fetchRegistroGlicoseById(int idRegistro) async {
    try {
      debugPrint('[EDIT][REGISTRO_GLICOSE] Buscando registro id=$idRegistro');
      final response = await _apiService.get('registros-glicose/$idRegistro');

      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final recordJson = data is Map<String, dynamic> ? data : response;

        return _registroGlicoseFormFromJson(recordJson);
      }

      throw DataException('Resposta inesperada da API.');
    } on ApiException catch (e) {
      throw DataException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw DataException('Erro ao buscar registro: $e');
    }
  }

  Future<void> deleteRegistroGlicose(int idRegistro) async {
    try {
      await _apiService.delete('registros-glicose/$idRegistro');
    } on ApiException catch (e) {
      throw DataException(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw DataException('Erro ao excluir registro: $e');
    }
  }

  NewRegistroGlicose _registroGlicoseFormFromJson(Map<String, dynamic> json) {
    final glicoseJson = _readMap(json['glicose']) ?? <String, dynamic>{};
    final periodoJson = _readMap(json['periodo']) ?? <String, dynamic>{};
    final insulinaJson = _readMap(json['insulina']) ?? <String, dynamic>{};
    final dataHora = _readDateTime(
      glicoseJson['data_hora'] ??
          glicoseJson['dataHora'] ??
          json['data_hora'] ??
          json['dataHora'] ??
          json['horaDoRegistro'],
    );

    return NewRegistroGlicose(
      idUsuario: (json['id_usuario'] ?? json['idUsuario'] ?? '').toString(),
      nivelGlicose: _readInt(
        glicoseJson['nivel'] ?? json['nivel_glicose'] ?? json['nivelGlicose'],
      ),
      periodoId: _readInt(
        periodoJson['id_periodo'] ??
            periodoJson['idPeriodo'] ??
            json['id_periodo'] ??
            json['periodoId'],
      ),
      horaDoRegistro: dataHora,
      dataDoRegistro: dataHora,
      unidadeInsulina: _readInt(
        insulinaJson['unidades'] ??
            insulinaJson['unidade_insulina'] ??
            insulinaJson['unidadeInsulina'],
      ),
      tipoInsulinaId: _readInt(
        insulinaJson['id_tipo_insulina'] ??
            insulinaJson['idTipoInsulina'] ??
            insulinaJson['tipoInsulinaId'],
      ),
      observacao: (json['observacao'] ?? '').toString(),
    );
  }

  Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    return null;
  }

  DateTime _readDateTime(dynamic value) {
    try {
      return ApiDateTimeFormatter.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DataException implements Exception {
  final String message;
  final int? statusCode;

  DataException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode == null) {
      return 'DataException: $message';
    }

    return 'DataException: $message (Status code: $statusCode)';
  }
}
