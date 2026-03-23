import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/task_service.dart';

enum OtpPageMode { generate, verify }

class TaskOtpPage extends StatefulWidget {
  final int? assignmentId;
  final int? taskId;
  final OtpPageMode mode;
  final String otpType; // 'START' or 'END'
  final String taskTitle;
  final bool isDocument;
  final int? obtainedScore;
  final int? penalty;

  const TaskOtpPage({
    super.key,
    this.assignmentId,
    this.taskId,
    required this.mode,
    required this.otpType,
    required this.taskTitle,
    this.isDocument = false,
    this.obtainedScore,
    this.penalty,
  });

  @override
  State<TaskOtpPage> createState() => _TaskOtpPageState();
}

class _TaskOtpPageState extends State<TaskOtpPage> {
  // Styles
  final Color _kIndigo = const Color(0xFF6366F1);
  final Color _kSlate = const Color(0xFF1E293B);
  final Color _kBg = const Color(0xFFF8FAFC);
  final Color _kBorder = const Color(0xFFE2E8F0);

  // State
  String? _currentOtp;
  int _secondsLeft = 20;
  Timer? _timer;
  bool _isLoading = false;
  String _enteredCode = "";
  bool _showManualEntry = false; // Default to scanner for students
  bool _isCoolingDown = false;
  int _cooldownLeft = 0;
  bool _isSuccess = false;
  final MobileScannerController _scannerController = MobileScannerController();
  
