import 'package:flutter/material.dart';
import 'package:insulog/states/report_state.dart';
import 'package:insulog/widgets/custom_button_widget.dart';

class SelectMonthReportWidget extends StatelessWidget {
  final ReportState reportState;
  final Size size;

  const SelectMonthReportWidget({
    super.key,
    required this.reportState,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SizedBox(
          width: size.width * 0.15,
          height: size.height * 0.07,
          child: CustomButtonWidget(
            onPressed: reportState.previousMonth,
            onTapDown: reportState.startPreviousMonthHold,
            onTapUp: reportState.stopMonthHold,
            onTapCancel: reportState.stopMonthHold,
            icon: Icons.arrow_left,
            iconSize: size.width * 0.12,
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
        SizedBox(
          width: size.width * 0.4,
          child: Column(
            children: [
              Text(
                '${reportState.selectedMonth}  ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 0,
                  fontSize: size.width * 0.075,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                ),
              ),
              Text(
                ' ${reportState.selectedYear}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 0,
                  fontSize: size.width * 0.065,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: size.width * 0.15,
          height: size.height * 0.07,
          child: CustomButtonWidget(
              iconSize: size.width * 0.12,
            onPressed: reportState.canGoToNextMonth
                ? reportState.nextMonth
                : null,
            onTapDown: reportState.canGoToNextMonth
                ? reportState.startNextMonthHold
                : null,
            onTapUp: reportState.stopMonthHold,
            onTapCancel: reportState.stopMonthHold,
            icon: Icons.arrow_right,
            bgColor: reportState.canGoToNextMonth
                ? const Color(0xFF3EA75F)
                : const Color.fromARGB(255, 160, 161, 160),
            onpressBgColor: Color.fromARGB(255, 31, 88, 49),
            borderRadius: BorderRadius.all(Radius.circular(20)),
            boxShadow: BoxShadow(
              color: Color.fromARGB(80, 0, 0, 0),
              blurRadius: 2,
              offset: Offset(0, 2),
            ),
          ),
        ),
      ],
    );
  }
}
