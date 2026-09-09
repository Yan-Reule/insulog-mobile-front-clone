import 'package:flutter/material.dart';
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
          // onPressed:  ,
          text: "Exportar",
          isFontBold: true,
          icon: Icons.add,
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
