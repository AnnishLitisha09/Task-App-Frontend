import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/faculty_dashboard_stats.dart';
import '../models/faculty_info.dart';
import '../models/departmental_dashboard_model.dart';
import '../models/institutional_dashboard_model.dart';
import '../models/venue_dashboard_model.dart';
import '../models/venue_history_model.dart';
import '../models/student_dashboard_model.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../services/student_service.dart';
import '../services/socket_service.dart';
import 'package:workmanager/workmanager.dart';

// ─── Cache Entry ──────────────────────────────────────────────────────────────
class _CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;

  _CacheEntry(this.data) : fetchedAt = DateTime.now();

  // Data is considered fresh for 5 minutes
  bool get isFresh => DateTime.now().difference(fetchedAt).inMinutes < 5;
}

// ─── Section Loading States ────────────────────────────────────────────────────
enum SectionState { idle, loading, loaded, error }

// ─── AppStore (Zustand equivalent for Flutter) ────────────────────────────────
// One global singleton store. The UI subscribes to individual sections only,
// so only that section widget rebuilds — not the full page.
class AppStore extends ChangeNotifier {
  // ── Singleton ────────────────────────────────────────────────────────────
  static final AppStore _instance = AppStore._internal();
  factory AppStore() => _instance;
  AppStore._internal();

  final _taskService = TaskService();
  final _userService = UserService();
  final _notificationService = NotificationService();
  final _studentService = StudentService();

  // ── User profile cache ───────────────────────────────────────────────────
  String? userRole;
  List<String> allRoles = [];

  // ── Section states ───────────────────────────────────────────────────────
  final Map<String, SectionState> _states = {};
  final Map<String, String?> _errors = {};

  SectionState stateOf(String section) => _states[section] ?? SectionState.idle;
  bool isLoading(String section) => _states[section] == SectionState.loading;
  String? errorOf(String section) => _errors[section];

  // ── Faculty dashboard data ───────────────────────────────────────────────
  _CacheEntry<FacultyDashboardStats>? _facultyStatsCache;
  List<dynamic> pendingProofs = [];
  List<dynamic> pendingVerifications = [];
  List<dynamic> escalations = [];
  List<dynamic> authorityApprovals = [];
  int unreadNotifications = 0;

  FacultyDashboardStats? get facultyStats => _facultyStatsCache?.data;
  // FacultyInfo is embedded in facultyStats.facultyInfo — no separate fetch needed
  FacultyInfo? get facultyInfo => _facultyStatsCache?.data.facultyInfo;

  // ── Departmental (HOD) dashboard data ────────────────────────────────────
  _CacheEntry<DepartmentalDashboard>? _deptDashboardCache;
  DepartmentalDashboard? get deptDashboard => _deptDashboardCache?.data;

  // ── Institutional (Dean/Principal) dashboard data ─────────────────────────
  _CacheEntry<InstitutionalDashboard>? _institutionDashboardCache;
  InstitutionalDashboard? get institutionDashboard =>
      _institutionDashboardCache?.data;

  // ── Infrastructure (Incharge) dashboard data ────────────────────────────
  _CacheEntry<VenueDetailsResponse>? _venueDashboardCache;
  VenueDetailsResponse? get venueDashboard => _venueDashboardCache?.data;

  _CacheEntry<VenueHistoryResponse>? _venueHistoryCache;
  VenueHistoryResponse? get venueHistory => _venueHistoryCache?.data;

  // ── Student dashboard data ─────────────────────────────────────────────
  _CacheEntry<StudentDashboard>? _studentDashboardCache;
  StudentDashboard? get studentDashboard => _studentDashboardCache?.data;

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Public method to trigger a UI rebuild from outside the store.
  void triggerUpdate() => notifyListeners();

  void _setSection(String s, SectionState state, {String? error}) {
    _states[s] = state;
    _errors[s] = error;
    notifyListeners();
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken') ?? '';
  }

  String get _baseUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://localhost:3002/api/';

  // ─────────────────────────────────────────────────────────────────────────
  // User Profile (cached forever in session, only re-fetch on explicit invalidate)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> ensureUserRole({bool force = false}) async {
    if (!force && userRole != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      // allRoles is saved as a comma-separated string (not JSON)
      final allRolesStr = prefs.getString('allRoles');
      if (allRolesStr != null && allRolesStr.isNotEmpty) {
        allRoles = allRolesStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      final profile = await _userService.getUserProfile();
      userRole = profile.role;
      notifyListeners();
    } catch (_) {}
  }

