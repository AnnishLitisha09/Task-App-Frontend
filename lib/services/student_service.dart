import '../models/student_model.dart';

class StudentService {
  // --- Mock Data Generator ---
  // Since we don't have the real API yet, we'll return mock data delay
  Future<List<StudentSummary>> getFacultyStudents() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    // Return mock list
    return List.generate(
      10,
      (index) => StudentSummary(
        id: index + 1,
        name: "Student ${index + 1}",
        email: "student${index + 1}@college.edu",
        registerNumber: "REG2024${(index + 1).toString().padLeft(3, '0')}",
        totalScore: (index * 15.5) + 50,
        totalPenalty: (index * 2.0),
        department: "CSE",
        avatarUrl:
            "https://ui-avatars.com/api/?name=Student+${index + 1}&background=random",
      ),
    );
  }

  Future<StudentDetail> getStudentDetails(int studentId) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    // Mock detail
    return StudentDetail(
      id: studentId,
      name: "Student $studentId",
      email: "student$studentId@college.edu",
      registerNumber: "REG2024${studentId.toString().padLeft(3, '0')}",
      totalScore: 85.5,
      totalPenalty: 12.0,
      department: "CSE",
      avatarUrl:
          "https://ui-avatars.com/api/?name=Student+$studentId&background=random",
      activeTasks: [],
      completedTasks: [],
    );
  }
}
