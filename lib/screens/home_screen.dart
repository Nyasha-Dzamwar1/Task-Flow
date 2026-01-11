import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mapd/screens/add_edit_task_screen.dart';
import 'package:mapd/screens/login_screen.dart';
import 'package:mapd/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/app_repository.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AppRepository _appRepository;

  String activeFilter = 'All';
  String activePriorityFilter = 'All'; // New priority filter
  String userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    // Initialize app repository from provider
    _appRepository = Provider.of<AppRepository>(context, listen: false);
  }

  /// Loads the user's name from Firebase Auth
  /// Falls back to email username or 'User' if display name is not available
  void _loadUserName() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
      });
    }
  }

  /// Returns a stream of tasks filtered based on active category and priority filters
  Stream<List<Task>> get filteredTasksStream {
    return _getBaseTaskStream().map((tasks) => _applyPriorityFilter(tasks));
  }

  /// Returns the base stream based on active category filter
  Stream<List<Task>> _getBaseTaskStream() {
    switch (activeFilter) {
      case 'Completed':
        return _appRepository.getCompletedTasks();
      case 'Work':
      case 'School':
      case 'Personal':
        return _appRepository.getTasksByCategory(activeFilter);
      default:
        return _appRepository.getUserTasks();
    }
  }

  /// Applies priority filter to the task list
  List<Task> _applyPriorityFilter(List<Task> tasks) {
    // First filter by priority if not 'All'
    List<Task> filteredTasks = tasks;
    if (activePriorityFilter != 'All') {
      filteredTasks = tasks
          .where((task) => task.priority == activePriorityFilter)
          .toList();
    }

    // Then sort by priority (High > Medium > Low) and other criteria
    return _sortTasksByPriority(filteredTasks);
  }

  /// Sorts tasks by priority (High > Medium > Low) and then by creation date
  List<Task> _sortTasksByPriority(List<Task> tasks) {
    final priorityOrder = {'High': 3, 'Medium': 2, 'Low': 1};

    tasks.sort((a, b) {
      // First, sort by priority (descending)
      final priorityA = priorityOrder[a.priority] ?? 0;
      final priorityB = priorityOrder[b.priority] ?? 0;
      final priorityComparison = priorityB.compareTo(priorityA);
      if (priorityComparison != 0) {
        return priorityComparison;
      }

      // If same priority, sort by completion status (incomplete first)
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }

      // If same completion status, sort by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });

    return tasks;
  }

  /// Toggles task completion status and shows feedback snackbar
  void toggleTaskComplete(String taskId, bool currentStatus) async {
    try {
      await _appRepository.toggleTaskComplete(taskId, currentStatus);
      _showSuccessSnackBar('Task updated successfully');
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  /// Shows a confirmation dialog before deleting a task
  void showDeleteConfirmationDialog(String taskId, String taskTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          _buildDeleteConfirmationDialog(taskId, taskTitle),
    );
  }

  /// Deletes a task and shows feedback snackbar
  void deleteTask(String taskId) async {
    try {
      await _appRepository.deleteTask(taskId);
      _showSuccessSnackBar('Task deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  /// Navigates to edit task screen with existing task data
  void editTask(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditTaskScreen(task: task)),
    );
  }

  /// Navigates to add new task screen
  void addNewTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditTaskScreen()),
    );
  }

  /// Handles user logout and navigates to login screen
  void logout() async {
    try {
      await _auth.signOut();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      _showErrorSnackBar('Error logging out: ${e.toString()}');
    }
  }

  // ========== UI COMPONENTS ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeaderSection(),
          _buildCategoryFilterChips(), // Category filters
          _buildPriorityFilterChips(), // Priority filters (NEW)
          _buildTaskList(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Builds the header section with user info and stats
  Widget _buildHeaderSection() {
    return Container(
      decoration: _headerDecoration(),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoRow(),
              SizedBox(height: 20),
              _buildStatsCards(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds user info row with app title, greeting, and avatar
  Widget _buildUserInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TaskFlow',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Hello $userName 👋',
              style: TextStyle(fontSize: 14, color: Color(0xFFDBEAFE)),
            ),
          ],
        ),
        Row(
          children: [
            _buildLogoutButton(),
            SizedBox(width: 8),
            _buildUserAvatar(),
          ],
        ),
      ],
    );
  }

  /// Builds logout button
  Widget _buildLogoutButton() {
    return IconButton(
      onPressed: logout,
      icon: Icon(Icons.logout),
      color: Colors.white,
      iconSize: 24,
      tooltip: 'Logout',
    );
  }

  /// Builds user avatar with initial
  Widget _buildUserAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          userName[0].toUpperCase(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF14B8A6),
          ),
        ),
      ),
    );
  }

  /// Builds stats cards showing pending and completed task counts
  Widget _buildStatsCards() {
    return StreamBuilder<List<Task>>(
      stream: _appRepository.getUserTasks(),
      builder: (context, snapshot) {
        final (pendingCount, completedCount) = _calculateTaskCounts(snapshot);

        return Row(
          children: [
            _buildStatCard(pendingCount, 'Pending'),
            SizedBox(width: 12),
            _buildStatCard(completedCount, 'Completed'),
          ],
        );
      },
    );
  }

  /// Calculates pending and completed task counts from snapshot data
  (int, int) _calculateTaskCounts(AsyncSnapshot<List<Task>> snapshot) {
    int pendingCount = 0;
    int completedCount = 0;

    if (snapshot.hasData) {
      final tasks = snapshot.data!;
      pendingCount = tasks.where((t) => !t.completed).length;
      completedCount = tasks.where((t) => t.completed).length;
    }

    return (pendingCount, completedCount);
  }

  /// Builds individual stat card
  Widget _buildStatCard(int count, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Color(0xFFDBEAFE)),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds category filter chips row
  Widget _buildCategoryFilterChips() {
    return Container(
      height: 60,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        children: _buildCategoryFilterChipsList(),
      ),
    );
  }

  /// Creates list of category filter chip widgets
  List<Widget> _buildCategoryFilterChipsList() {
    return ['All', 'Work', 'School', 'Personal', 'Completed']
        .map(
          (filter) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: activeFilter == filter,
              onSelected: (selected) {
                setState(() {
                  activeFilter = filter;
                });
              },
              selectedColor: Color(0xFF14B8A6),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: activeFilter == filter
                    ? Colors.white
                    : Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              showCheckmark: false,
            ),
          ),
        )
        .toList();
  }

  /// Builds priority filter chips row (NEW)
  Widget _buildPriorityFilterChips() {
    return Container(
      height: 50,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        children: _buildPriorityFilterChipsList(),
      ),
    );
  }

  /// Creates list of priority filter chip widgets (NEW)
  List<Widget> _buildPriorityFilterChipsList() {
    return ['All', 'High', 'Medium', 'Low']
        .map(
          (priority) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(priority),
              selected: activePriorityFilter == priority,
              onSelected: (selected) {
                setState(() {
                  activePriorityFilter = priority;
                });
              },
              selectedColor: _getPriorityChipColor(priority),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: activePriorityFilter == priority
                    ? Colors.white
                    : getPriorityTextColor(priority),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              showCheckmark: false,
            ),
          ),
        )
        .toList();
  }

  /// Returns color for priority filter chips (NEW)
  Color _getPriorityChipColor(String priority) {
    switch (priority) {
      case 'High':
        return Color(0xFFEF4444);
      case 'Medium':
        return Color(0xFFF59E0B);
      case 'Low':
        return Color(0xFF10B981);
      default:
        return Color(0xFF14B8A6); // 'All' filter
    }
  }

  /// Builds the main task list
  Widget _buildTaskList() {
    return Expanded(
      child: StreamBuilder<List<Task>>(
        stream: filteredTasksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          return _buildTaskListView(snapshot.data!);
        },
      ),
    );
  }

  /// Builds loading indicator
  Widget _buildLoadingIndicator() {
    return Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6)));
  }

  /// Builds error state widget
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error loading tasks',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds empty state widget (UPDATED)
  Widget _buildEmptyState() {
    String message = 'No tasks yet';

    if (activeFilter != 'All' && activePriorityFilter != 'All') {
      message = 'No $activePriorityFilter priority $activeFilter tasks';
    } else if (activeFilter != 'All') {
      message = 'No $activeFilter tasks';
    } else if (activePriorityFilter != 'All') {
      message = 'No $activePriorityFilter priority tasks';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 64, color: Color(0xFFD1D5DB)),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to create one',
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  /// Builds list view of tasks
  Widget _buildTaskListView(List<Task> tasks) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _buildTaskItem(tasks[index]),
    );
  }

  /// Builds individual task item widget
  Widget _buildTaskItem(Task task) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Opacity(
        opacity: task.completed ? 0.6 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTaskCheckbox(task),
              SizedBox(width: 12),
              _buildTaskContent(task),
              _buildTaskActions(task),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds task checkbox
  Widget _buildTaskCheckbox(Task task) {
    return GestureDetector(
      onTap: () => toggleTaskComplete(task.id, task.completed),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: task.completed ? Color(0xFF14B8A6) : Colors.transparent,
          border: Border.all(
            color: task.completed ? Color(0xFF14B8A6) : Color(0xFFD1D5DB),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: task.completed
            ? Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }

  /// Builds task content (title, description, tags)
  Widget _buildTaskContent(Task task) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              decoration: task.completed ? TextDecoration.lineThrough : null,
            ),
          ),
          SizedBox(height: 4),
          Text(
            task.description,
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          SizedBox(height: 8),
          _buildTaskTags(task),
        ],
      ),
    );
  }

  /// Builds task tags (category and priority)
  Widget _buildTaskTags(Task task) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildCategoryTag(task.category),
        _buildPriorityTag(task.priority),
      ],
    );
  }

  /// Builds category tag
  Widget _buildCategoryTag(String category) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: getCategoryColor(category),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: getCategoryTextColor(category),
        ),
      ),
    );
  }

  /// Builds priority tag
  Widget _buildPriorityTag(String priority) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: getPriorityColor(priority),
        border: Border.all(color: getPriorityBorderColor(priority), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: getPriorityTextColor(priority),
        ),
      ),
    );
  }

  /// Builds task action buttons (edit and delete)
  Widget _buildTaskActions(Task task) {
    return Column(
      children: [
        IconButton(
          onPressed: () => editTask(task),
          icon: Icon(Icons.edit_outlined),
          color: Color(0xFF3B82F6),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
        ),
        SizedBox(height: 8),
        IconButton(
          onPressed: () => showDeleteConfirmationDialog(task.id, task.title),
          icon: Icon(Icons.delete_outline),
          color: Color(0xFFEF4444),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
        ),
      ],
    );
  }

  /// Builds floating action button for adding new tasks
  Widget _buildFloatingActionButton() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF14B8A6).withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: addNewTask,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }

  // ========== HELPER METHODS ==========

  /// Shows success snackbar with given message
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows error snackbar with given message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Builds delete confirmation dialog
  Widget _buildDeleteConfirmationDialog(String taskId, String taskTitle) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDeleteDialogIcon(),
            SizedBox(height: 20),
            Text(
              'Delete Task?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Are you sure you want to delete "$taskTitle"? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            _buildDeleteDialogButtons(taskId),
          ],
        ),
      ),
    );
  }

  /// Builds delete dialog icon
  Widget _buildDeleteDialogIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Color(0xFFFEE2E2),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.delete_outline, size: 32, color: Color(0xFFEF4444)),
    );
  }

  /// Builds delete dialog action buttons
  Widget _buildDeleteDialogButtons(String taskId) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              deleteTask(taskId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== DECORATION METHODS ==========

  /// Returns header decoration with gradient and shadow
  BoxDecoration _headerDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      boxShadow: [
        BoxShadow(
          color: Color(0xFF14B8A6).withOpacity(0.3),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  // ========== COLOR HELPER METHODS ==========

  /// Returns background color for category tags
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

  /// Returns text color for category tags
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

  /// Returns background color for priority tags
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

  /// Returns text color for priority tags
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

  /// Returns border color for priority tags
  Color getPriorityBorderColor(String priority) {
    switch (priority) {
      case 'High':
        return Color(0xFFFECACA);
      case 'Medium':
        return Color(0xFFFED7AA);
      case 'Low':
        return Color(0xFFBBF7D0);
      default:
        return Color(0xFFE5E7EB);
    }
  }
}