  bool get isAuthority {
    const authorityRoles = ['hod', 'dean', 'principal', 'admin'];
    return allRoles.any((r) => authorityRoles.contains(r.toLowerCase())) ||
        (userRole != null && authorityRoles.contains(userRole!.toLowerCase()));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Unread notifications
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchUnreadNotifications({int? venueId}) async {
    try {
      final count = await _notificationService.getUnreadCount(venueId: venueId);
      unreadNotifications = count;
      notifyListeners();
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Faculty Stats (with smart cache — skip network if data is fresh)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchFacultyStats({bool force = false}) async {
    if (!force && _facultyStatsCache != null && _facultyStatsCache!.isFresh) {
      return; // Already fresh, skip request
    }

    _setSection('facultyStats', SectionState.loading);
    try {
      final token = await _token();
      final response = await http.get(
        Uri.parse('${_baseUrl}users/faculty/stats/daily'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stats = data is List
            ? FacultyDashboardStats.fromJson(data[0])
            : FacultyDashboardStats.fromJson(data);
        _facultyStatsCache = _CacheEntry(stats);

        // Populate escalations from the daily stats object if provided
        if (stats.escalatedTasks.isNotEmpty || escalations.isEmpty) {
          escalations = stats.escalatedTasks;
        }

        _setSection('facultyStats', SectionState.loaded);
      } else {
        _setSection(
          'facultyStats',
          SectionState.error,
          error: 'Failed to load stats',
        );
      }
    } catch (e) {
      _setSection('facultyStats', SectionState.error, error: e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Escalations
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchEscalations({bool force = false}) async {
    if (!force && _states['escalations'] == SectionState.loaded) return;
    _setSection('escalations', SectionState.loading);
    try {
      final response = await _taskService.getEscalations(unread: true);
      
      if (response.isNotEmpty) {
        escalations = response;
      } else if (facultyStats != null && facultyStats!.escalatedTasks.isNotEmpty) {
        escalations = facultyStats!.escalatedTasks;
      // also check student/staff payloads if needed, but AppStore handles escalations standalone mostly 
      } else {
        escalations = response;
      }
      
      _setSection('escalations', SectionState.loaded);
    } catch (e) {
      if (facultyStats != null && facultyStats!.escalatedTasks.isNotEmpty) {
        escalations = facultyStats!.escalatedTasks;
        _setSection('escalations', SectionState.loaded);
      } else {
        escalations = [];
        _setSection('escalations', SectionState.error, error: e.toString());
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Pending Proofs
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchPendingProofs({bool force = false}) async {
    if (!force && _states['pendingProofs'] == SectionState.loaded) return;
    _setSection('pendingProofs', SectionState.loading);
    try {
      final dynamic response = await _taskService.getPendingProofs();
      List<dynamic> raw = [];
      if (response is Map) {
        raw =
            (response['items'] as List?) ?? (response['tasks'] as List?) ?? [];
      } else if (response is List) {
        raw = response;
      }

      // Tasks are securely scoped to the current user by the backend.
      pendingProofs = raw;

      _setSection('pendingProofs', SectionState.loaded);
    } catch (e) {
      pendingProofs = [];
      _setSection('pendingProofs', SectionState.error, error: e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Pending Verifications
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchPendingVerifications({bool force = false}) async {
    if (!force && _states['pendingVerifications'] == SectionState.loaded) {
      return;
    }
    _setSection('pendingVerifications', SectionState.loading);
    try {
      final dynamic response = await _taskService.getPendingVerifications();
      List<dynamic> raw = response is List ? response : [];

      // Tasks are securely scoped to the current user by the backend.
      pendingVerifications = raw;

      _setSection('pendingVerifications', SectionState.loaded);
    } catch (e) {
      pendingVerifications = [];
      _setSection(
        'pendingVerifications',
        SectionState.error,
        error: e.toString(),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Authority Approvals (HOD+ only)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchAuthorityApprovals({bool force = false}) async {
    if (!force && _states['authorityApprovals'] == SectionState.loaded) return;
    if (!isAuthority) {
      authorityApprovals = [];
      return;
    }
    _setSection('authorityApprovals', SectionState.loading);
    try {
      // Re-use cached dept dashboard if fresh to avoid a redundant API call.
      // Only fetch fresh if not already cached.
      await fetchDeptDashboard(force: force);
      final dashboard = deptDashboard;
      if (dashboard != null) {
        authorityApprovals = dashboard.pendingApprovals;
        _setSection('authorityApprovals', SectionState.loaded);
      } else {
        authorityApprovals = [];
        _setSection('authorityApprovals', SectionState.error, error: 'Dashboard unavailable');
      }
    } catch (e) {
      authorityApprovals = [];
      _setSection(
        'authorityApprovals',
        SectionState.error,
        error: e.toString(),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Departmental Dashboard (HOD)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchDeptDashboard({bool force = false}) async {
    if (!force && _deptDashboardCache != null && _deptDashboardCache!.isFresh) {
      return;
    }
    _setSection('deptDashboard', SectionState.loading);
    try {
      final dashboard = await _userService.getDepartmentalDashboard();
      _deptDashboardCache = _CacheEntry(dashboard);

      // Sink unified personal/verification/escalation tasks from HOD response into global lists
      pendingProofs = dashboard.pendingProofs;
      pendingVerifications = dashboard.verificationTasks;
      escalations = dashboard.escalatedTasks;
      authorityApprovals = dashboard.pendingApprovals;

      _setSection('deptDashboard', SectionState.loaded);
      
      // Mark sub-sections as loaded since we just hydrated them
      _states['pendingProofs'] = SectionState.loaded;
      _states['pendingVerifications'] = SectionState.loaded;
      _states['escalations'] = SectionState.loaded;
      _states['authorityApprovals'] = SectionState.loaded;
      _errors.remove('pendingProofs');
      _errors.remove('pendingVerifications');
      _errors.remove('escalations');
      _errors.remove('authorityApprovals');
      
      notifyListeners();
    } catch (e) {
      _setSection('deptDashboard', SectionState.error, error: e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Institutional Dashboard (Dean / Principal)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchInstitutionDashboard({bool force = false}) async {
    if (!force &&
        _institutionDashboardCache != null &&
        _institutionDashboardCache!.isFresh) {
      return;
    }
    _setSection('institutionDashboard', SectionState.loading);
    try {
      final dashboard = await _userService.getInstitutionalDashboard();
      _institutionDashboardCache = _CacheEntry(dashboard);
      _setSection('institutionDashboard', SectionState.loaded);
    } catch (e) {
      _setSection(
        'institutionDashboard',
        SectionState.error,
        error: e.toString(),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Infrastructure Dashboard (Venue Incharge)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchVenueDashboard({bool force = false}) async {
    if (!force &&
        _venueDashboardCache != null &&
        _venueDashboardCache!.isFresh) {
      return;
    }
    _setSection('venueDashboard', SectionState.loading);
    try {
      final dashboard = await _taskService.getVenueDashboard();
      _venueDashboardCache = _CacheEntry(dashboard);
      _setSection('venueDashboard', SectionState.loaded);
    } catch (e) {
      _setSection('venueDashboard', SectionState.error, error: e.toString());
    }
  }

  Future<void> fetchVenueHistory({int? venueId, bool force = false}) async {
    // Note: History cache logic is slightly complex with venueId changes,
    // so we skip freshness check if a specific logic dictates it, or just use force.
    if (!force && _venueHistoryCache != null && _venueHistoryCache!.isFresh) {
      return;
    }
    _setSection('venueHistory', SectionState.loading);
    try {
      final history = await _taskService.getVenueHistory(
        venueId: venueId,
        days: 7,
      );
      _venueHistoryCache = _CacheEntry(history);
      _setSection('venueHistory', SectionState.loaded);
    } catch (e) {
      _setSection('venueHistory', SectionState.error, error: e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Student Dashboard
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchStudentDashboard({bool force = false}) async {
    if (!force &&
        _studentDashboardCache != null &&
        _studentDashboardCache!.isFresh) {
      return;
    }
    _setSection('studentDashboard', SectionState.loading);
    try {
      final dashboard = await _studentService.getStudentDashboard();
      _studentDashboardCache = _CacheEntry(dashboard);
      _setSection('studentDashboard', SectionState.loaded);
    } catch (e) {
      _setSection('studentDashboard', SectionState.error, error: e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Invalidation helpers (call after create/update/action)
  // ─────────────────────────────────────────────────────────────────────────

  /// Invalidates all faculty-page related sections so the next access re-fetches.
  void invalidateFaculty() {
    _facultyStatsCache = null;
    _states.remove('facultyStats');
    _states.remove('pendingProofs');
    _states.remove('pendingVerifications');
    _states.remove('authorityApprovals');
    notifyListeners();
  }

  /// Re-fetches only the sections that actually changed after an action.
  Future<void> refreshFacultyAfterAction() async {
    await Future.wait([
      fetchFacultyStats(force: true),
      fetchPendingProofs(force: true),
      fetchPendingVerifications(force: true),
    ]);
  }

  void invalidateDeptDashboard() {
    _deptDashboardCache = null;
    _states.remove('deptDashboard');
    notifyListeners();
  }

  void invalidateInstitutionDashboard() {
    _institutionDashboardCache = null;
    _states.remove('institutionDashboard');
    notifyListeners();
  }

  /// Full reset on logout
  void clearAll() {
    userRole = null;
    allRoles = [];
    _facultyStatsCache = null;
    _deptDashboardCache = null;
    _institutionDashboardCache = null;
    _studentDashboardCache = null;
    pendingProofs = [];
    pendingVerifications = [];
    escalations = [];
    authorityApprovals = [];
    unreadNotifications = 0;
    _states.clear();
    _errors.clear();
    SocketService.disconnect();
    Workmanager().cancelAll();
    notifyListeners();
  }
}
