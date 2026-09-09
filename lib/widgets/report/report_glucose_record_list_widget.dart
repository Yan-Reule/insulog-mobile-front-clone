import 'package:flutter/material.dart';
import 'package:insulog/DTO/ENUMs/enum_registroGlicose.dart';
import 'package:insulog/states/report_state.dart';

class ReportGlucoseRecordListWidget extends StatelessWidget {
  final Size size;
  final List<RegistroGlicose> records;
  final VoidCallback? onShowMore;
  final VoidCallback? onShowLess;
  final ReportState state;

  const ReportGlucoseRecordListWidget({
    super.key,
    required this.size,
    required this.records,
    required this.state,
    this.onShowMore,
    this.onShowLess,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...state
            .groupRecordsByWeek(records)
            .map(
              (week) => _ReportRecordWeekSection(
                size: size,
                week: week,
                state: state,
              ),
            ),
        if (onShowMore != null || onShowLess != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onShowLess != null)
                GestureDetector(
                  onTap: onShowLess,
                  child: Text(
                    'Ver menos',
                    style: TextStyle(
                      color: const Color(0xFF6B6B6B),
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF6B6B6B),
                    ),
                  ),
                ),
              if (onShowMore != null && onShowLess != null)
                SizedBox(width: size.width * 0.06),
              if (onShowMore != null)
                GestureDetector(
                  onTap: onShowMore,
                  child: Text(
                    'Mostrar mais',
                    style: TextStyle(
                      color: const Color(0xFF3EA75F),
                      fontSize: size.width * 0.055,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF3EA75F),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _ReportRecordWeekSection extends StatelessWidget {
  const _ReportRecordWeekSection({
    required this.size,
    required this.week,
    required this.state,
  });

  final Size size;
  final ReportRecordWeek week;
  final ReportState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: size.width * 0.05,
            right: size.width * 0.05,
            bottom: size.height * 0.0,
          ),
          child: Text(
            state.returnCurrentDateLabel(week),
            style: TextStyle(
              fontSize: size.width * 0.042,
              color: const Color.fromARGB(255, 78, 78, 78),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...week.days.map(
          (day) => _ReportRecordDaySection(size: size, day: day, state: state),
        ),
      ],
    );
  }
}

class _ReportRecordDaySection extends StatelessWidget {
  const _ReportRecordDaySection({
    required this.size,
    required this.day,
    required this.state,
  });

  final Size size;
  final ReportRecordDay day;
  final ReportState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: size.width * 0.05,
            right: size.width * 0.05,
            bottom: size.height * 0.0,
          ),
          child: Row(
            children: [
              Text(
                state.returnDayLabel(day),
                style: TextStyle(
                  fontSize: size.width * 0.04,
                  color: const Color.fromARGB(255, 100, 100, 100),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: size.width * 0.025),
              const Expanded(
                child: Divider(color: Color(0xFFC7C7C7), thickness: 1),
              ),
            ],
          ),
        ),
        ...day.records.map(
          (record) => Padding(
            padding: EdgeInsets.only(bottom: size.height * 0.022),
            child: _ReportGlucoseRecordCard(
              size: size,
              record: record,
              state: state,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportGlucoseRecordCard extends StatefulWidget {
  final Size size;
  final RegistroGlicose record;
  final ReportState state;

  const _ReportGlucoseRecordCard({
    required this.size,
    required this.record,
    required this.state,
  });

  @override
  State<_ReportGlucoseRecordCard> createState() =>
      _ReportGlucoseRecordCardState();
}

class _ReportGlucoseRecordCardState extends State<_ReportGlucoseRecordCard> {
  bool isPressed = false;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(handleStateChange);
  }

  void handleStateChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(handleStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.size.width * 0.045,
          vertical: widget.size.height * 0.022,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(widget.size.width * 0.05),
          border: Border(
            bottom: BorderSide(
              color: Color(widget.record.colorStatus),
              width: 4,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(255, 104, 104, 104),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: widget.size.width * 0.045,
              height: widget.size.width * 0.045,
              decoration: BoxDecoration(
                color: Color(widget.record.colorStatus),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: widget.size.width * 0.02),
            SizedBox(
              width: widget.size.width * 0.17,
              child: Text(
                widget.record.horaFormatada,
                style: TextStyle(
                  fontSize: widget.size.width * 0.05,
                  color: const Color(0xFF4C4C4C),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${widget.record.nivelGlicose}',
                      style: TextStyle(
                        fontSize: widget.size.width * 0.07,
                        color: const Color(0xFF171717),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: ' mg/dL',
                      style: TextStyle(
                        fontSize: widget.size.width * 0.05,
                        color: const Color(0xFF4C4C4C),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: widget.size.width * 0.02),
            Text(
              widget.record.periodo,
              style: TextStyle(
                fontSize: widget.size.width * 0.05,
                color: const Color(0xFF7C7C7C),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
