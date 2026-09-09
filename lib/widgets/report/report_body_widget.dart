import 'package:flutter/material.dart'; 
import 'package:insulog/states/report_state.dart';
import 'package:insulog/widgets/custom_container_widget.dart'; 
import 'package:insulog/widgets/report/report_glucose_record_list_widget.dart';
import 'package:insulog/widgets/report/select_days_report_widget.dart';
import 'package:insulog/widgets/report/stats_report_widget.dart';

class ReportBodyWidget extends StatelessWidget {
  final Size size;
  final ReportState reportState;

  const ReportBodyWidget({
    super.key,
    required this.size,
    required this.reportState,
  });

  @override
  Widget build(BuildContext context) {
    return CustomContainerWidget(
      width: size.width,
      innerShadow: const InnerShadow(
        color: Color.fromARGB(80, 0, 0, 0),
        blurRadius: 2,
        offset: Offset(0, 2),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size.width * 0.1),
          topRight: Radius.circular(size.width * 0.1),
        ),
      ),
      child: RefreshIndicator(
        onRefresh: reportState.refreshReportRecords,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              SelectDaysReportWidget(state: reportState, size: size),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                  child: Row(
                    spacing: size.width * 0.03,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      StatsReportWidget(
                        size: size,
                        tipe: 3,
                        title: "Média",
                        value: reportState.media,
                      ),
                      StatsReportWidget(
                        size: size,
                        tipe: 5,
                        title: "Normais",
                        value: reportState.totalNormais,
                      ),
                      StatsReportWidget(
                        size: size,
                        tipe: 2,
                        title: "Altos",
                        value: reportState.totalAlertas,
                      ),
                      StatsReportWidget(
                        size: size,
                        tipe: 4,
                        title: "Baixos",
                        value: reportState.totalBaixos,
                      ),
                      StatsReportWidget(
                        size: size,
                        tipe: 1,
                        title: "Registros",
                        value: reportState.totalRecords,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  size.width * 0.04,
                  size.height * 0.02,
                  size.width * 0.04,
                  size.height * 0.035,
                ),
                child: ReportGlucoseRecordListWidget(
                  size: size,
                  state: reportState,
                  records: reportState.visibleRecords,
                  onShowMore: reportState.canShowMoreRecords
                      ? reportState.showMoreRecords
                      : null,
                  onShowLess: reportState.canShowLessRecords
                      ? reportState.showLessRecords
                      : null,
                ),
              ), // Add your report content here
            ],
          ),
        ),
      ),
    );
  }
}
