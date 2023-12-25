class Task {
  int id;
  String title;
  String description;
  DateTime dueTime;
  bool isDone;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueTime,
    this.isDone = false,
  });
}
