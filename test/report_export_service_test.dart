import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:insulog/services/api/api_service.dart';
import 'package:insulog/services/api/report_export_service.dart';

void main() {
  final start = DateTime(2026, 8, 1);
  final end = DateTime(2026, 8, 31);

  for (final format in ReportFormat.values) {
    test(
      'recebe ${format.name} como bytes e envia período e usuário',
      () async {
        final bytes = format == ReportFormat.pdf
            ? [37, 80, 68, 70, 45, 255, 0, 128]
            : [80, 75, 3, 4, 255, 0, 128];
        final client = MockClient((request) async {
          expect(request.url.path, '/exportacoes/relatorio');
          expect(request.url.queryParameters, {
            'id_usuario': '19',
            'dataInicio': '2026-08-01',
            'dataFim': '2026-08-31',
            'formato': format.name,
          });
          expect(request.headers['Accept'], format.mimeType);
          return http.Response.bytes(
            bytes,
            200,
            headers: {
              'content-type': format.mimeType,
              'content-disposition':
                  'attachment; filename="teste.${format.name}"',
            },
          );
        });
        final service = ReportExportService(
          client: client,
          baseUrl: () async => 'http://localhost:3000',
        );
        final file = await service.fetchReport(
          userId: 19,
          start: start,
          end: end,
          format: format,
        );
        expect(file.bytes, bytes);
        expect(file.filename, 'teste.${format.name}');
        expect(file.mimeType, format.mimeType);
      },
    );
  }

  test('preserva mensagem da API quando o período não tem registros', () async {
    final service = ReportExportService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': 'Nenhum registro encontrado no período informado',
          }),
          404,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
      baseUrl: () async => 'http://localhost:3000',
    );
    await expectLater(
      service.fetchReport(
        userId: 19,
        start: start,
        end: end,
        format: ReportFormat.pdf,
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 404)
            .having((e) => e.message, 'mensagem', contains('período')),
      ),
    );
  });

  test('não trata JSON ou arquivo corrompido como um PDF válido', () async {
    final service = ReportExportService(
      client: MockClient(
        (_) async => http.Response(
          '{}',
          200,
          headers: {'content-type': 'application/pdf'},
        ),
      ),
      baseUrl: () async => 'http://localhost:3000',
    );
    await expectLater(
      service.fetchReport(
        userId: 19,
        start: start,
        end: end,
        format: ReportFormat.pdf,
      ),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 502)),
    );
  });

  test(
    'exporta um dia e ignora caminhos recebidos no nome do arquivo',
    () async {
      final service = ReportExportService(
        client: MockClient((request) async {
          expect(
            request.url.queryParameters['dataInicio'],
            request.url.queryParameters['dataFim'],
          );
          return http.Response(
            '%PDF-',
            200,
            headers: {
              'content-type': 'application/pdf',
              'content-disposition': 'attachment; filename="../relatorio.pdf"',
            },
          );
        }),
        baseUrl: () async => 'http://localhost:3000',
      );
      final file = await service.fetchReport(
        userId: 19,
        start: end,
        end: end,
        format: ReportFormat.pdf,
      );
      expect(file.filename, 'relatorio-insulog-19-2026-08-31-2026-08-31.pdf');
    },
  );
}
