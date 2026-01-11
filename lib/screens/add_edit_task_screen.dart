import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mapd/models/task.dart';
import 'package:mapd/screens/home_screen.dart';
import 'package:mapd/services/app_repository.dart';
import 'package:provider/provider.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;

  const AddEditTaskScreen({this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late AppRepository _appRepository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String _selectedCategory = 'Personal';
  String _selectedPriority = 'Medium';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _appRepository = Provider.of<AppRepository>(context, listen: false);
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedCategory = widget.task?.category ?? 'Personal';
    _selectedPriority = widget.task?.priority ?? 'Medium';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Task _createTaskFromForm() {
    return Task(
      id: widget.task?.id ?? '',
      title: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      priority: _selectedPriority,
      completed: widget.task?.completed ?? false,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      userId: _auth.currentUser?.uid ?? '',
    );
  }

  Color getCategoryColor(String category) {
    switch (category) {
      case 'School':
        return Color(0xFFF3E8FF);
      case 'Work':
        return Color(0xFFDBEAFE);
      case 'Personal':
        return Color(0xFFCCFBF1);
      default:
        return Color(0xFFF3F4F6);
    }
  }

  Color getCategoryTextColor(String category) {
    switch (category) {
      case 'School':
        return Color(0xFF7C3AED);
      case 'Work':
        return Color(0xFF2563EB);
      case 'Personal':
        return Color(0xFF0D9488);
      default:
        return Color(0xFF374151);
    }
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Color(0xFFFEE2E2);
      case 'Medium':
        return Color(0xFFFFEDD5);
      case 'Low':
        return Color(0xFFDCFCE7);
      default:
        return Color(0xFFF3F4F6);
    }
  }

  Color getPriorityTextColor(String priority) {
    switch (priority) {
      case 'High':
        return Color(0xFFDC2626);
      case 'Medium':
        return Color(0xFFEA580C);
      case 'Low':
        return Color(0xFF16A34A);
      default:
        return Color(0xFF374151);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Gradient Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF14B8A6).withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      widget.task == null ? 'Add New Task' : 'Edit Task',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    Text(
                      'Task Title',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter task title',
                          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                          prefixIcon: Icon(
                            Icons.title,
                            color: Color(0xFF14B8A6),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a task title';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 24),

                    // Description Field
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _descriptionController,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Enter task description',
                          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Icon(
                              Icons.description,
                              color: Color(0xFF14B8A6),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a task description';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 24),

                    // Category Selection
                    Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.category,
                            color: Color(0xFF14B8A6),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        items: ['Personal', 'Work', 'School']
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: getCategoryColor(category),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: getCategoryTextColor(category),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(category),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 24),

                    // Priority Selection
                    Text(
                      'Priority',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.flag,
                            color: Color(0xFF14B8A6),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        items: ['Low', 'Medium', 'High']
                            .map(
                              (priority) => DropdownMenuItem(
                                value: priority,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: getPriorityColor(priority),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        priority,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: getPriorityTextColor(priority),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPriority = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 40),

                    // Action Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF14B8A6).withOpacity(0.4),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                print(
                                  '=== DEBUG: Button pressed, starting process ===',
                                ); // Debug
                                if (_formKey.currentState!.validate()) {
                                  print(
                                    'DEBUG: Form validation passed',
                                  ); // Debug
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    print(
                                      'DEBUG: Loading set to true (spinner should show)',
                                    ); // Debug
                                  } else {
                                    print(
                                      'DEBUG: Widget not mounted - aborting',
                                    ); // Debug (unlikely)
                                    return;
                                  }
                                  try {
                                    print(
                                      'DEBUG: About to call repository (create or update)...',
                                    ); // Debug
                                    if (widget.task == null) {
                                      print(
                                        'DEBUG: Creating new task',
                                      ); // Debug
                                      final newTask = _createTaskFromForm();
                                      await _appRepository.createTask(newTask);
                                      print(
                                        'DEBUG: createTask succeeded! Task added to Firestore',
                                      ); // Debug
                                    } else {
                                      print(
                                        'DEBUG: Updating existing task',
                                      ); // Debug
                                      final updatedTask = _createTaskFromForm();
                                      await _appRepository.updateTask(
                                        widget.task!.id,
                                        updatedTask.toMap(),
                                      );
                                      print(
                                        'DEBUG: updateTask succeeded! Task updated in Firestore',
                                      ); // Debug
                                    }

                                    // Success path: Reset loading and show success message BEFORE navigation
                                    String message = widget.task == null
                                        ? 'Task created successfully!'
                                        : 'Task updated successfully!';
                                    print(
                                      'DEBUG: Preparing success message: $message',
                                    ); // Debug
                                    if (mounted) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      print(
                                        'DEBUG: Loading set to false (spinner should hide)',
                                      ); // Debug
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(message),
                                          backgroundColor: const Color(
                                            0xFF14B8A6,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                      print(
                                        'DEBUG: Success SnackBar shown on add screen',
                                      ); // Debug
                                    } else {
                                      print(
                                        'DEBUG: Not mounted for success handling - skipping UI updates',
                                      ); // Debug
                                    }

                                    // Navigate back to HomeScreen (data auto-refreshes via stream)
                                    print(
                                      'DEBUG: About to navigate...',
                                    ); // Debug
                                    if (mounted) {
                                      Navigator.pop(
                                        context,
                                      ); // Simple pop back to existing HomeScreen
                                      // Alternative (if you want a new HomeScreen instance):
                                      // Navigator.pushReplacement(
                                      //   context,
                                      //   MaterialPageRoute(builder: (_) => const HomeScreen()),
                                      // );
                                      print(
                                        'DEBUG: Navigation (pop) executed',
                                      ); // Debug
                                    } else {
                                      print(
                                        'DEBUG: Not mounted for navigation - manual back needed',
                                      ); // Debug
                                    }
                                  } catch (e) {
                                    print(
                                      'DEBUG: Error caught in try-catch: $e',
                                    ); // Debug - This is key!
                                    print(
                                      'DEBUG: Full error stack: ${StackTrace.current}',
                                    ); // Debug (more details)
                                    if (mounted) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      print(
                                        'DEBUG: Loading reset to false after error',
                                      ); // Debug
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: ${e.toString()}',
                                          ),
                                          backgroundColor: const Color(
                                            0xFFEF4444,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      print(
                                        'DEBUG: Error SnackBar shown',
                                      ); // Debug
                                    } else {
                                      print(
                                        'DEBUG: Not mounted for error handling',
                                      ); // Debug
                                    }
                                  }
                                  print(
                                    '=== DEBUG: onPressed process ended ===',
                                  ); // Debug
                                } else {
                                  print(
                                    'DEBUG: Form validation FAILED - check required fields',
                                  ); // Debug
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.task == null
                                        ? Icons.add
                                        : Icons.save,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    widget.task == null
                                        ? 'Add Task'
                                        : 'Save Changes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
