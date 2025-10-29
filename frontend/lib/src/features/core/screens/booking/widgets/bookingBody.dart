import 'package:clubedaareia/src/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controllers/bookingController.dart';

class BookingBody extends StatefulWidget {
  final void Function(DateTime)? toggleCurrentDate;
  final Function(String, double)? toggleSlotSelection;
  final Function(double)? changeTotalPrice;
  final Function()? resetSelectedSlots;
  final List<String>? selectedSlots;
  final Map<String, dynamic>? courtData;

  //usado pra atualizar slots usados pro share
  final Function(List<String>)? onUpdateSlots;

  const BookingBody(
      {super.key,
      this.toggleCurrentDate,
      this.toggleSlotSelection,
      this.changeTotalPrice,
      this.selectedSlots,
      this.resetSelectedSlots,
      this.courtData,
      this.onUpdateSlots});

  @override
  _BookingBodyState createState() => _BookingBodyState();
}

class _BookingBodyState extends State<BookingBody> {
  //controllers
  final bookingController = Get.put(BookingController());
  //variables
  DateTime currentDate = DateTime.now();
  int startDayOffset = 0;
  int selectedDayIndex = 0;
  int selectedDayNumber = DateTime.now().day;
  late int idPlace;
  dynamic timeslotsData = [];
  //lista de grades por dia (0 - dom, 6 - sab)
  List<List<String>> daysTimeSlotsGrid = List.generate(7, (index) => []);
  List<List<String>> daysTimeSlotsVigencyInit = List.generate(7, (index) => []);
  List<List<String>> daysTimeSlotsVigencyEnd = List.generate(7, (index) => []);
  List<List<String>> daysTimeSlotsBooked = List.generate(7, (index) => []);
  List<List<String>> daysTimeSlotsBookedRepetition =
      List.generate(7, (index) => []);
  dynamic booked = [];
  dynamic blocked = [];
  List<List<dynamic>> daysTimeSlots = [];
  double totalPrice = 0;
  List<String> filteredSlots = [];
  List<String> freeSlots = [];
  int currentHour = DateTime.now().hour;
  String todayDate = DateTime.now().toString().substring(0, 10);

  @override
  void initState() {
    super.initState();
    int today = DateTime.now().weekday;

    setState(() {
      idPlace = widget.courtData?['courtId'];

      selectedDayIndex = (today % 7);
    });

    fetchTimeslots();
    fetchBlocked();
  }

  void generateBookedTimeSlots() {
    List<List<String>> daysBooked = List.generate(7, (index) => []);
    List<List<String>> daysBookedRepetition = List.generate(7, (index) => []);

    for (var agendamento in booked) {
      DateTime data = DateTime.parse(agendamento['data_agenda']);
      DateTime data_fim = DateTime.parse(agendamento['data_fim']);
      int dayOfWeek =
          data.weekday % 7; // Ajusta para o padrão 0 (domingo) - 6 (sábado)

      String horario = agendamento['horario'];
      String horarioFinal = agendamento['horario_final'];
      int repeticao = agendamento['repeticao'];

      // Formata a data como "YYYY-MM-DD"
      String formattedDate =
          "${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}";
      String formattedDateFinal =
          "${data_fim.year}-${data_fim.month.toString().padLeft(2, '0')}-${data_fim.day.toString().padLeft(2, '0')}";
      // Adiciona a data junto com o horário no array
      daysBooked[dayOfWeek].add(
          "$formattedDate: ${horario.substring(0, 5)} - ${horarioFinal.substring(0, 5)}");
      daysBookedRepetition[dayOfWeek].add(
          "${data.weekday}: ${formattedDateFinal} - ${horario.substring(0, 5)} - ${horarioFinal.substring(0, 5)} - ${repeticao.toString()}");
    }

    setState(() {
      daysTimeSlotsBooked = daysBooked;
      daysTimeSlotsBookedRepetition = daysBookedRepetition;
    });
  }

  void generateTimeSlots() {
    // Inicializar a lista de timeslots por dia da semana
    List<List<Map<String, dynamic>>> daysTimeSlots =
        List.generate(7, (index) => []);

    // Separar os horários por dia da semana
    for (var i = 0; i < timeslotsData.length; ++i) {
      int diaSemana = timeslotsData[i]['dia_semana'];

      // Verificar se o dia da semana é válido
      if (diaSemana >= 1 && diaSemana <= 7) {
        daysTimeSlots[diaSemana - 1].add(timeslotsData[i]);
      }
    }

    // Processar os horários de cada dia
    for (int dayIndex = 0; dayIndex < daysTimeSlots.length; dayIndex++) {
      List<Map<String, dynamic>> daySlots = daysTimeSlots[dayIndex];

      for (var slot in daySlots) {
        String startTime = slot['inicio'];
        String endTime = slot['final'];
        int intervalMinutes = slot['grade_minutos'];

        // Converter horários para DateTime
        DateTime start = DateTime.parse('2022-01-01 $startTime');
        DateTime end = DateTime.parse('2022-01-01 $endTime');

        // Criar intervalos de tempo
        while (start.isBefore(end)) {
          DateTime next = start.add(Duration(minutes: intervalMinutes));

          if (next.isAfter(end)) next = end;
          daysTimeSlotsGrid[dayIndex].add(
              '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${next.hour.toString().padLeft(2, '0')}:${next.minute.toString().padLeft(2, '0')}');
          daysTimeSlotsVigencyInit[dayIndex].add(slot['vigencia_inicio']);
          daysTimeSlotsVigencyEnd[dayIndex].add(slot['vigencia_final']);

          start = next;
        }
      }
    }
    //_filterSlots();
  }

