/// Account & subscription management for Harmonoid.
///
/// NOTE: This is an OFFLINE community reimplementation. The original private
/// upstream package (Supabase + Play Billing backed) is unavailable. In this
/// rebuild:
///
/// * No backend exists — all edge-function calls report "unavailable"
///   gracefully (HTTP 503) through the [Supabase] shim below.
/// * Every "Plus" feature is unlocked locally ([SubscriptionNotifier.state]
///   is always [SubscriptionValid]).
/// * Sign-in always fails with a clear [AuthException] message.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'identity.freezed.dart';
part 'identity.g.dart';

// ---------------------------------------------------------------------------
// Supabase-compatible offline shim.
// ---------------------------------------------------------------------------

/// HTTP methods for edge-function invocation.
enum HttpMethod {
  get,
  post,
  put,
  delete,
  patch,
}

/// Response of an edge-function invocation.
class FunctionResponse {
  FunctionResponse({this.data, this.status = 503});

  final dynamic data;
  final int status;
}

/// Offline shim for the Supabase functions client.
class SupabaseFunctionsClient {
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
    HttpMethod method = HttpMethod.post,
  }) async {
    return FunctionResponse(data: null, status: 503);
  }
}

/// Offline shim for the Supabase client.
class SupabaseClient {
  final SupabaseFunctionsClient functions = SupabaseFunctionsClient();
}

/// Offline shim for the Supabase singleton.
class Supabase {
  Supabase._();

  static Supabase? _instance;

  /// The singleton instance.
  static Supabase get instance => _instance ??= Supabase._();

  /// The (offline) client.
  SupabaseClient get client => _client;

  final SupabaseClient _client = SupabaseClient();
}

/// A (minimal) user record.
class User {
  User({this.email});

  final String? email;
}

/// A (minimal) auth session.
class Session {
  Session({User? user}) : user = user ?? User();

  final User user;
}

/// Authentication failure.
class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

// ---------------------------------------------------------------------------
// Identity storage bridge.
// ---------------------------------------------------------------------------

/// Persists identity-related items through the host application's storage.
class IdentityNotifier {
  IdentityNotifier._();

  static FutureOr<String?> Function(String key)? _getItem;
  static FutureOr<void> Function(String key, String value)? _setItem;
  static FutureOr<void> Function(String key)? _removeItem;
  static String? _deviceId;

  /// Initializes the identity storage bridge.
  static Future<void> ensureInitialized({
    required FutureOr<String?> Function(String key) getItem,
    required FutureOr<void> Function(String key, String value) setItem,
    required FutureOr<void> Function(String key) removeItem,
    required String deviceId,
  }) async {
    _getItem = getItem;
    _setItem = setItem;
    _removeItem = removeItem;
    _deviceId = deviceId;
  }

  /// Reads a persisted value.
  static Future<String?> getItem(String key) async => await _getItem?.call(key);

  /// Persists a value.
  static Future<void> setItem(String key, String value) async =>
      await _setItem?.call(key, value);

  /// Removes a persisted value.
  static Future<void> removeItem(String key) async =>
      await _removeItem?.call(key);

  /// Anonymous device identifier supplied by the host application.
  static String? get deviceId => _deviceId;
}

// ---------------------------------------------------------------------------
// Authentication.
// ---------------------------------------------------------------------------

/// Notifies about the (signed-in) user.
///
/// The offline rebuild has no backend, so authentication always fails with
/// an [AuthException].
class UserNotifier extends ChangeNotifier {
  Session? _session;

  /// Current session; `null` when signed out.
  Session? get session => _session;

  /// Requests a one-time-password for [email].
  Future<void> authenticate(String email) async {
    throw AuthException(
      'Account system is not available in this community rebuild.',
    );
  }

  /// Verifies the one-time-password [otp] sent to [email].
  Future<void> verify(String email, String otp) async {
    throw AuthException(
      'Account system is not available in this community rebuild.',
    );
  }

  /// Signs the user out.
  Future<void> logout() async {
    _session = null;
    notifyListeners();
  }
}

/// Creates [UserNotifier] instances (dependency-injection seam).
class UserNotifierFactory {
  static UserNotifier create() => UserNotifier();
}

// ---------------------------------------------------------------------------
// Subscription.
// ---------------------------------------------------------------------------

/// State of the "Harmonoid Plus" subscription.
sealed class SubscriptionState {
  const SubscriptionState();

  @override
  String toString() => runtimeType.toString();
}

/// An active subscription.
class SubscriptionValid extends SubscriptionState {
  const SubscriptionValid();
}

/// No subscription present.
class SubscriptionInvalid extends SubscriptionState {
  const SubscriptionInvalid();
}

