import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';

class PersonalCalendarPage extends StatelessWidget {
  const PersonalCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Schedule"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {}, // Go to today
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
                        _buildEventBlock(context, "Physics Lab", 9, 2, Colors.blue), // 9 AM - 11 AM
                        _buildEventBlock(context, "Lunch Break", 12, 1, Colors.green), // 12 PM - 1 PM
                        _buildEventBlock(context, "Project Meeting", 14, 1.5, Colors.orange), // 2 PM - 3:30 PM
                        
                        // Conflict Example
                        _buildEventBlock(context, "Library Duty", 14, 1, Colors.red, isConflict: true, offset: 50), 
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
        onPressed: () {},
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDaySelector(BuildContext context) {
    return Container(
      height: 80,
      color: Theme.of(context).cardColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          bool isSelected = index == 2; // Dummy selection
          return Container(
            width: 60,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Mon", 
                  style: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12
                  )
                ),
                Text(
                  "${12 + index}", 
                  style: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
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
      child: Text(
        "${hour.toString().padLeft(2, '0')}:00",
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEventBlock(BuildContext context, String title, double startHour, double durationHours, Color color, {bool isConflict = false, double offset = 0}) {
    return Positioned(
      top: startHour * 60,
      left: 10 + offset, // Slight padding
      right: isConflict ? 10 : 10, // Full width or partial
      height: durationHours * 60 - 2, // -2 for margin
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isConflict ? 0.7 : 0.2),
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
                color: isConflict ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isConflict)
             const Text(
               "CONFLICT!",
               style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
             ),
          ],
        ),
      ),
    );
  }
}