  // Proof Logic
  String? _selectedFilePath;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    if (widget.mode == OtpPageMode.generate) {
      _fetchNewOtp();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _fetchNewOtp() async {
    setState(() {
      _isLoading = true;
      _currentOtp = null; // Prevent scanning an old QR code while refreshing
    });
    try {
      // Uses taskId for generating OTP
      if (widget.taskId == null) {
        throw Exception("Task ID is missing for generation");
      }
      final res = await TaskService().generateOTP(
        widget.taskId!,
        widget.otpType,
      );
      setState(() {
        _currentOtp = (res['otp_code'] ?? res['otp'])?.toString();
        _secondsLeft = 20;
        _isCoolingDown = false;
        _isLoading = false;
      });
      _startCountdown();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _isCoolingDown = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCoolingDown) {
        if (_cooldownLeft > 0) {
          setState(() => _cooldownLeft--);
        } else {
          _timer?.cancel();
          setState(() => _isCoolingDown = false);
          _fetchNewOtp();
        }
      } else {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          setState(() {
            _isCoolingDown = true;
            _cooldownLeft = 10;
            _currentOtp = null; // hide OTP during cooldown
          });
        }
      }
    });
  }

  Future<void> _handleVerify(String code) async {
    if (_isLoading || _isSuccess) return;
    if (code.length != 6) return;

    setState(() => _isLoading = true);
    try {
      if (widget.assignmentId == null) throw Exception("Assignment ID missing");
      await TaskService().verifyOTP(
        widget.assignmentId!, 
        code,
        filePath: _selectedFilePath,
        obtainedScore: widget.obtainedScore,
        penalty: widget.penalty,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Verification failed: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        // Wait exactly 2 seconds before unlocking the camera from a failed scan.
        // This stops rapid-fire scanning of the exact same code before the user can react!
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isSuccess) {
            _scannerController.start();
          }
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              "Activity ${widget.otpType == 'START' ? 'Started' : 'Ended'}",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Successfully verified OTP for ${widget.taskTitle}.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Return success to detail page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "DONE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _kSlate, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.mode == OtpPageMode.generate ? "GENERATE OTP" : "VERIFY OTP",
          style: GoogleFonts.plusJakartaSans(
            color: _kSlate,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: widget.mode == OtpPageMode.verify && !_showManualEntry
          ? _buildFullscreenScanner()
          : _isLoading && _currentOtp == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (widget.mode == OtpPageMode.verify && widget.otpType == 'END' && widget.isDocument)
                    _buildProofPicker(),
                  const SizedBox(height: 24),
                  widget.mode == OtpPageMode.generate
                      ? _buildGeneratorView()
                      : _buildManualEntryView(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kIndigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              widget.otpType == 'START'
                  ? Icons.play_circle_outline_rounded
                  : Icons.stop_circle_outlined,
              color: _kIndigo,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otpType == 'START'
                      ? "Attendance Verification"
                      : "Completion Verification",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.taskTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kSlate,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorView() {
    return Column(
      children: [
        // QR Code
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: QrImageView(
            data: _currentOtp ?? "",
            version: QrVersions.auto,
            size: 240.0,
            eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: _kSlate),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: _kIndigo,
            ),
          ),
        ),
        const SizedBox(height: 40),
        // 6-Digit Code
        Text(
          "MANUAL CODE",
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: (_currentOtp ?? "000000").split('').map((char) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 40,
              height: 56,
              decoration: BoxDecoration(
                color: _kSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Center(
                child: Text(
                  char,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _kIndigo,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 48),
        // Countdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _isCoolingDown
                ? Colors.orange.shade50
                : (_secondsLeft < 5
                      ? Colors.red.shade50
                      : _kIndigo.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isCoolingDown
                    ? Icons.hourglass_top_rounded
                    : Icons.timer_outlined,
                size: 16,
                color: _isCoolingDown
                    ? Colors.orange
                    : (_secondsLeft < 5 ? Colors.red : _kIndigo),
              ),
              const SizedBox(width: 8),
              Text(
                _isCoolingDown
                    ? "Next OTP in $_cooldownLeft seconds"
                    : "Expires in $_secondsLeft seconds",
                style: TextStyle(
                  color: _isCoolingDown
                      ? Colors.orange
                      : (_secondsLeft < 5 ? Colors.red : _kIndigo),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: _isCoolingDown ? null : _fetchNewOtp,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text("Refresh Code Now"),
          style: TextButton.styleFrom(foregroundColor: _kSlate),
        ),
      ],
    );
  }

  Widget _buildFullscreenScanner() {
    return Stack(
      children: [
        // 1. Camera View
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                // Regex to find 6 consecutive digits
                final match = RegExp(r'(\d{6})').firstMatch(barcode.rawValue!);
                if (match != null) {
                  final code = match.group(1)!;
                  debugPrint("Scanned Code: $code");
                  _scannerController.stop();
                  _handleVerify(code);
                  break; // Process only the first valid code per frame
                }
              }
            }
          },
        ),

        // 2. Custom Overlay matching the image
        _buildScannerOverlay(),

        // 3. Close Button (Optional if you want to allow exit from scanner but keep page)
        Positioned(
          top: 20,
          left: 20,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The Scanning Frame
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Corner Brackets
              _buildCorner(0, 0), // Top-Left
              _buildCorner(0, 1), // Top-Right
              _buildCorner(1, 0), // Bottom-Left
              _buildCorner(1, 1), // Bottom-Right
              // Scanning Line
              _buildScanningLine(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Position QR code within the frame to scan',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                shadows: [const Shadow(blurRadius: 10, color: Colors.black45)],
              ),
            ),
          ),
          const SizedBox(height: 60),

          // USE OTP BUTTON (Pill shape with border)
          GestureDetector(
            onTap: () {
              setState(() {
                _showManualEntry = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 2),
                color: Colors.black26,
              ),
              child: Text(
                'Use OTP',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(int y, int x) {
    return Positioned(
      top: y == 0 ? -2 : null,
      bottom: y == 1 ? -2 : null,
      left: x == 0 ? -2 : null,
      right: x == 1 ? -2 : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: y == 0
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            bottom: y == 1
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            left: x == 0
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            right: x == 1
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildScanningLine() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Positioned(
          top: 260 * value,
          child: Container(
            width: 240,
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: _kIndigo.withOpacity(0.8),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  _kIndigo.withOpacity(0),
                  _kIndigo,
                  _kIndigo.withOpacity(0),
                ],
              ),
            ),
          ),
        );
      },
      onEnd: () {
        // Handled by TweenAnimationBuilder
      },
    );
  }

  Widget _buildManualEntryView() {
    return Column(
      children: [
        const Text(
          'ENTER 6-DIGIT CODE MANUALLY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 30),
        _buildSixDigitGrid(),
        const SizedBox(height: 60),
        _buildKeyboard(),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _isLoading || _enteredCode.length < 6
              ? null
              : () => _handleVerify(_enteredCode),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kIndigo,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            shadowColor: _kIndigo.withOpacity(0.4),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'VERIFY & PROCEED',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => setState(() {
            _showManualEntry = false;
            _enteredCode = "";
          }),
          child: Text(
            'Back to Scanner',
            style: TextStyle(color: _kIndigo, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSixDigitGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        String digit = "";
        if (_enteredCode.length > index) {
          digit = _enteredCode[index];
        }
        bool isActive = _enteredCode.length == index;

        return Container(
          width: 48,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? _kIndigo
                  : (digit.isNotEmpty ? _kSlate : _kBorder),
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _kIndigo.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              digit,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _kSlate,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeyboard() {
    return Column(
      children: [
        _buildKeyboardRow(["1", "2", "3"]),
        const SizedBox(height: 16),
        _buildKeyboardRow(["4", "5", "6"]),
        const SizedBox(height: 16),
        _buildKeyboardRow(["7", "8", "9"]),
        const SizedBox(height: 16),
        _buildKeyboardRow([null, "0", Icons.backspace_rounded]),
      ],
    );
  }

  Widget _buildKeyboardRow(List<dynamic> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key == null) return const SizedBox(width: 72);
        return _buildKey(key);
      }).toList(),
    );
  }

  Widget _buildKey(dynamic content) {
    bool isIcon = content is IconData;
    return InkWell(
      onTap: () {
        if (isIcon) {
          if (_enteredCode.isNotEmpty) {
            setState(() {
              _enteredCode = _enteredCode.substring(0, _enteredCode.length - 1);
            });
          }
        } else {
          if (_enteredCode.length < 6) {
            setState(() {
              _enteredCode += content.toString();
            });
            if (_enteredCode.length == 6) {
              // Optional: auto-verify
            }
          }
        }
      },
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isIcon ? Colors.transparent : Colors.white,
          border: isIcon ? null : Border.all(color: _kBorder, width: 1),
        ),
        alignment: Alignment.center,
        child: isIcon
            ? Icon(content, color: _kSlate, size: 24)
            : Text(
                content,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: _kSlate,
                ),
              ),
      ),
    );
  }

  static const Color _kSubtle = Color(0xFFF1F5F9);

  Widget _buildProofPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "DOCUMENTATION REQUIRED",
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickProofFile,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedFilePath != null ? _kIndigo : _kBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (_selectedFilePath != null ? _kIndigo : Colors.grey).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _selectedFilePath != null ? Icons.description_rounded : Icons.add_a_photo_rounded,
                    color: _selectedFilePath != null ? _kIndigo : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFileName ?? "Pick Proof Document/Image",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedFilePath != null ? _kSlate : Colors.grey,
                        ),
                      ),
                      if (_selectedFilePath == null)
                        const Text(
                          "Required to complete this task",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                if (_selectedFilePath != null)
                  const Icon(Icons.check_circle_rounded, color: Colors.green),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickProofFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint("File picker error: $e");
    }
  }
}
