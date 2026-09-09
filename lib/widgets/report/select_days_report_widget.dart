import 'package:flutter/material.dart';
import 'package:insulog/states/report_state.dart';

class SelectDaysReportWidget extends StatelessWidget {
  final ReportState state;
  final Size size;

  const SelectDaysReportWidget({
    super.key,
    required this.state,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final List<ReportDay> selectedMonthDays = state.selectedMonthDays;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        spacing: size.width * 0.03,
        children: selectedMonthDays.map((reportDay) {
          final bool isSelected =
              (reportDay.day == state.selectedDay) ||
              (state.selectedDay == 0);
          return GestureDetector(
            onTap: () {
              state.setDay(reportDay.day);
            },
            child: Container(
              width: size.width * 0.2,
              height: size.height * 0.08,
              margin: EdgeInsets.only(
                top: size.height * 0.02,
                bottom: size.height * 0.02,
                left: size.width * (reportDay.day == 1 ? 0.05 : 0),
                right:
                    size.width *
                    (reportDay.day == reportDay.totalDays ? 0.05 : 0),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: size.width * 0.2,
                    height: size.height * 0.04,
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF3EA75F) : Colors.grey,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        reportDay.shortWeekday,
                        style: TextStyle(
                          fontSize: size.width * 0.045,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: size.width * 0.2,
                    height: size.height * 0.04,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        reportDay.day.toString(),
                        style: TextStyle(
                          fontSize: size.width * 0.05,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
