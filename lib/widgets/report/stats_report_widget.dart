import 'package:flutter/material.dart';

class StatsReportWidget extends StatelessWidget {
  final String title;
  final int value;
  final int tipe;
  final Size size;

  const StatsReportWidget({
    super.key,
    required this.title,
    required this.value,
    required this.tipe,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: size.width * 0.25,
        height: size.height * 0.12,
        decoration: BoxDecoration(
          border: Border.all(
            color: tipe == 1
                ? Colors.grey
                : tipe == 2
                ? Color(0xffD62828)
                : tipe == 3
                ? Colors.blue
                : tipe == 4
                ? Color(0xFFFFC81e)
                : Color(0xff3EA75F),
            width: 2.0,
          ),
          color: tipe == 1
              ? Colors.grey.withOpacity(0.1)
              : tipe == 2
              ? Color(0xffD62828).withOpacity(0.1)
              : tipe == 3
              ? Colors.blue.withOpacity(0.1)
              : tipe == 4
              ? Color(0xFFFFC81e).withOpacity(0.1)
              : Color(0xff3EA75F).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.0),
            Icon(
              color: tipe == 1
                  ? Colors.grey
                  : tipe == 2
                  ? Color(0xffD62828)
                  : tipe == 3
                  ? Colors.blue
                  : tipe == 4
                  ? Color(0xFFFFC81e)
                  : Color(0xff3EA75F),
              tipe == 1
                  ? Icons.bar_chart_sharp
                  : tipe == 2
                  ? Icons.arrow_upward
                  : tipe == 3
                  ? Icons.all_inbox
                  : tipe == 4
                  ? Icons.arrow_downward
                  : Icons.water_drop,
              size: size.width * 0.08,
            ),
            Text(
              value.toString(),
              style: TextStyle(
                height: 0,
                fontSize: size.width * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[800],
                height: 0,
                fontSize: size.width * 0.05,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
