import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'data_service.dart';
import '../models/category.dart';

/// Local, opt-in, inexact reminders. Notification IDs are tracked so a paid,
/// edited or deleted bill cannot leave a stale scheduled alert behind.
class BillNotificationService {
  BillNotificationService._();
  static final instance = BillNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const _channel = AndroidNotificationDetails(
    'byelui_bill_reminders',
    'Bill reminders',
    channelDescription: 'Credit card and recurring bill due date reminders',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );
  static const _details = NotificationDetails(
    android: _channel,
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await _initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  int _idFor(String key) {
    // Stable nonzero 31-bit FNV hash, independent of Dart hashCode randomization.
    var h = 0x811c9dc5;
    for (final byte in utf8.encode(key)) {
      h = ((h ^ byte) * 0x01000193) & 0xffffffff;
    }
    return (h & 0x7fffffff) | 1;
  }

  Future<void> sync() async {
    final data = DataService();
    if (!data.billRemindersEnabled) {
      await cancelAllManaged();
      return;
    }
    await _initialize();

    // Cancel only our IDs, never unrelated notification channels.
    final old = data.billNotificationIds.toSet();
    for (final id in old) {
      await _plugin.cancel(id);
    }
    final nextIds = <int>{};
    final now = DateTime.now();
    final events = <({String key, String label, DateTime due, String type})>[];

    for (final bill in data.getCardStatements()) {
      if (bill.isPaid) continue;
      events.add((
        key: 'card:${bill.id}',
        label: bill.cardName,
        due: bill.dueDate,
        type: 'Credit card statement',
      ));
    }

    // Only next scheduled occurrence; never claim an auto-generated
    // recurring expense is unpaid.
    for (final bill in data.getRecurringTransactions(activeOnly: true)) {
      if (bill.type != TransactionType.expense) continue;
      final due = bill.nextDueDate ?? bill.startDate;
      if (bill.endDate != null && due.isAfter(bill.endDate!)) continue;
      events.add((
        key: 'recurring:${bill.id}:${due.year}-${due.month}-${due.day}',
        label: bill.description,
        due: due,
        type: 'Scheduled recurring expense',
      ));
    }

    // One alert per bill, at the user's chosen lead time.
    // Old 7/3/1-day notifications are cancelled above on every sync.
    final daysBefore = data.billReminderDaysBefore;
    for (final event in events.take(54)) {
      final localTime = DateTime(
        event.due.year, event.due.month, event.due.day - daysBefore, 9,
      );
      if (!localTime.isAfter(now)) continue;
      final id = _idFor('${event.key}:$daysBefore');
      if (!nextIds.add(id)) continue;
      try {
        await _plugin.zonedSchedule(
          id,
          '${event.type} due in $daysBefore day${daysBefore == 1 ? '' : 's'}',
          event.label,
          tz.TZDateTime.from(localTime, tz.UTC),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (error) {
        nextIds.remove(id);
        debugPrint('Could not schedule bill reminder: $error');
      }
    }
    await data.setBillNotificationIds(nextIds.toList());
  }

  Future<void> cancelAllManaged() async {
    final data = DataService();
    await _initialize();
    for (final id in data.billNotificationIds) {
      await _plugin.cancel(id);
    }
    await data.setBillNotificationIds([]);
  }

  Future<void> syncSafely() async {
    try {
      await sync();
    } catch (error) {
      debugPrint('Bill reminder synchronization failed: $error');
    }
  }
}
