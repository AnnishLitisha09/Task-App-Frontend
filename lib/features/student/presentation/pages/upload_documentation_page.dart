import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';

class UploadDocumentationPage extends StatefulWidget {
  const UploadDocumentationPage({super.key});

  @override
  State<UploadDocumentationPage> createState() => _UploadDocumentationPageState();
}

class _UploadDocumentationPageState extends State<UploadDocumentationPage> {
  String? _selectedFileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Documents"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Please ensure all documents are clear and legible. PDF or JPG formats only.",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Upload Area
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFileName = "medical_certificate.pdf"; // Simulating selection
                });
              },
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    width: 2,
                    style: BorderStyle.none // Dashed border workaround needs CustomPainter, skipping for now
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedFileName != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                        size: 64,
                        color: _selectedFileName != null ? Colors.green : Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFileName ?? "Tap to Select File",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      if (_selectedFileName == null)
                        Text(
                          "Max size: 5MB",
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            const Text("Remarks", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Add any additional details here...",
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 48),

            CustomButton(
              text: "Submit Document",
              onPressed: () {
                 if (_selectedFileName != null) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text("Document Submitted Successfully!"))
                   );
                   Navigator.pop(context);
                 }
              },
              backgroundColor: _selectedFileName != null ? Theme.of(context).primaryColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
