import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room.dart';
import '../models/tenant.dart';
import '../models/payment.dart';
import '../models/maintenance.dart';

class JsonStorageService {
  static const String _roomsKey = 'rooms';
  static const String _tenantsKey = 'tenants';
  static const String _paymentsKey = 'payments';
  static const String _maintenanceKey = 'maintenance';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Room CRUD methods
  Future<void> addRoom(Room room) async {
    final rooms = await getRooms();
    rooms.add(room);
    final roomsJson = rooms.map((r) => r.toMap()).toList();
    await _prefs.setString(_roomsKey, json.encode(roomsJson));
  }

  Future<List<Room>> getRooms() async {
    final roomsString = _prefs.getString(_roomsKey);
    if (roomsString == null) return [];
    
    final List<dynamic> roomsJson = json.decode(roomsString);
    return roomsJson.map((r) => Room.fromMap(r)).toList();
  }

  Future<void> updateRoom(Room room) async {
    final rooms = await getRooms();
    final index = rooms.indexWhere((r) => r.id == room.id);
    if (index != -1) {
      rooms[index] = room;
      final roomsJson = rooms.map((r) => r.toMap()).toList();
      await _prefs.setString(_roomsKey, json.encode(roomsJson));
    }
  }

  Future<void> deleteRoom(String roomId) async {
    final rooms = await getRooms();
    rooms.removeWhere((r) => r.id == roomId);
    final roomsJson = rooms.map((r) => r.toMap()).toList();
    await _prefs.setString(_roomsKey, json.encode(roomsJson));
  }

  // Tenant CRUD methods
  Future<void> addTenant(Tenant tenant) async {
    final tenants = await getTenants();
    tenants.add(tenant);
    final tenantsJson = tenants.map((t) => t.toMap()).toList();
    await _prefs.setString(_tenantsKey, json.encode(tenantsJson));
  }

  Future<List<Tenant>> getTenants() async {
    final tenantsString = _prefs.getString(_tenantsKey);
    if (tenantsString == null) return [];
    
    final List<dynamic> tenantsJson = json.decode(tenantsString);
    return tenantsJson.map((t) => Tenant.fromMap(t)).toList();
  }

  Future<void> updateTenant(Tenant tenant) async {
    final tenants = await getTenants();
    final index = tenants.indexWhere((t) => t.id == tenant.id);
    if (index != -1) {
      tenants[index] = tenant;
      final tenantsJson = tenants.map((t) => t.toMap()).toList();
      await _prefs.setString(_tenantsKey, json.encode(tenantsJson));
    }
  }

  Future<void> deleteTenant(String tenantId) async {
    final tenants = await getTenants();
    tenants.removeWhere((t) => t.id == tenantId);
    final tenantsJson = tenants.map((t) => t.toMap()).toList();
    await _prefs.setString(_tenantsKey, json.encode(tenantsJson));
  }

  // Payment CRUD methods
  Future<void> addPayment(Payment payment) async {
    final payments = await getPayments();
    payments.add(payment);
    final paymentsJson = payments.map((p) => p.toMap()).toList();
    await _prefs.setString(_paymentsKey, json.encode(paymentsJson));
  }

  Future<List<Payment>> getPayments() async {
    final paymentsString = _prefs.getString(_paymentsKey);
    if (paymentsString == null) return [];
    
    final List<dynamic> paymentsJson = json.decode(paymentsString);
    return paymentsJson.map((p) => Payment.fromMap(p)).toList();
  }

  Future<void> updatePayment(Payment payment) async {
    final payments = await getPayments();
    final index = payments.indexWhere((p) => p.id == payment.id);
    if (index != -1) {
      payments[index] = payment;
      final paymentsJson = payments.map((p) => p.toMap()).toList();
      await _prefs.setString(_paymentsKey, json.encode(paymentsJson));
    }
  }

  Future<void> deletePayment(String paymentId) async {
    final payments = await getPayments();
    payments.removeWhere((p) => p.id == paymentId);
    final paymentsJson = payments.map((p) => p.toMap()).toList();
    await _prefs.setString(_paymentsKey, json.encode(paymentsJson));
  }

  // Maintenance CRUD methods
  Future<void> addMaintenance(Maintenance maintenance) async {
    final maintenanceList = await getMaintenance();
    maintenanceList.add(maintenance);
    final maintenanceJson = maintenanceList.map((m) => m.toMap()).toList();
    await _prefs.setString(_maintenanceKey, json.encode(maintenanceJson));
  }

  Future<List<Maintenance>> getMaintenance() async {
    final maintenanceString = _prefs.getString(_maintenanceKey);
    if (maintenanceString == null) return [];
    
    final List<dynamic> maintenanceJson = json.decode(maintenanceString);
    return maintenanceJson.map((m) => Maintenance.fromMap(m)).toList();
  }

  Future<void> updateMaintenance(Maintenance maintenance) async {
    final maintenanceList = await getMaintenance();
    final index = maintenanceList.indexWhere((m) => m.id == maintenance.id);
    if (index != -1) {
      maintenanceList[index] = maintenance;
      final maintenanceJson = maintenanceList.map((m) => m.toMap()).toList();
      await _prefs.setString(_maintenanceKey, json.encode(maintenanceJson));
    }
  }

  Future<void> deleteMaintenance(String maintenanceId) async {
    final maintenanceList = await getMaintenance();
    maintenanceList.removeWhere((m) => m.id == maintenanceId);
    final maintenanceJson = maintenanceList.map((m) => m.toMap()).toList();
    await _prefs.setString(_maintenanceKey, json.encode(maintenanceJson));
  }
}