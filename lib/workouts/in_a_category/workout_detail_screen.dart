import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // ez kell az időzítéshez
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  _WorkoutDetailScreenState createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  bool isFavorite = false;
  double? userRating;
  double averageRating = 0.0;
  bool isGuest = false;
  List<dynamic> steps = []; // <-- a globális steps lista
  List<bool> _checkedSteps = []; // <-- a pipálási állapotok

  @override
  void initState() {
    super.initState();
    _checkIfGuest();
    _checkIfFavorite();
    _fetchRatings();
  }

  void _checkIfGuest() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) {
      setState(() {
        isGuest = true;
      });
    }
  }

  Future<Map<String, dynamic>?> getWorkoutData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('workouts')
        .doc(widget.workoutId)
        .get();
    return doc.data() as Map<String, dynamic>?;
  }

  Future<void> _checkIfFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      List<dynamic> favoriteWorkouts =
          (userDoc.data() as Map<String, dynamic>?)?['favorites'] ?? [];

      setState(() {
        isFavorite = favoriteWorkouts.contains(widget.workoutId);
      });
    }
  }

  Future<void> _fetchRatings() async {
    DocumentSnapshot workoutDoc = await FirebaseFirestore.instance
        .collection('workouts')
        .doc(widget.workoutId)
        .get();

    Map<String, dynamic> ratings =
        (workoutDoc.data() as Map<String, dynamic>?)?['ratings'] ?? {};

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && ratings.containsKey(user.uid)) {
      setState(() {
        userRating = (ratings[user.uid] as num).toDouble();
      });
    }

    if (ratings.isNotEmpty) {
      double totalRating =
          ratings.values.fold(0.0, (sum, value) => sum + (value as num));
      setState(() {
        averageRating = totalRating / ratings.length;
      });
    } else {
      setState(() {
        averageRating = 0.0;
      });
    }
  }

  Future<void> _updateRating(double rating) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    DocumentReference workoutRef =
        FirebaseFirestore.instance.collection('workouts').doc(widget.workoutId);

    DocumentSnapshot workoutDoc = await workoutRef.get();
    Map<String, dynamic> ratings =
        (workoutDoc.data() as Map<String, dynamic>?)?['ratings'] ?? {};

    ratings[user.uid] = rating;

    double totalRating =
        ratings.values.fold(0.0, (sum, value) => sum + (value as num));
    double newAverageRating = totalRating / ratings.length;

    await workoutRef.update({
      'ratings': ratings,
      'averageRating': newAverageRating,
    });

    setState(() {
      userRating = rating;
      averageRating = newAverageRating;
    });
  }

  Future<void> _toggleFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      DocumentSnapshot userDoc = await userRef.get();
      List<dynamic> favoriteWorkouts =
          (userDoc.data() as Map<String, dynamic>?)?['favorites'] ?? [];

      if (favoriteWorkouts.contains(widget.workoutId)) {
        await userRef.update({
          'favorites': FieldValue.arrayRemove([widget.workoutId])
        });
        setState(() {
          isFavorite = false;
        });
      } else {
        await userRef.update({
          'favorites': FieldValue.arrayUnion([widget.workoutId])
        });
        setState(() {
          isFavorite = true;
        });
      }
    }
  }

  Future<void> _markWorkoutCompleted() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      await userRef.update({
        'completedWorkouts': FieldValue.increment(1),
      });
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Completion'),
          content: const Text(
              'Are you sure you want to mark this workout as completed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _markWorkoutCompleted();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _showRatingDialog() {
    double? selectedRating = userRating;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final surfaceColor = theme.dialogBackgroundColor;
        final buttonColor = isDark ? Colors.grey.shade700 : Colors.blueAccent;

        return Dialog(
          backgroundColor: surfaceColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Rate this Workout',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// Vendég felhasználó esetén
                    if (isGuest) ...[
                      Text(
                        'Average Rating: ${averageRating.toStringAsFixed(1)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'To rate this workout, please create an account.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.75),
                        ),
                      ),
                    ]

                    /// Bejelentkezett felhasználónak
                    else ...[
                      Text(
                        'Select your rating:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<double>(
                        value: selectedRating,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        dropdownColor: surfaceColor,
                        style: theme.textTheme.bodyLarge,
                        items: [1, 2, 3, 4, 5]
                            .map((value) => DropdownMenuItem<double>(
                                  value: value.toDouble(),
                                  child: Text('$value'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => selectedRating = value);
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Average Rating: ${averageRating.toStringAsFixed(1)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.85),
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.secondary,
                          ),
                          child: const Text('Close'),
                        ),
                        if (!isGuest) ...[
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: selectedRating != null
                                ? () {
                                    Navigator.of(context).pop();
                                    _updateRating(selectedRating!);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Submit'),
                          ),
                        ]
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : Colors.blueAccent;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.thumb_up_alt_outlined),
            tooltip: 'Rate Workout',
            onPressed: _showRatingDialog,
          ),
        ],
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : null,
        flexibleSpace: !isDark
            ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.tealAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              )
            : null,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getWorkoutData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading workout data'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No workout found'));
          }

          Map<String, dynamic> workoutData = snapshot.data!;
          String title = workoutData['title'] ?? 'No Title';
          String description = workoutData['description'] ?? 'No Description';
          steps = workoutData['steps'] ?? [];
          if (_checkedSteps.length != steps.length) {
            _checkedSteps = List<bool>.filled(steps.length, false);
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      if (!isGuest)
                        GestureDetector(
                          onTap: _toggleFavorite,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: isFavorite
                                  ? (isDark
                                      ? Colors.grey.shade700.withOpacity(0.4)
                                      : Colors.yellow.shade100)
                                  : (isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200),
                              shape: BoxShape.circle,
                              boxShadow: [],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isFavorite ? Icons.star : Icons.star_border,
                              color: isFavorite
                                  ? (isDark
                                      ? Colors.orange.shade300
                                      : Colors.orange)
                                  : (isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey),
                              size: 30,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Steps:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StepsList(
                    steps: steps,
                    workoutId: widget.workoutId,
                    isDark: isDark,
                    primaryColor: primaryColor,
                    textColor: textColor,
                  ),
                  RestTimerWidget(isDark: isDark),
                  const SizedBox(height: 20),
                  if (!isGuest)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _showConfirmationDialog,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Mark as Completed',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? Colors.grey.shade700 : Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RestTimerWidget extends StatefulWidget {
  final bool isDark;

  const RestTimerWidget({super.key, required this.isDark});

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  int _selectedMinutes = 1;
  Duration _remainingTime = const Duration(minutes: 1);
  Timer? _timer;
  bool _isRunning = false;
  late String _prefsStartKey;
  late String _prefsMinutesKey;
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  void initState() {
    super.initState();
    _prefsStartKey = 'restTimer_start';
    _prefsMinutesKey = 'restTimer_minutes';
    _initializeNotifications();
    _loadTimerState();
  }

  Future<void> _requestPermissions() async {
    // Értesítési jogosultság kérése
    final status = await Permission.notification.status;
    debugPrint('Notification permission status: $status');
    if (status.isDenied) {
      final result = await Permission.notification.request();
      debugPrint('Notification permission request result: $result');
    }
  }

  void _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android inicializálási beállítások
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS inicializálási beállítások
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Kombinált inicializálási beállítások
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Plugin inicializálása előtérben történő kezeléssel
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Értesítés megérintve: ${response.payload}');
      },
    );

    // Android értesítési csatorna létrehozása
    const channel = AndroidNotificationChannel(
      'rest_timer_channel',
      'Rest Timer Notifications',
      description: 'Értesítések a pihenőidő időzítő befejezéséhez',
      importance: Importance.max,
      playSound: true,
      showBadge: true,
      enableVibration: true,
    );

    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    debugPrint('Notification channel created');

    // Jogosultságok kérése
    await _requestPermissions();
  }

  Future<void> _showNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'rest_timer_channel',
      'Rest Timer Notifications',
      channelDescription: 'Notifications for rest timer completion',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Rest Timer',
      showWhen: true,
      autoCancel: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        0,
        'Rest Timer Finished',
        'Your rest period is over!',
        notificationDetails,
        payload: 'timer_complete',
      );
      debugPrint('Notification sent successfully');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _saveTimerState(DateTime startTime, int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsStartKey, startTime.toIso8601String());
    await prefs.setInt(_prefsMinutesKey, minutes);
  }

  Future<void> _clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsStartKey);
    await prefs.remove(_prefsMinutesKey);
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final startString = prefs.getString(_prefsStartKey);
    final minutes = prefs.getInt(_prefsMinutesKey);

    if (startString != null && minutes != null) {
      final startTime = DateTime.parse(startString);
      final elapsed = DateTime.now().difference(startTime);
      final total = Duration(minutes: minutes);
      final remaining = total - elapsed;

      if (remaining > Duration.zero) {
        setState(() {
          _selectedMinutes = minutes;
          _remainingTime = remaining;
          _isRunning = true;
        });
        _startTimer(resume: true);
      } else {
        await _clearTimerState();
        _resetTimer();
      }
    }
  }

  void _startTimer({bool resume = false}) {
    _timer?.cancel();

    if (!resume) {
      _saveTimerState(DateTime.now(), _selectedMinutes);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime -= const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
        setState(() {
          _isRunning = false;
        });
        await _clearTimerState();
        await _showNotification(); // Trigger notification when timer expires
      }
    });

    setState(() {
      _isRunning = true;
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingTime = Duration(minutes: _selectedMinutes);
      _isRunning = false;
    });
    _clearTimerState();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isDark ? Colors.white : Colors.blueAccent;
    final textColor = widget.isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        const SizedBox(height: 30),
        Text(
          'Rest Timer',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.grey.shade900 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  widget.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            boxShadow: !widget.isDark
                ? [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(
                _formatDuration(_remainingTime),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<int>(
                    value: _selectedMinutes,
                    dropdownColor:
                        widget.isDark ? Colors.grey.shade800 : Colors.white,
                    style: TextStyle(color: textColor),
                    items: [1, 2, 3, 4, 5]
                        .map((minute) => DropdownMenuItem(
                              value: minute,
                              child: Text('$minute min'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (!_isRunning && value != null) {
                        setState(() {
                          _selectedMinutes = value;
                          _remainingTime = Duration(minutes: value);
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRunning
                          ? Colors.redAccent
                          : (widget.isDark ? Colors.grey : Colors.blueAccent),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_isRunning ? 'Pause' : 'Start'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _resetTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StepsList extends StatefulWidget {
  final List<dynamic> steps;
  final String workoutId;
  final bool isDark;
  final Color primaryColor;
  final Color textColor;

  const StepsList({
    super.key,
    required this.steps,
    required this.workoutId,
    required this.isDark,
    required this.primaryColor,
    required this.textColor,
  });

  @override
  State<StepsList> createState() => _StepsListState();
}

class _StepsListState extends State<StepsList> {
  List<bool> _checkedSteps = [];

  @override
  void initState() {
    super.initState();
    _loadCheckedSteps();
  }

  Future<void> _loadCheckedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? saved =
        prefs.getStringList('checkedSteps_${widget.workoutId}');
    setState(() {
      if (saved != null) {
        _checkedSteps = saved.map((e) => e == 'true').toList();
      } else {
        _checkedSteps = List<bool>.filled(widget.steps.length, false);
      }
    });
  }

  Future<void> _saveCheckedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'checkedSteps_${widget.workoutId}',
      _checkedSteps.map((e) => e.toString()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        widget.steps.length,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.grey.shade900 : Colors.grey.shade100,
            border: Border.all(
              color:
                  widget.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Checkbox(
                value:
                    _checkedSteps.length > index ? _checkedSteps[index] : false,
                onChanged: (value) {
                  setState(() {
                    _checkedSteps[index] = value ?? false;
                  });
                  _saveCheckedSteps();
                },
                fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (_checkedSteps.length > index && _checkedSteps[index]) {
                    return widget.isDark ? Colors.grey : Colors.blueAccent;
                  }
                  return widget.isDark ? Colors.white : Colors.grey.shade400;
                }),
              ),
              Expanded(
                child: Text(
                  '${index + 1}. ${widget.steps[index]}',
                  style: TextStyle(
                    fontSize: 15.5,
                    color: widget.textColor,
                    decoration:
                        _checkedSteps.length > index && _checkedSteps[index]
                            ? TextDecoration.lineThrough
                            : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
