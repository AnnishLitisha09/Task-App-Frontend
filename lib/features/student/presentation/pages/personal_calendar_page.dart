import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';

class PersonalCalendarPage extends StatefulWidget {
  const PersonalCalendarPage({super.key});

  @override
  State<PersonalCalendarPage> createState() => _PersonalCalendarPageState();
}

class _PersonalCalendarPageState extends State<PersonalCalendarPage> {
  // Simple Event Model
  final List<Map<String, dynamic>> _events = [
    {"title": "Physics Lab", "start": 9.0, "duration": 2.0, "color": Colors.blue},
    {"title": "Lunch Break", "start": 12.0, "duration": 1.0, "color": Colors.green},
    {"title": "Project Meeting", "start": 14.0, "duration": 1.5, "color": Colors.orange},
  ];

  void _addEvent(String title, double start, double duration) {
    if (_hasConflict(start, duration)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Conflict detected! Cannot add event at this time."),
          backgroundColor: Colors.red,
        )
      );
      return;
    }

    setState(() {
      _events.add({
        "title": title,
        "start": start,
        "duration": duration,
        "color": Colors.purple
      });
    });
    Navigator.pop(context);
  }

  bool _hasConflict(double start, double duration) {
    double end = start + duration;
    for (var event in _events) {
      double eventStart = event["start"];
      double eventEnd = eventStart + event["duration"];

      if (start < eventEnd && end > eventStart) {
        return true; // Overlap
      }
    }
    return false;
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    double selectedStart = 8.0;
    double selectedDuration = 1.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("New Event", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Event Title", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  Text("Start Time: ${selectedStart.toInt()}:00", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: selectedStart,
                    min: 0,
                    max: 23,
                    divisions: 23,
                    label: "${selectedStart.toInt()}:00",
                    onChanged: (val) => setModalState(() => selectedStart = val),
                  ),
                  Text("Duration: ${selectedDuration.toStringAsFixed(1)} hrs", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: selectedDuration,
                    min: 0.5,
                    max: 4,
                    divisions: 7,
                    label: "${selectedDuration.toStringAsFixed(1)} hrs",
                    onChanged: (val) => setModalState(() => selectedDuration = val),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _addEvent(titleController.text, selectedStart, selectedDuration),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: const Text("Add Event", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Schedule"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black, // Dark text for white background
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {}, 
          )
        ],
      ),
      body: Column(
        children: [
          _buildDaySelector(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Column
                  SizedBox(
                    width: 60,
                    child: Column(
                      children: List.generate(24, (index) => _buildTimeSlot(context, index)),
                    ),
                  ),
                  // Events Column
                  Expanded(
                    child: Stack(
                      children: [
                        // Grid Lines
                        Column(
                           children: List.generate(24, (index) => Container(
                             height: 60, 
                             decoration: BoxDecoration(
                               border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))
                             ),
                           )),
                        ),
                        // Event Blocks
                        ..._events.map((e) => _buildEventBlock(
                          context, 
                          e["title"], 
                          e["start"], 
                          e["duration"], 
                          e["color"]
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDaySelector(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          bool isSelected = index == 2; // Dummy selection
          return Container(
            width: 60,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Mon", 
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 12
                  )
                ),
                Text(
                  "${12 + index}", 
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18
                  )
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlot(BuildContext context, int hour) {
    return SizedBox(
      height: 60,
      child: Center(
        child: Text(
          "${hour.toString().padLeft(2, '0')}:00",
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEventBlock(BuildContext context, String title, double startHour, double durationHours, Color color) {
    return Positioned(
      top: startHour * 60,
      left: 10, 
      right: 10,
      height: durationHours * 60 - 2, 
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          border: Border(left: BorderSide(color: color, width: 4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
               "${startHour.toInt()}:00 - ${(startHour + durationHours).toInt()}:00",
               style: const TextStyle(color: Colors.black54, fontSize: 10),
             ),
          ],
        ),
      ),
    );
  }
}

