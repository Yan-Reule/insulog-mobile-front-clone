import 'package:flutter/material.dart';
import 'package:insulog/DTO/ENUMs/enum_clock_register.dart';
import 'package:insulog/services/api/data_service.dart';
import 'package:insulog/states/clock_state.dart';
import 'package:insulog/widgets/app_notification.dart';

class ClockRecordListWidget extends StatelessWidget {
  final Size size;
  final List<EnumClockRegister> records;
  final ClockState state;
  final bool isLoading;
  final String? errorMessage;

  const ClockRecordListWidget({
    super.key,
    required this.size,
    required this.records,
    required this.state,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null && records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFD62828)),
        ),
      );
    }

    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('Nenhum alarme cadastrado.'),
      );
    }

    return Column(
      children: [
        ...records.map(
          (record) => Padding(
            padding: EdgeInsets.only(bottom: size.height * 0.022),
            child: _ClockRecordCard(size: size, record: record, state: state),
          ),
        ),
      ],
    );
  }
}

class _ClockRecordCard extends StatefulWidget {
  final Size size;
  final EnumClockRegister record;
  final ClockState state;

  const _ClockRecordCard({
    required this.size,
    required this.record,
    required this.state,
  });

  @override
  State<_ClockRecordCard> createState() => _ClockRecordCardState();
}

class _ClockRecordCardState extends State<_ClockRecordCard> {
  final List<String> diasSemana = [
    "SEG",
    "TER",
    "QUA",
    "QUI",
    "SEX",
    "SAB",
    "DOM",
  ];
  bool isPressed = false;

  List<String> get diasSemanaSelec => widget.record.diasSemana is String
      ? (widget.record.diasSemana as String)
            .split(',')
            .map((dia) => dia.trim())
            .toList()
      : (widget.record.diasSemana as List).cast<String>();

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
    final isSelected = widget.state.isRecordSelected(widget.record);
    final isUpdating = widget.state.isUpdatingAlarm(widget.record.idAlarme);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        widget.state.onLongPressRecord(widget.record, context, widget.size);
      },
      onTap: () {
        widget.state.onTapRecord(widget.record);
      },
      child: AnimatedScale(
        scale: isSelected ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.size.width * 0.045,
            vertical: widget.size.height * 0.01,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(widget.size.width * 0.05),
            border: Border(),
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
              // SizedBox(
              //   width: widget.size.width * 0.12,
              //   child: Icon(
              //     icone,
              //     color: const Color(0xFF3EA75F),
              //     size: widget.size.width * 0.09,
              //   ),
              // ),
              // SizedBox(width: widget.size.width * 0.02),
              Text(
                widget.state.formataHora(widget.record.dataHora),
                style: TextStyle(
                  fontSize: widget.size.width * 0.08,
                  color: const Color.fromARGB(255, 3, 3, 3),
                  // fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: widget.record.diasSemana.isNotEmpty
                    ? Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...diasSemana.asMap().entries.map((entry) {
                              final isSelected = diasSemanaSelec.contains(
                                entry.value,
                              );
                              final dia = entry.value == "SEG"
                                  ? "S"
                                  : entry.value == "TER"
                                  ? "T"
                                  : entry.value == "QUA"
                                  ? "Q"
                                  : entry.value == "QUI"
                                  ? "Q"
                                  : entry.value == "SEX"
                                  ? "S"
                                  : entry.value == "SAB"
                                  ? "S"
                                  : entry.value == "DOM"
                                  ? "D"
                                  : entry.value;

                              return Padding(
                                padding: EdgeInsets.only(
                                  right: widget.size.width * 0.01,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: widget.size.width * 0.02,
                                      height: widget.size.width * 0.02,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF3EA75F)
                                            : const Color.fromARGB(
                                                0,
                                                204,
                                                204,
                                                204,
                                              ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Text(
                                      dia,
                                      style: TextStyle(
                                        fontSize: widget.size.width * 0.04,
                                        color: isSelected
                                            ? const Color(0xFF3EA75F)
                                            : const Color.fromARGB(
                                                255,
                                                185,
                                                185,
                                                185,
                                              ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      )
                    : const Text(''),
              ),

              Switch(
                value: widget.record.ativo,
                activeColor: const Color(0xFF3EA75F),

                inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
                inactiveTrackColor: const Color.fromARGB(255, 192, 192, 192),

                trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((
                  states,
                ) {
                  if (!states.contains(WidgetState.selected)) {
                    return const Color.fromARGB(
                      0,
                      102,
                      95,
                      95,
                    ); // borda quando inativo
                  }

                  return const Color(0xFF3EA75F); // borda quando ativo
                }),

                onChanged: isUpdating
                    ? null
                    : (newValue) async {
                        try {
                          await widget.state.updateAlarmStatus(
                            widget.record,
                            newValue,
                          );
                        } on DataException catch (e) {
                          if (!context.mounted) {
                            return;
                          }

                          AppNotification.error(context, e.message);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