/// A subscription which has expired.
class SubscriptionExpired extends SubscriptionState {
  const SubscriptionExpired();
}

/// A subscription which could not be verified.
class SubscriptionUnverified extends SubscriptionState {
  const SubscriptionUnverified();
}

/// Details of a subscription.
class Subscription {
  Subscription({this.email, this.expiresAt});

  final String? email;
  final DateTime? expiresAt;

  /// Human-readable label shown in the settings.
  String toLabel(BuildContext context) => 'Plus';
}

/// Remote configuration controlling whether purchases are offered.
@freezed
abstract class SubscriptionPurchaseConfig
    with _$SubscriptionPurchaseConfig {
  const factory SubscriptionPurchaseConfig({
    @JsonKey(name: 'max_version') required String maxVersion,
    @JsonKey(name: 'min_version') required String minVersion,
    @JsonKey(name: 'blacklisted_versions')
    required List<String> blacklistedVersions,
  }) = _SubscriptionPurchaseConfig;

  factory SubscriptionPurchaseConfig.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPurchaseConfigFromJson(json);
}

/// Host-application callbacks used by the subscription flows.
class SubscriptionFunctions {
  const SubscriptionFunctions({
    required this.updateAvailable,
    required this.getSubscriptionConfig,
    required this.showUpdate,
    required this.showLogin,
    required this.onSubscriptionUpdate,
    required this.onSubscriptionError,
    required this.onLicenseTap,
    required this.onPrivacyTap,
    required this.showTagEditorDemo,
  });

  final bool Function() updateAvailable;
  final Future<SubscriptionPurchaseConfig?> Function() getSubscriptionConfig;
  final Future<bool> Function() showUpdate;
  final Future<void> Function() showLogin;
  final void Function(SubscriptionState state) onSubscriptionUpdate;
  final void Function(SubscriptionState state) onSubscriptionError;
  final Future<bool> Function() onLicenseTap;
  final Future<bool> Function() onPrivacyTap;
  final Future<void> Function() showTagEditorDemo;
}

/// Notifies about the "Harmonoid Plus" subscription.
///
/// The offline rebuild always reports a valid subscription so that every
/// feature is unlocked locally.
class SubscriptionNotifier extends ChangeNotifier {
  /// Initializes the subscription state.
  static Future<void> ensureInitialized() async {}

  /// Current subscription state (always [SubscriptionValid]).
  SubscriptionState get state => const SubscriptionValid();

  /// Current subscription details.
  Subscription? get subscription => Subscription();

  /// Deletes the account (no-op: no backend).
  Future<void> deleteAccount() async {}

  /// Runs [open], optionally gating it behind the paywall.
  ///
  /// With the offline rebuild this always runs [open] directly.
  Future<void> accessSubscriptionFeature(
    BuildContext context,
    Future<void> Function() open,
  ) async {
    await open();
  }
}

/// Creates [SubscriptionNotifier] instances (dependency-injection seam).
class SubscriptionNotifierFactory {
  static SubscriptionNotifier create({
    required String version,
    required UserNotifier userNotifier,
    required SubscriptionFunctions functions,
  }) {
    return SubscriptionNotifier();
  }
}

/// Compares `vX.Y.Z`-style version strings; returns whether [to] > [from].
bool compareVersions(String? to, String from) {
  if (to == null) return false;
  final latestVersionParts = to.substring(1).split('.');
  final currentVersionParts = from.substring(1).split('.');
  for (var i = 0;
      i < math.max(latestVersionParts.length, currentVersionParts.length);
      i++) {
    final latestPart =
        int.parse(latestVersionParts.elementAtOrNull(i) ?? '0');
    final currentPart =
        int.parse(currentVersionParts.elementAtOrNull(i) ?? '0');
    if (latestPart > currentPart) return true;
    if (latestPart < currentPart) return false;
  }
  return false;
}

// ---------------------------------------------------------------------------
// Widgets.
// ---------------------------------------------------------------------------

/// Supplies localized strings for the identity/subscription UI.
class SubscriptionLocalizations extends StatelessWidget {
  const SubscriptionLocalizations.fromCode({
    super.key,
    required String code,
    required this.child,
  }) : _code = code;

  final String _code;
  final Widget child;

  /// Locale code supplied by the host application.
  String get code => _code;

  @override
  Widget build(BuildContext context) => child;
}

/// Wraps "Plus"-gated UI.
///
/// The offline rebuild has a valid subscription at all times, so this simply
/// passes [child] through.
class SubscriptionReveal extends StatelessWidget {
  const SubscriptionReveal({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Observes navigation for subscription gating (no-op in this rebuild).
class SubscriptionNavigationObserver extends NavigatorObserver {
  SubscriptionNavigationObserver();
}
