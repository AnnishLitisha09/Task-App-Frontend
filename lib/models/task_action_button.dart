class TaskActionButton {
  final String type;
  final String label;
  final String action;

  TaskActionButton({
    required this.type,
    required this.label,
    required this.action,
  });

  factory TaskActionButton.fromJson(Map<String, dynamic> json) {
    return TaskActionButton(
      type: json['type'] ?? '',
      label: json['label'] ?? '',
      action: json['action'] ?? '',
    );
  }
}
