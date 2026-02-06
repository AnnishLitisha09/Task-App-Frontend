import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../../../core/widgets/custom_button.dart';

class TaskExecutionPage extends StatefulWidget {
  const TaskExecutionPage({super.key});

  @override
  State<TaskExecutionPage> createState() => _TaskExecutionPageState();
}

class _TaskExecutionPageState extends State<TaskExecutionPage> {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _pauseTimer() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _stopTimer() {
     if (_timer != null) {
      _timer!.cancel();
    }
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Execution Mode"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Timer Display
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                         BoxShadow(
                          color: _isRunning && !_isPaused 
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.2) 
                            : Colors.transparent,
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                      border: Border.all(
                        color: _isRunning && !_isPaused 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey.withValues(alpha: 0.2),
                        width: 4
                      )
                    ),

                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined, 
                            size: 40, 
                            color: _isRunning && !_isPaused ? Theme.of(context).primaryColor : Colors.grey
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _formatTime(_secondsElapsed),
                            style: GoogleFonts.robotoMono( // Changed to robotoMono
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isPaused ? "PAUSED" : (_isRunning ? "RUNNING" : "READY"),
                            style: TextStyle(
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                              color: _isPaused ? Colors.orange : (_isRunning ? Colors.green : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(target: _isRunning && !_isPaused ? 1 : 0).shimmer(duration: 2.seconds), // Changed pulse to shimmer
                  
                  const SizedBox(height: 48),

                  // Location Check-in Placeholder
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text("Science Block, Room 302"),
                        const SizedBox(width: 12),
                        Icon(Icons.nfc, color: Theme.of(context).primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Controls
            if (!_isRunning && !_isPaused)
              CustomButton(
                text: "Start Task",
                onPressed: _startTimer,
                backgroundColor: Colors.green,
              )
            else ...[
               Row(
                 children: [
                   Expanded(
                     child: CustomButton(
                       text: _isPaused ? "Resume" : "Pause",
                       backgroundColor: _isPaused ? Colors.blue : Colors.orange,
                       onPressed: _isPaused ? _resumeTimer : _pauseTimer,
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 16),
               CustomButton(
                 text: "Complete Task",
                 backgroundColor: Theme.of(context).primaryColor,
                 onPressed: () {
                    _stopTimer();
                    // Show completion dialog or navigation
                    _showCompletionDialog();
                 },
               ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    bool isUploaded = false; // Local state for dialog
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("Complete Task"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("To complete this task, please upload a photo proof of your work."),
                  const SizedBox(height: 16),
                  
                  // Upload Area
                  GestureDetector(
                    onTap: () {
                      // Simulate upload delay
                      Future.delayed(const Duration(seconds: 1), () {
                        setDialogState(() {
                           isUploaded = true;
                        });
                      });
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      ),
                      child: isUploaded 
                        ? Stack(
                            children: [
                              Center(child: Icon(Icons.check_circle, color: Colors.green, size: 50)),
                              Positioned(bottom: 8, left: 0, right: 0, child: Text("Proof Attached", textAlign: TextAlign.center, style: TextStyle(color: Colors.green)))
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded, color: Colors.grey, size: 40),
                              SizedBox(height: 8),
                              Text("Tap to Attach Proof", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                    ),
                  ),
                  
                  if (isUploaded)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text("✅ Proof Verified: image_001.jpg", style: TextStyle(fontSize: 12, color: Colors.green)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                     Navigator.pop(context); // Close dialog to resume if needed
                  },
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isUploaded ? () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Back to Detail
                    Navigator.pop(context); // Back to Dashboard
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Task Submitted Successfully!"), backgroundColor: Colors.green)
                    );
                  } : null, // Disable if not uploaded
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Submit Final"),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
