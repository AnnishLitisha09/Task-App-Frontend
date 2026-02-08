import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskViewPage extends StatelessWidget {
  final Map<String, dynamic> taskData;

  const TaskViewPage({super.key, required this.taskData});

  final Color accent = const Color(0xFF6366F1);
  final Color bgSlate = const Color(0xFFF8FAFC);
  final Color textDark = const Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSlate,
      appBar: AppBar(
        title: const Text(
          "Directive Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. DYNAMIC STATUS BANNER
            _buildStatusBanner(),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 32),

                  // 2. PROOF & METHODS SECTION
                  _sectionHeader("Execution Proof"),
                  _buildProofGrid(),
                  const SizedBox(height: 32),

                  // 3. ASSIGNEES SECTION
                  _sectionHeader("Assignees"),
                  _buildAssigneeList(),
                  const SizedBox(height: 32),

                  // 4. UPDATED DUAL-APPROVAL GOVERNANCE
                  _sectionHeader("Governance & Approvals"),
                  _buildGovernanceCard(),

                  const SizedBox(height: 40),

                  // 5. ACTION BUTTON (Contextual)
                  _buildActionButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildStatusBanner() {
    // Determine overall status based on approvals
    bool isFullyApproved =
        (taskData['facultyApproval'] == 'Approved' &&
        taskData['venueInchargeApproval'] == 'Approved');

    return Container(
      width: double.infinity,
      color: isFullyApproved ? Colors.green.shade50 : Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: [
          Icon(
            isFullyApproved
                ? Icons.check_circle
                : Icons.pending_actions_rounded,
            color: isFullyApproved
                ? Colors.green.shade700
                : Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            isFullyApproved
                ? "STATUS: FULLY AUTHORIZED"
                : "STATUS: PENDING AUTHORIZATION",
            style: TextStyle(
              color: isFullyApproved
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          taskData['title'] ?? "Untitled Directive",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _priorityBadge(taskData['priority']),
            const SizedBox(width: 12),
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              "Due ${DateFormat('MMM dd, yyyy').format(taskData['selectedDate'] ?? DateTime.now())}",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProofGrid() {
    final List methods = taskData['completionMethods'] ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: methods.isEmpty
            ? [const Text("No proof methods required")]
            : methods
                  .map<Widget>(
                    (m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: accent.withOpacity(0.1),
                            child: Icon(
                              Icons.verified_rounded,
                              color: accent,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            m.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textDark,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            "MANDATORY",
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
      ),
    );
  }

  Widget _buildAssigneeList() {
    // Mocking a list of assignee objects.
    // In a real app, this would come from taskData['assignees']
    final List assignees =
        taskData['assignees'] ??
        [
          {'name': 'Alex Rivera', 'role': 'Lead'},
          {'name': 'Sarah Chen', 'role': 'Member'},
          {'name': 'James Wilson', 'role': 'Member'},
        ];

    return SizedBox(
      height: 64, // Slightly taller to accommodate two lines of text
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: assignees.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final person = assignees[index];
          return Container(
            padding: const EdgeInsets.only(right: 16, left: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accent.withOpacity(0.1),
                  child: Text(
                    person['name']![0], // Shows first letter of name
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person['name']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textDark,
                      ),
                    ),
                    Text(
                      person['role']!.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGovernanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigo.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. ASSIGNED FACULTY
          _approvalRow(
            role: "Assigned Faculty",
            name: taskData['facultyName'] ?? "Dr. Robert Fox",
            status: taskData['facultyApproval'] ?? "Pending",
            icon: Icons.school_rounded,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.grey.shade100, thickness: 1),
          ),

          // 2. VENUE INCHARGE
          _approvalRow(
            role: "Venue Incharge",
            name: taskData['inchargeName'] ?? "Mr. Albert Flores",
            status: taskData['venueInchargeApproval'] ?? "Approved",
            icon: Icons.meeting_room_rounded,
          ),
        ],
      ),
    );
  }

  Widget _approvalRow({
    required String role,
    required String name,
    required String status,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgSlate,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textDark,
                ),
              ),
            ],
          ),
        ),
        _buildStatusChip(status),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'approved':
        chipColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        break;
      case 'rejected':
        chipColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        break;
      default: // Pending
        chipColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFF854D0E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          "EXECUTE DIRECTIVE",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: Colors.blueGrey.shade400,
        ),
      ),
    );
  }

  Widget _priorityBadge(String? priority) {
    Color color = priority == 'Critical' ? Colors.red : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority ?? "Medium",
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