  List<dynamic> weekDayData(List<dynamic> timeslotsData, int weekDay) {
    return timeslotsData
        .where((item) => item['dia_semana'] == weekDay)
        .toList();
  }

  Future<void> fetchTimeslots() async {
    final response = await bookingController.fetchTimeslots(idPlace);
    final responseBooked = await bookingController.fetchBooked(idPlace);
    setState(() {
      timeslotsData = response;
      booked = responseBooked;
    });

    generateBookedTimeSlots();
    generateTimeSlots();
  }

  String getWeekdayInPortuguese(DateTime date) {
    return DateFormat('EEE', 'pt_BR').format(date).toUpperCase();
  }

  String getMonthInPortuguese(DateTime date) {
    return DateFormat('MMMM', 'pt_BR').format(date).toUpperCase();
  }

  List<DateTime> getVisibleDays() {
    return List.generate(8,
        (index) => DateTime.now().add(Duration(days: startDayOffset + index)));
  }

  void shiftDays(bool forward) {
    freeSlots.clear();
    setState(() {
      if (forward) {
        // Shift days forward by 8 days
        startDayOffset += 8;
        currentDate = getVisibleDays().first;
        selectedDayIndex = currentDate.weekday % 7;
        widget.resetSelectedSlots!();
        widget.toggleCurrentDate!(currentDate);
        selectedDayNumber = currentDate.day;
      } else {
        // Check if shifting backward would show a past date
        DateTime newFirstDay =
            DateTime.now().add(Duration(days: startDayOffset - 8));
        if (!newFirstDay.isBefore(DateTime.now())) {
          startDayOffset -= 8;
          currentDate = getVisibleDays().first;
          selectedDayIndex = currentDate.weekday % 7;
          widget.resetSelectedSlots!();
          widget.toggleCurrentDate!(currentDate);
          selectedDayNumber = currentDate.day;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Não é possível selecionar datas anteriores à data atual.'),
            ),
          );
        }
      }
    });
  }

  void _filterSlots() {
    List<String> slots = daysTimeSlotsGrid[selectedDayIndex]
        .asMap()
        .entries
        .where((entry) {
          int index = entry.key;
          DateTime vigencyInit =
              DateTime.parse(daysTimeSlotsVigencyInit[selectedDayIndex][index]);
          DateTime vigencyEnd =
              DateTime.parse(daysTimeSlotsVigencyEnd[selectedDayIndex][index]);
          return currentDate.isAfter(vigencyInit) &&
              currentDate.isBefore(vigencyEnd);
        })
        .map((entry) => entry.value)
        .toList();

    setState(() {
      filteredSlots = slots;
    });
  }

  Future<void> fetchBlocked() async {
    final response = await bookingController.fetchBlocked(idPlace);
    setState(() {
      blocked = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleDays = getVisibleDays();

    return Container(
     
      
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              "${getMonthInPortuguese(currentDate)} ${currentDate.year}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Weekday row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_left, color: globalPrimaryColor),
                onPressed: () => shiftDays(false),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(8, (index) {
                    final day = visibleDays[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDayIndex = day.weekday % 7;
                          selectedDayNumber = day.day;
                          widget.resetSelectedSlots!();
      
                          currentDate = day;
                        });
                        widget.toggleCurrentDate!(day);
                        freeSlots.clear();
                      },
                      child: Column(
                        children: [
                          Text(getWeekdayInPortuguese(day)),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ((selectedDayNumber == (day.day)))
                                  ? globalPrimaryColor
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              DateFormat('d').format(day),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ((selectedDayNumber == (day.day)))
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right, color: globalPrimaryColor),
                onPressed: () => shiftDays(true),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Time slot list
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.70,
            child: ListView.builder(
              // Filtra os slots de acordo com o intervalo de vigência
              itemCount: daysTimeSlotsGrid[selectedDayIndex]
                  .asMap()
                  .entries
                  .where((entry) {
                int index = entry.key;
                DateTime vigencyInit = DateTime.parse(
                    daysTimeSlotsVigencyInit[selectedDayIndex][index]);
                DateTime vigencyEnd = DateTime.parse(
                    daysTimeSlotsVigencyEnd[selectedDayIndex][index]);
                return currentDate.isAfter(vigencyInit) &&
                    currentDate.isBefore(vigencyEnd);
              }).length,
              itemBuilder: (context, index) {
                // Slots filtrados
                List<String> filteredSlots = daysTimeSlotsGrid[selectedDayIndex]
                    .asMap()
                    .entries
                    .where((entry) {
                      int i = entry.key;
                      DateTime vigencyInit = DateTime.parse(
                          daysTimeSlotsVigencyInit[selectedDayIndex][i]);
                      DateTime vigencyEnd = DateTime.parse(
                          daysTimeSlotsVigencyEnd[selectedDayIndex][i]);
                      return currentDate.isAfter(vigencyInit) &&
                          currentDate.isBefore(vigencyEnd);
                    })
                    .map((entry) => entry.value)
                    .toList();
      
                String slot = filteredSlots[index];
                bool isBooked = false;
                bool isBlocked = false;
      
                //verifica se slot esta agendado
                if (daysTimeSlotsBooked[selectedDayIndex].isNotEmpty) {
                  for (var i = 0;
                      i < daysTimeSlotsBooked[selectedDayIndex].length;
                      ++i) {
                    if ((slot.toString() ==
                                daysTimeSlotsBooked[selectedDayIndex][i]
                                    .toString()
                                    .substring(12, 25) &&
                            currentDate.toString().substring(0, 10) ==
                                daysTimeSlotsBooked[selectedDayIndex][i]
                                    .toString()
                                    .substring(0, 10)) || //ou tem repetição
                        (daysTimeSlotsBookedRepetition[selectedDayIndex].isNotEmpty &&
                                slot.toString() ==
                                    daysTimeSlotsBookedRepetition[selectedDayIndex][i]
                                        .toString()
                                        .substring(16, 29) &&
                                int.parse(daysTimeSlotsBookedRepetition[selectedDayIndex][i].toString().substring(32, 33)) ==
                                    1 &&
                                currentDate.weekday ==
                                    int.parse(
                                        daysTimeSlotsBookedRepetition[selectedDayIndex][i]
                                            .toString()
                                            .substring(0, 1))) &&
                            currentDate.isBefore(DateTime.parse(daysTimeSlotsBookedRepetition[selectedDayIndex][i].toString().substring(3, 13)))
                            && currentDate.isAfter(DateTime.parse(daysTimeSlotsBooked[selectedDayIndex][i].toString().substring(0,10)))) {
                      isBooked = true;
                    }
                  }
                }
      
                //verifica se slot esta bloqueado
                for (var i = 0; i < blocked.length; ++i) {
                  if (currentDate.weekday == blocked[i]['dia_semana'] &&
                      currentDate
                          .isAfter(DateTime.parse(blocked[i]['data_inicio'])) &&
                      currentDate
                          .isBefore(DateTime.parse(blocked[i]['data_fim']))) {
                    if (int.parse(blocked[i]['inicio'].substring(0, 2)) <=
                            int.parse(slot.substring(0, 2)) &&
                        int.parse(blocked[i]['final'].substring(0, 2)) >=
                            int.parse(slot.substring(8, 10))) {
                      isBlocked = true;
                    }
                  }
                }
                //verifica se horário já passou
                if (int.parse(slot.substring(0, 2)) <= currentHour &&
                    todayDate == currentDate.toString().substring(0, 10)) {
                  isBlocked = true;
                }
      
                bool isSelected = widget.selectedSlots!.contains(slot);
      
                //salvo pro share
                if (!isBooked && !isBlocked) {
                  freeSlots.add(slot);
                }
      
                widget.onUpdateSlots!(freeSlots);
      
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    tileColor: isBooked
                        ? Colors.grey[300]
                        : isBlocked
                            ? Colors.red[100]
                            : isSelected
                                ? Colors.green[100]
                                : Colors.white,
                    leading: isSelected
                        ? const Icon(
                            Icons.check_sharp,
                            color: Colors.green,
                          )
                        : const Icon(
                            Icons.check_sharp,
                            color: Colors.transparent,
                          ),
                    title: Text(slot),
                    trailing: isBooked
                        ? const Text(
                            "AGENDADO",
                            style: TextStyle(color: Colors.grey),
                          )
                        : isBlocked
                            ? const Text(
                                "INDISPONÍVEL",
                                style: TextStyle(color: Colors.red),
                              )
                            : const Text(
                                "LIVRE",
                                style: TextStyle(color: Colors.green),
                              ),
                    onTap: isBooked || isBlocked
                        ? null
                        : () {
                            double slotPrice;
      
                            slotPrice = double.parse(weekDayData(
                                    timeslotsData, selectedDayIndex + 1)[0]
                                ['valor_hora']);
                            widget.toggleSlotSelection!(slot, slotPrice);
                          },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
