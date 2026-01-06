import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room.dart';
import '../models/tenant.dart';
import '../models/payment.dart';
import '../models/maintenance.dart';

class StorageService {
  static const String _roomsKey = 'rooms';
  static const String _tenantsKey = 'tenants';
  static const String _paymentsKey = 'payments';
  static const String _maintenanceKey = 'maintenance';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Room Operations
  Future<void> addRoom(Room room) async {
    final rooms = await getRooms();
    rooms.add(room);
    await _prefs.setString(_roomsKey, jsonEncode(rooms.map((r) => r.toMap()).toList()));
  }

  Future<List<Room>> getRooms() async {
    final data = _prefs.getString(_roomsKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Room.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateRoom(Room room) async {
    final rooms = await getRooms();
    final index = rooms.indexWhere((r) => r.id == room.id);
    if (index != -1) {
      rooms[index] = room;
      await _prefs.setString(_roomsKey, jsonEncode(rooms.map((r) => r.toMap()).toList()));
    }
  }

  Future<void> deleteRoom(String roomId) async {
    final rooms = await getRooms();
    rooms.removeWhere((r) => r.id == roomId);
    await _prefs.setString(_roomsKey, jsonEncode(rooms.map((r) => r.toMap()).toList()));
  }

  // Tenant Operations
  Future<void> addTenant(Tenant tenant) async {
    final tenants = await getTenants();
    tenants.add(tenant);
    await _prefs.setString(_tenantsKey, jsonEncode(tenants.map((t) => t.toMap()).toList()));
  }

  Future<List<Tenant>> getTenants() async {
    final data = _prefs.getString(_tenantsKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Tenant.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateTenant(Tenant tenant) async {
    final tenants = await getTenants();
    final index = tenants.indexWhere((t) => t.id == tenant.id);
    if (index != -1) {
      tenants[index] = tenant;
      await _prefs.setString(_tenantsKey, jsonEncode(tenants.map((t) => t.toMap()).toList()));
    }
  }

  Future<void> deleteTenant(String tenantId) async {
    final tenants = await getTenants();
    tenants.removeWhere((t) => t.id == tenantId);
    await _prefs.setString(_tenantsKey, jsonEncode(tenants.map((t) => t.toMap()).toList()));
  }

  // Payment Operations
  Future<void> addPayment(Payment payment) async {
    final payments = await getPayments();
    payments.add(payment);
    await _prefs.setString(_paymentsKey, jsonEncode(payments.map((p) => p.toMap()).toList()));
  }

  Future<List<Payment>> getPayments() async {
    final data = _prefs.getString(_paymentsKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Payment.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> updatePayment(Payment payment) async {
    final payments = await getPayments();
    final index = payments.indexWhere((p) => p.id == payment.id);
    if (index != -1) {
      payments[index] = payment;
      await _prefs.setString(_paymentsKey, jsonEncode(payments.map((p) => p.toMap()).toList()));
    }
  }

  Future<void> deletePayment(String paymentId) async {
    final payments = await getPayments();
    payments.removeWhere((p) => p.id == paymentId);
    await _prefs.setString(_paymentsKey, jsonEncode(payments.map((p) => p.toMap()).toList()));
  }

  // Maintenance Operations
  Future<void> addMaintenance(Maintenance maintenance) async {
    final items = await getMaintenance();
    items.add(maintenance);
    await _prefs.setString(_maintenanceKey, jsonEncode(items.map((m) => m.toMap()).toList()));
  }

  Future<List<Maintenance>> getMaintenance() async {
    final data = _prefs.getString(_maintenanceKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Maintenance.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateMaintenance(Maintenance maintenance) async {
    final items = await getMaintenance();
    final index = items.indexWhere((m) => m.id == maintenance.id);
    if (index != -1) {
      items[index] = maintenance;
      await _prefs.setString(_maintenanceKey, jsonEncode(items.map((m) => m.toMap()).toList()));
    }
  }

  Future<void> deleteMaintenance(String maintenanceId) async {
    final items = await getMaintenance();
    items.removeWhere((m) => m.id == maintenanceId);
    await _prefs.setString(_maintenanceKey, jsonEncode(items.map((m) => m.toMap()).toList()));
  }
}
