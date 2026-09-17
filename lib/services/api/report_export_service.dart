import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:insulog/services/api/api_service.dart';
import 'package:insulog/services/local/api_ip_service.dart';

enum ReportFormat {
  pdf('application/pdf'),
  xlsx('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

  const ReportFormat(this.mimeType);
  final String mimeType;
}

class ReportFile {
  const ReportFile({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
}

class ReportExportService {
  ReportExportService({http.Client? client, Future<String> Function()? baseUrl})
    : _client = client,
      _baseUrl = baseUrl ?? ApiIpService().getBaseUrl;

  final http.Client? _client;
  final Future<String> Function() _baseUrl;

  static String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<ReportFile> fetchReport({
    required int userId,
    required DateTime start,
    required DateTime end,
    required ReportFormat format,
  }) async {
    final firstDay = formatDate(start);
    final lastDay = formatDate(end);
    if (userId <= 0 || firstDay.compareTo(lastDay) > 0) {
      throw ApiException(
        message: 'Usuário ou período inválido.',
        statusCode: 400,
      );
    }
    try {
      final uri = Uri.parse('${await _baseUrl()}/exportacoes/relatorio')
          .replace(
            queryParameters: {
              'id_usuario': '$userId',
              'dataInicio': firstDay,
              'dataFim': lastDay,
              'formato': format.name,
            },
          );
      final get = _client?.get ?? http.get;
      final response = await get(
        uri,
        headers: {'Accept': format.mimeType},
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        var message = 'Não foi possível gerar o relatório.';
        try {
          final error = jsonDecode(utf8.decode(response.bodyBytes));
          if (error is Map && error['error'] is String) {
            message = error['error'] as String;
          }
        } on FormatException {
          // Respostas de proxy podem não conter JSON.
        }
        throw ApiException(message: message, statusCode: response.statusCode);
      }

      final bytes = response.bodyBytes;
      final expected = format == ReportFormat.pdf
          ? [37, 80, 68, 70, 45]
          : [80, 75, 3, 4];
      final hasSignature =
          bytes.length >= expected.length &&
          List.generate(
            expected.length,
            (i) => bytes[i] == expected[i],
          ).every((value) => value);
      final mime = response.headers['content-type']?.split(';').first.trim();
      if (mime != format.mimeType || !hasSignature) {
        throw ApiException(
          message: 'A API retornou um arquivo inválido.',
          statusCode: 502,
        );
      }

      // Nome previsível, sem permitir caminhos fornecidos pelo servidor.
      final fallback =
          'relatorio-insulog-$userId-$firstDay-$lastDay.${format.name}';
      final disposition = response.headers['content-disposition'] ?? '';
      final serverName = RegExp(
        r'filename="([a-zA-Z0-9._-]+)"',
      ).firstMatch(disposition)?.group(1);
      return ReportFile(
        bytes: bytes,
        filename: serverName != null && serverName.endsWith('.${format.name}')
            ? serverName
            : fallback,
        mimeType: format.mimeType,
      );
    } on TimeoutException {
      throw ApiException(
        message: 'A geração demorou demais. Tente novamente.',
        statusCode: 408,
      );
    } on SocketException {
      throw ApiException(
        message: 'Não foi possível conectar ao servidor.',
        statusCode: 503,
      );
    } on http.ClientException {
      throw ApiException(
        message: 'Falha na conexão ao baixar o relatório.',
        statusCode: 503,
      );
    }
  }
}
