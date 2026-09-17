import 'package:flutter/material.dart';
import 'package:insulog/services/api/api_service.dart';
import 'package:insulog/services/api/report_export_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:insulog/states/report_state.dart';
import 'package:insulog/widgets/custom_button_widget.dart';
import 'package:insulog/widgets/main_body_widget.dart';
import 'package:insulog/widgets/report/report_body_widget.dart';
import 'package:insulog/widgets/report/report_header_widget.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final ReportState reportState = ReportState();
  bool _isExporting = false;

  Future<void> _exportReport() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final format = await showModalBottomSheet<ReportFormat>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Exportar relatório',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${ReportExportService.formatDate(reportState.exportStart)} a ${ReportExportService.formatDate(reportState.exportEnd)}',
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('PDF'),
                onTap: () => Navigator.pop(sheetContext, ReportFormat.pdf),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('Planilha Excel (.xlsx)'),
                onTap: () => Navigator.pop(sheetContext, ReportFormat.xlsx),
              ),
            ],
          ),
        ),
      );
      if (format == null || !mounted) return;
      final file = await reportState.exportReport(format);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: 'Relatório Insulog',
          files: [XFile.fromData(file.bytes, mimeType: file.mimeType)],
          fileNameOverrides: [file.filename],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível compartilhar o relatório. Tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    reportState.addListener(handleNotify);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reportState.openReport();
    });
  }

  void handleNotify() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    reportState.removeListener(handleNotify);
    reportState.leaveReport();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      floatingActionButton: SizedBox(
        width: size.width * 0.4,
        height: size.height * 0.08,
        child: CustomButtonWidget(
          onPressed: _isExporting ? null : _exportReport,
          isLoading: _isExporting,
          text: "Exportar",
          isFontBold: true,
          icon: Icons.file_download_outlined,
          textColor: Color.fromARGB(255, 255, 255, 255),
          onpressTextColor: Color.fromARGB(255, 255, 255, 255),
          bgColor: Color(0xFF3EA75F),
          onpressBgColor: Color.fromARGB(255, 31, 88, 49),
          borderRadius: BorderRadius.all(Radius.circular(20)),
          boxShadow: BoxShadow(
            color: Color.fromARGB(80, 0, 0, 0),
            blurRadius: 2,
            offset: Offset(0, 2),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: MainBody(
        children: Column(
          children: [
            ReportHeaderWidget(size: size, state: reportState),

            Expanded(
              child: ReportBodyWidget(size: size, reportState: reportState),
            ),
          ],
        ),
      ),
    );
  }
}
