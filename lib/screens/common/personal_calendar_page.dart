import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PersonalCalendarPage extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;

  const PersonalCalendarPage({super.key, this.tasks = const []});

  @override
  State<PersonalCalendarPage> createState() => _PersonalCalendarPageState();
}

class _PersonalCalendarPageState extends State<PersonalCalendarPage> {
  DateTime _selectedDate = DateTime.now();
  final double hourHeight = 85.0; // Slightly taller for a more premium feel
  final Color brandAccent = const Color(0xFF6366F1); // Indigo
  final Color slate500 = const Color(0xFF64748B);
  final Color surfaceColor = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    DateTime startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    List<DateTime> weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildLightDateHeader(weekDays),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: brandAccent.withOpacity(0.05), width: 1),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimeColumn(),
                      Expanded(
                        child: Stack(
                          children: [
                            _buildRefinedGrid(),
                            ...widget.tasks.map((task) => _buildLightEventCard(task)),
                            _buildModernTimeIndicator(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('MMMM yyyy').format(_selectedDate), 
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: brandAccent)),
          Text("${widget.tasks.length} events scheduled", 
            style: TextStyle(fontSize: 12, color: slate500.withOpacity(0.7), fontWeight: FontWeight.w500)),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => setState(() => _selectedDate = DateTime.now()),
          icon: Icon(Icons.today_outlined, color: brandAccent.withOpacity(0.8)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLightDateHeader(List<DateTime> weekDays) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekDays.map((date) {
          bool isSelected = DateUtils.isSameDay(date, _selectedDate);
          bool isToday = DateUtils.isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: 200.ms,
              width: 45,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? brandAccent.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected 
                    ? Border.all(color: brandAccent.withOpacity(0.2)) 
                    : (isToday ? Border.all(color: brandAccent.withOpacity(0.1)) : null),
              ),
              child: Column(
                children: [
                  Text(DateFormat('E').format(date).toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? brandAccent : slate500.withOpacity(0.5), 
                        fontSize: 10, 
                        fontWeight: FontWeight.w800
                      )),
                  const SizedBox(height: 6),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? brandAccent : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 16,
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

  Widget _buildLightEventCard(Map<String, dynamic> task) {
    double start = (task['start'] as num).toDouble();
    double duration = (task['dur'] as num).toDouble() / 60;
    Color taskColor = task['color'] ?? brandAccent;

    return Positioned(
      top: start * hourHeight + 4,
      left: 10,
      right: 12,
      height: (duration * hourHeight) - 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: taskColor.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: taskColor.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 4, 
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: taskColor,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
              ),
            ), 
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title'] ?? "Untitled Event",
                      style: TextStyle(
                        color: taskColor.withAlpha(220), 
                        fontWeight: FontWeight.w700, 
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (duration > 0.5) ...[
                      const SizedBox(height: 2),
                      Text(
                        task['sub'] ?? "",
                        style: TextStyle(
                          color: slate500.withOpacity(0.6), 
                          fontSize: 11, 
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().moveY(begin: 5, end: 0),
    );
  }

  Widget _buildTimeColumn() {
    return Container(
      width: 60,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: List.generate(24, (i) => Container(
          height: hourHeight,
          alignment: Alignment.topCenter,
          child: Text(
            "${i.toString().padLeft(2, '0')}:00",
            style: TextStyle(color: slate500.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w700),
          ),
        )),
      ),
    );
  }

  Widget _buildRefinedGrid() {
    return Column(
      children: List.generate(24, (index) => Container(
        height: hourHeight,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: brandAccent.withOpacity(0.03), width: 1)),
        ),
      )),
    );
  }

  Widget _buildModernTimeIndicator() {
    final now = DateTime.now();
    final double top = (now.hour + (now.minute / 60)) * hourHeight;
    return Positioned(
      top: top,
      left: 0, right: 0,
      child: Row(
        children: [
          Container(
            width: 6, height: 6, 
            decoration: BoxDecoration(color: brandAccent, shape: BoxShape.circle),
          ),
          Expanded(child: Container(height: 1, color: brandAccent.withOpacity(0.3))),
        ],
      ),
    );
  }
}