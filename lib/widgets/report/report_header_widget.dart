import 'package:flutter/material.dart'; 
import 'package:insulog/states/report_state.dart';
import 'package:insulog/widgets/report/select_month_report_widget.dart';

class ReportHeaderWidget extends StatelessWidget {
  final Size size;
  final ReportState state;

  const ReportHeaderWidget({super.key, required this.size, required this.state});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3EA75F);
    const titleColor = Color(0xFF171717);
    const secondaryColor = Color(0xFF6B6B6B);

    return Container(
      height: size.height * 0.22,
      padding: EdgeInsets.fromLTRB(
        size.width * 0.06,
        size.height * 0.025,
        size.width * 0.06,
        size.height * 0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // SizedBox(width: size.width * 0.035),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: size.width * 0.15,
                      height: size.width * 0.15,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: primaryColor,
                        size: 27,
                      ),
                    ),
                    SizedBox(width: size.width * 0.03),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Relatório',
                          style: TextStyle(
                            fontSize: 28,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Relatório de registros',
                          style: TextStyle(
                            fontSize: size.width * 0.045,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container( 
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: primaryColor.withOpacity(0.6),
                  width: 2,
                ),
              ),
            ),
          ),
          SelectMonthReportWidget(reportState: state, size: size),
          SizedBox(height: size.height * 0.005),
        ],
      ),
    );
  }
}
