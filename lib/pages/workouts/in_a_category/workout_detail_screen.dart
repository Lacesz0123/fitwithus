import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:io';
import '/utils/timer_manager.dart';

/// Az edzés részleteit megjelenítő képernyő.
///
/// Megmutatja az edzés címét, leírását, lépéseit, videóját (ha van),
/// értékelési lehetőséget, valamint vendég és regisztrált felhasználókhoz igazodó funkciókat.
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
  List<dynamic> steps = [];
  List<bool> _checkedSteps = [];
  YoutubePlayerController? _videoController;
  bool hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkIfGuest();
    _checkIfFavorite();
    _fetchRatings();
    _checkInternet().then((value) {
      setState(() {
        hasInternet = value;
      });
      if (value) _initializeVideoController();
    });
  }

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Ellenőrzi, hogy a felhasználó vendégként van-e bejelentkezve.
  void _checkIfGuest() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) {
      setState(() {
        isGuest = true;
      });
    }
  }

  void _initializeVideoController() async {
    final workoutData = await getWorkoutData();
    final videoUrl = workoutData?['videoUrl'];
    if (videoUrl != null && videoUrl.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(videoUrl);
      if (videoId != null) {
        setState(() {
          _videoController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
            ),
          );
        });
      }
    }
  }

  /// Lekéri a workout dokumentumot a Firestore-ból.
  Future<Map<String, dynamic>?> getWorkoutData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('workouts')
        .doc(widget.workoutId)
        .get();
    return doc.data() as Map<String, dynamic>?;
  }

  /// Ellenőrzi, hogy az edzés szerepel-e a felhasználó kedvencei között.
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

  /// Értékelések lekérése a Firestore-ból: saját és átlagos érték kiszámítása.
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

  /// Új értékelés mentése az adatbázisba, és az átlag frissítése.
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

  /// Az edzés kedvencekhez adása vagy eltávolítása.
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

  /// Az edzés elvégzettként jelölése.
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

  /// Megjelenít egy megerősítő dialógust az edzés befejezéséhez.
  void _showConfirmationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cancelColor =
        isDark ? Theme.of(context).textTheme.bodyLarge?.color : Colors.black;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text('Confirm Completion'),
          content: const Text(
            'Are you sure you want to mark this workout as completed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: cancelColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _markWorkoutCompleted();
              },
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Értékelési dialógus megjelenítése, vendégek és bejelentkezettek számára.
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
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : null,
            gradient: !isDark
                ? const LinearGradient(
                    colors: [Colors.blueAccent, Colors.tealAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getWorkoutData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading workout data'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No workout found'));
          }

          Map<String, dynamic> workoutData = snapshot.data!;
          String title = workoutData['title'] ?? 'No Title';
          String? videoUrl = workoutData['videoUrl'];
          String description = workoutData['description'] ?? 'No Description';
          steps = workoutData['steps'] ?? [];
          if (_checkedSteps.length != steps.length) {
            _checkedSteps = List<bool>.filled(steps.length, false);
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ListView(
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
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            color: isFavorite
                                ? (isDark
                                    ? Colors.orange.shade300
                                    : Colors.orange)
                                : (isDark ? Colors.grey.shade400 : Colors.grey),
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
                if (hasInternet && videoUrl != null && videoUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Exercise Guide',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_videoController != null)
                    YoutubePlayerBuilder(
                      player: YoutubePlayer(
                        controller: _videoController!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: Colors.blueAccent,
                      ),
                      builder: (context, player) {
                        return player;
                      },
                    )
                  else
                    const CircularProgressIndicator(),
                ],
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
                if (!isGuest) RestTimerWidget(isDark: isDark),
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
          );
        },
      ),
    );
  }
}

/// A pihenőidőt kezelő widget, amely időzítőt jelenít meg és vezérel.
///
/// Lehetőség van idő kiválasztására, indításra, szüneteltetésre és nullázásra.
/// Az állapot megmarad újraindítás után is SharedPreferences és TimerManager segítségével.

class RestTimerWidget extends StatefulWidget {
  final bool isDark;

  const RestTimerWidget({super.key, required this.isDark});

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  final TimerManager _timerManager = TimerManager();

  @override
  void initState() {
    super.initState();
    _timerManager.setIsDark(widget.isDark);
    _timerManager.initializeNotifications();
    _timerManager.loadTimerState();
    _timerManager.onTimerUpdate = (remainingTime, isRunning) {
      if (mounted) {
        setState(() {});
      }
    };
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
                _formatDuration(_timerManager.getRemainingTime()),
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
                    value: _timerManager.getSelectedMinutes(),
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
                      if (value != null) {
                        _timerManager.setSelectedMinutes(value);
                        if (mounted) setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _timerManager.isRunning()
                        ? _timerManager.pauseTimer
                        : _timerManager.startTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _timerManager.isRunning()
                          ? Colors.redAccent
                          : (widget.isDark ? Colors.grey : Colors.blueAccent),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_timerManager.isRunning() ? 'Pause' : 'Start'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _timerManager.resetTimer,
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

/// Az edzés lépéseit megjelenítő lista, checkbox jelöléssel.
///
/// A felhasználó pipálhatja a végrehajtott lépéseket, a bejelölések helyileg elmentésre kerülnek.

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
