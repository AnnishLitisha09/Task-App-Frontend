import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class TaskClosurePage extends StatefulWidget {
  final Map<String, dynamic> taskData;
  const TaskClosurePage({super.key, required this.taskData});

  @override
  State<TaskClosurePage> createState() => _TaskClosurePageState();
}

class _TaskClosurePageState extends State<TaskClosurePage> {
  final Color _kSlate = const Color(0xFF0F172A);
  final Color brandAccent = const Color(0xFF6366F1);
  final Color _kIndigo = const Color(0xFF4F46E5);
  final Color _kBg = Colors.white;
  final Color _kSubtle = const Color(0xFFF8FAFC);
  final Color _kBorder = const Color(0xFFE2E8F0);

  int _activeStep = 1;
  late bool requiresOtp;
  late bool requiresProof;

  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  PlatformFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    String type =
        widget.taskData['closureType']?.toString().toLowerCase() ?? 'both';
    requiresOtp = type == 'otp' || type == 'both';
    requiresProof = type == 'proof' || type == 'both';
    if (!requiresProof) _activeStep = 2;
  }

  // --- Elegant Submission Modal ---
  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Success",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: _kBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Task Finalized",
                    style: _titleStyle().copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "The task has been successfully closed and recorded.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Back to task list
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandAccent,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "RETURN TO DASHBOARD",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleBack() {
    if (_activeStep == 2 && requiresProof) {
      setState(() => _activeStep = 1);
    } else {
      Navigator.pop(context);
    }
  }

  // ... (previous imports and variables remain the same)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: Column(
        // FIX: Force everything to start from the top
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressLine(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              // FIX: Ensure the switcher itself aligns its children to the top
              layoutBuilder:
                  (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[...previousChildren, ?currentChild],
                    );
                  },
              child: _activeStep == 1 ? _buildEvidenceView() : _buildOtpView(),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  // --- Step 1: Evidence (Top Aligned) ---
  Widget _buildEvidenceView() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      // Reduced top padding to 0 so it sits directly under the progress bar
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.start, // Force internal column to top
        children: [
          Text("Completion Proof", style: _titleStyle()),
          const SizedBox(height: 8),
          const Text(
            "Please attach a visual or document record of the completed work.",
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 32),
          _buildUploadAreaWithPreview(),
        ],
      ),
    );
  }

  // ... (Keep _buildUploadAreaWithPreview and other methods the same)
  Widget _buildUploadAreaWithPreview() {
    if (_pickedFile == null) {
      return GestureDetector(
        onTap: _pickFile,
        child: Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: _kSubtle,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBorder, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: _kIndigo,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                "Tap to select file",
                style: TextStyle(fontWeight: FontWeight.bold, color: _kSlate),
              ),
              const Text(
                "PDF, JPG or PNG",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    bool isImage = [
      'jpg',
      'jpeg',
      'png',
    ].contains(_pickedFile!.extension?.toLowerCase());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              height: 200,
              width: double.infinity,
              color: _kSubtle,
              child: isImage && _pickedFile!.path != null
                  ? Image.file(File(_pickedFile!.path!), fit: BoxFit.cover)
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 48,
                            color: _kIndigo,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ".${_pickedFile!.extension?.toUpperCase()}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _kIndigo,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pickedFile!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _pickFile,
                  child: Text(
                    "Change",
                    style: TextStyle(
                      color: _kIndigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: 6-Digit OTP ---
  Widget _buildOtpView() {
    return Padding(
      key: const ValueKey(2),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Verification", style: _titleStyle()),
          const SizedBox(height: 8),
          const Text(
            "Enter the 6-digit code provided to you.",
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 48),
          _buildSixDigitGrid(),
          const Spacer(),
          _buildNumpad(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProgressLine() {
    bool dual = requiresOtp && requiresProof;
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (!dual || _activeStep == 2) ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: _kIndigo,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildSixDigitGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        String val = _controllers[index].text;
        return Container(
          width: 45,
          height: 60,
          decoration: BoxDecoration(
            color: _kSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: val.isNotEmpty ? _kIndigo : _kBorder,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              val,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomButton() {
    bool ready = _activeStep == 2
        ? _controllers.every((c) => c.text.isNotEmpty)
        : (_pickedFile != null || !requiresProof);

    // Determine button label based on action type
    String buttonLabel;
    final actionType = widget.taskData['actionType']?.toString() ?? '';

    if (actionType == 'start') {
      // Starting activity
      buttonLabel = _activeStep == 2 || !requiresOtp
          ? "START TASK"
          : "CONTINUE";
    } else if (actionType == 'end') {
      // Ending activity
      buttonLabel = _activeStep == 2 || !requiresOtp
          ? "FINALIZE CLOSURE"
          : "CONTINUE";
    } else {
      // Default closure
      buttonLabel = _activeStep == 2 || !requiresOtp
          ? "FINALIZE CLOSURE"
          : "CONTINUE";
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
      child: ElevatedButton(
        onPressed: ready
            ? () {
                if (_activeStep == 1 && requiresOtp) {
                  setState(() => _activeStep = 2);
                } else {
                  if (actionType == 'start' || actionType == 'end') {
                    // Return true to indicate success
                    Navigator.pop(context, true);
                  } else {
                    _showSuccessDialog();
                  }
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandAccent,
          disabledBackgroundColor: _kBorder,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: Text(
          buttonLabel,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // Determine title based on action type
    final actionType = widget.taskData['actionType']?.toString() ?? '';
    String title = "TASK CLOSURE";

    if (actionType == 'start') {
      title = "START TASK";
    } else if (actionType == 'end') {
      title = "END TASK";
    }

    return AppBar(
      backgroundColor: _kBg,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: _kSlate, size: 18),
        onPressed: _handleBack,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  TextStyle _titleStyle() => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: _kSlate,
    letterSpacing: -0.8,
  );

  Widget _buildNumpad() {
    return Column(
      children: [
        for (var row in [
          ["1", "2", "3"],
          ["4", "5", "6"],
          ["7", "8", "9"],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((n) => _numpadBtn(n)).toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80),
            _numpadBtn("0"),
            IconButton(
              onPressed: _backspace,
              icon: const Icon(Icons.backspace_outlined, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _numpadBtn(String n) => TextButton(
    onPressed: () {
      for (var c in _controllers) {
        if (c.text.isEmpty) {
          setState(() => c.text = n);
          break;
        }
      }
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        n,
        style: TextStyle(
          fontSize: 26,
          color: _kSlate,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  void _backspace() {
    for (int i = _controllers.length - 1; i >= 0; i--) {
      if (_controllers[i].text.isNotEmpty) {
        setState(() => _controllers[i].clear());
        break;
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );
    if (result != null) setState(() => _pickedFile = result.files.first);
  }
}
