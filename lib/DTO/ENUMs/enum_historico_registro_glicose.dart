import 'package:insulog/DTO/ENUMs/enum_registroGlicose.dart';

class HistoricoRegistroGlicoseResponse {
  const HistoricoRegistroGlicoseResponse({
    required this.media,
    required this.totalBaixos,
    required this.totalNormais,
    required this.totalAlertas,
    required this.statusMedia,
    required this.statusMediaDescricao,
    required this.registros,
  });

  final int media;
  final int totalBaixos;
  final int totalNormais;
  final int totalAlertas;
  final int statusMedia;
  final String statusMediaDescricao;
  final List<RegistroGlicose> registros;

  factory HistoricoRegistroGlicoseResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final responseJson = data is Map<String, dynamic> ? data : json;
    final registrosJson = responseJson['registros'];

    if (registrosJson is! List) {
      throw FormatException('Campo "registros" ausente ou inválido.');
    }

    return HistoricoRegistroGlicoseResponse(
      media: _readInt(responseJson['media']),
      totalBaixos: _readInt(responseJson['totalBaixos']),
      totalNormais: _readInt(responseJson['totalNormais']),
      totalAlertas: _readInt(responseJson['totalAlertas']),
      statusMedia: _readInt(responseJson['statusMedia']),
      statusMediaDescricao:
          responseJson['statusMediaDescricao']?.toString() ?? '',
      registros: registrosJson
          .map((item) => RegistroGlicose.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
