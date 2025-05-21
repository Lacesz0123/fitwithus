import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';

/// A `TimerManager` singleton osztály felelős a pihenőidő visszaszámláló
/// kezeléséért, valamint a helyi értesítések megjelenítéséért.
class TimerManager {
  /// Singleton példány
  static final TimerManager _instance = TimerManager._internal();

  /// Gyári konstruktor, amely mindig ugyanazt az egy példányt adja vissza.
  factory TimerManager() => _instance;

  /// Privát belső konstruktor
  TimerManager._internal();

  Timer? _timer;
  Duration _remainingTime = const Duration(minutes: 1);
  int _selectedMinutes = 1;
  bool _isRunning = false;

  final String _prefsStartKey = 'restTimer_start';
  final String _prefsMinutesKey = 'restTimer_minutes';

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isDark = false; // Az aktuális téma (sötét mód) tárolása

  /// Callback függvény az UI értesítéséhez időzítő frissítéskor
  Function(Duration, bool)? onTimerUpdate;

  /// A sötét világítási mód beállítása.
  void setIsDark(bool isDark) {
    _isDark = isDark;
  }

  /// Az értesítések inicializálása és engedélykérések kezelése.
  void initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Értesítés megérintve: ${response.payload}');
        if (response.payload == 'timer_complete') {
          _showInAppNotification();
        }
      },
    );

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

    await _requestPermissions();
  }

  /// Értesítési engedélyek lekérése a felhasználótól.
  Future<void> _requestPermissions() async {
    final status = await Permission.notification.status;
    debugPrint('Notification permission status: $status');
    if (status.isDenied) {
      final result = await Permission.notification.request();
      debugPrint('Notification permission request result: $result');
    }
  }

  /// Helyi értesítés megjelenítése az időzítő lejártakor.
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
      _showInAppNotification();
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Az alkalmazáson belüli SnackBar értesítés megjelenítése.
  void _showInAppNotification() {
    final context = MainApp.navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Rest Timer Finished! Your rest period is over!'),
        backgroundColor: _isDark ? Colors.grey.shade700 : Colors.blueAccent,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Az időzítő állapotának elmentése a `SharedPreferences`-be.
  Future<void> _saveTimerState(DateTime startTime, int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsStartKey, startTime.toIso8601String());
    await prefs.setInt(_prefsMinutesKey, minutes);
  }

  /// Az elmentett időzítő állapot törlése.
  Future<void> _clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsStartKey);
    await prefs.remove(_prefsMinutesKey);
  }

  /// Az időzítő korábbi állapotának betöltése újraindítás esetén.
  ///
  /// Ha az időzítő még nem járt le, automatikusan újraindul a visszaszámlálás.
  Future<void> loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final startString = prefs.getString(_prefsStartKey);
    final minutes = prefs.getInt(_prefsMinutesKey);

    if (startString != null && minutes != null) {
      final startTime = DateTime.parse(startString);
      final elapsed = DateTime.now().difference(startTime);
      final total = Duration(minutes: minutes);
      final remaining = total - elapsed;

      if (remaining > Duration.zero) {
        _selectedMinutes = minutes;
        _remainingTime = remaining;
        _isRunning = true;
        startTimer(resume: true);
      } else {
        await _clearTimerState();
        resetTimer();
        await _showNotification();
      }
    }
  }

  /// Az időzítő elindítása.
  ///
  /// Ha `resume` igaz, akkor a korábbi állapotból folytatja.
  void startTimer({bool resume = false}) {
    _timer?.cancel();

    if (!resume) {
      _remainingTime = Duration(minutes: _selectedMinutes);
      _saveTimerState(DateTime.now(), _selectedMinutes);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingTime.inSeconds > 0) {
        _remainingTime -= const Duration(seconds: 1);
        onTimerUpdate?.call(_remainingTime, _isRunning);
      } else {
        timer.cancel();
        _isRunning = false;
        await _clearTimerState();
        await _showNotification();
        onTimerUpdate?.call(_remainingTime, _isRunning);
      }
    });

    _isRunning = true;
    onTimerUpdate?.call(_remainingTime, _isRunning);
  }

  /// Az időzítő szüneteltetése.
  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    onTimerUpdate?.call(_remainingTime, _isRunning);
  }

  /// Az időzítő visszaállítása az alapértelmezett kiválasztott percre.
  void resetTimer() {
    _timer?.cancel();
    _remainingTime = Duration(minutes: _selectedMinutes);
    _isRunning = false;
    _clearTimerState();
    onTimerUpdate?.call(_remainingTime, _isRunning);
  }

  /// A kiválasztott idő percben történő beállítása.
  ///
  /// Csak akkor állítható, ha az időzítő nem fut.
  void setSelectedMinutes(int minutes) {
    if (!_isRunning) {
      _selectedMinutes = minutes;
      _remainingTime = Duration(minutes: minutes);
      onTimerUpdate?.call(_remainingTime, _isRunning);
    }
  }

  /// Visszaadja a hátralévő időt.
  Duration getRemainingTime() => _remainingTime;

  /// Visszaadja a kiválasztott időzítő hosszát percben.
  int getSelectedMinutes() => _selectedMinutes;

  /// Igazat ad vissza, ha az időzítő épp fut.
  bool isRunning() => _isRunning;
}
