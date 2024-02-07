import 'package:flutter/material.dart';
import 'task.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String _baseURL = 'https://nesoleb.000webhostapp.com';

class ToDoList extends StatefulWidget {
  @override
  _ToDoListState createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  List<Task> tasks = [];
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  DateTime? dueTime;
  Future<void> addTask() async {
    if (dueTime == null) {
      return;
    }

    Task newTask = Task(
      id: 0,
      title: titleController.text,
      description: descriptionController.text,
      dueTime: dueTime!,
    );

    final response = await http.post(
      Uri.parse('$_baseURL/add_task.php'),
      body: {
        'title': newTask.title,
        'description': newTask.description,
        'due_time': newTask.dueTime.toIso8601String(),
      },
    );

    if (response.statusCode == 200) {
      newTask.id = int.parse(response.body);
      print('Task added successfully. ID: ${newTask.id}');
      setState(() {
        tasks.add(newTask);
      });
      titleController.clear();
      descriptionController.clear();
      setState(() {
        dueTime = null;
      });
    } else {
      print('Failed to add task. Response code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  Future<void> fetchTasks() async {
    final response = await http.get(Uri.parse('$_baseURL/get_tasks.php'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      setState(() {
        tasks = data
            .map((task) => Task(
                  id: int.parse(task['id']),
                  title: task['title'],
                  description: task['description'],
                  dueTime: DateTime.parse(task['due_time']),
                  isDone: task['is_done'] == '1',
                ))
            .toList();
      });
    }
  }

  Future<void> deleteTask(int index) async {
    final response = await http.post(
      Uri.parse('$_baseURL/delete_task.php'),
      body: {
        'id': tasks[index].id.toString(),
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        tasks.removeAt(index);
      });
    }
  }

  Future<void> markTaskAsDone(int index) async {
    final Task task = tasks[index];

    if (!task.isDone) {
      // If the task is not done, mark it as done
      final response = await http.post(
        Uri.parse('$_baseURL/mark_task_as_done.php'),
        body: {
          'id': task.id.toString(),
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          task.isDone = true;
        });
        setState(() {
          tasks.removeAt(index);
        });
      } else {
        print(
            'Failed to mark task as done. Response code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    }
  }

  Future<void> _selectDueTime() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          dueTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToDo App '),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(8.0),
            elevation: 4.0,
            child: ListTile(
              contentPadding: EdgeInsets.all(16.0),
              title: Text(
                tasks[index].title,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  decoration:
                      tasks[index].isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tasks[index].description,
                    style: TextStyle(fontSize: 16.0),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Due: ${DateFormat('yyyy-MM-dd h:mm a').format(tasks[index].dueTime.toLocal())}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
              trailing: Checkbox(
                value: tasks[index].isDone,
                onChanged: (value) {
                  if (value != null && value) {
                    deleteTask(index);
                  } else {
                    markTaskAsDone(index);
                  }
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Add Task'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: 'Title'),
                    ),
                    SizedBox(height: 8.0),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                    SizedBox(height: 18.0),
                    Row(
                      children: [
                        Text('Due Time:'),
                        if (dueTime != null) SizedBox(width: 8.0),
                        if (dueTime != null)
                          Text(
                            '${DateFormat('yyyy-MM-dd HH:mm').format(dueTime!)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: _selectDueTime,
                          child: Text('Select a Time'),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      addTask();
                      Navigator.pop(context);
                    },
                    child: Text('ADD'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
