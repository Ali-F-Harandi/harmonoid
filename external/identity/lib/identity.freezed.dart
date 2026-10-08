// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'identity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubscriptionPurchaseConfig implements DiagnosticableTreeMixin {
  @JsonKey(name: 'max_version')
  String get maxVersion;
  @JsonKey(name: 'min_version')
  String get minVersion;
  @JsonKey(name: 'blacklisted_versions')
  List<String> get blacklistedVersions;

  /// Create a copy of SubscriptionPurchaseConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SubscriptionPurchaseConfigCopyWith<SubscriptionPurchaseConfig>
      get copyWith =>
          _$SubscriptionPurchaseConfigCopyWithImpl<SubscriptionPurchaseConfig>(
              this as SubscriptionPurchaseConfig, _$identity);

  /// Serializes this SubscriptionPurchaseConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'SubscriptionPurchaseConfig'))
      ..add(DiagnosticsProperty('maxVersion', maxVersion))
      ..add(DiagnosticsProperty('minVersion', minVersion))
      ..add(DiagnosticsProperty('blacklistedVersions', blacklistedVersions));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SubscriptionPurchaseConfig &&
            (identical(other.maxVersion, maxVersion) ||
                other.maxVersion == maxVersion) &&
            (identical(other.minVersion, minVersion) ||
                other.minVersion == minVersion) &&
            const DeepCollectionEquality()
                .equals(other.blacklistedVersions, blacklistedVersions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, maxVersion, minVersion,
      const DeepCollectionEquality().hash(blacklistedVersions));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SubscriptionPurchaseConfig(maxVersion: $maxVersion, minVersion: $minVersion, blacklistedVersions: $blacklistedVersions)';
  }
}

/// @nodoc
abstract mixin class $SubscriptionPurchaseConfigCopyWith<$Res> {
  factory $SubscriptionPurchaseConfigCopyWith(SubscriptionPurchaseConfig value,
          $Res Function(SubscriptionPurchaseConfig) _then) =
      _$SubscriptionPurchaseConfigCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'max_version') String maxVersion,
      @JsonKey(name: 'min_version') String minVersion,
      @JsonKey(name: 'blacklisted_versions') List<String> blacklistedVersions});
}

/// @nodoc
class _$SubscriptionPurchaseConfigCopyWithImpl<$Res>
    implements $SubscriptionPurchaseConfigCopyWith<$Res> {
  _$SubscriptionPurchaseConfigCopyWithImpl(this._self, this._then);

  final SubscriptionPurchaseConfig _self;
  final $Res Function(SubscriptionPurchaseConfig) _then;

  /// Create a copy of SubscriptionPurchaseConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxVersion = null,
    Object? minVersion = null,
    Object? blacklistedVersions = null,
  }) {
    return _then(_self.copyWith(
      maxVersion: null == maxVersion
          ? _self.maxVersion
          : maxVersion // ignore: cast_nullable_to_non_nullable
              as String,
      minVersion: null == minVersion
          ? _self.minVersion
          : minVersion // ignore: cast_nullable_to_non_nullable
              as String,
      blacklistedVersions: null == blacklistedVersions
          ? _self.blacklistedVersions
          : blacklistedVersions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// Adds pattern-matching-related methods to [SubscriptionPurchaseConfig].
extension SubscriptionPurchaseConfigPatterns on SubscriptionPurchaseConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_SubscriptionPurchaseConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SubscriptionPurchaseConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_SubscriptionPurchaseConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubscriptionPurchaseConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_SubscriptionPurchaseConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubscriptionPurchaseConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            @JsonKey(name: 'max_version') String maxVersion,
            @JsonKey(name: 'min_version') String minVersion,
            @JsonKey(name: 'blacklisted_versions')
            List<String> blacklistedVersions)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SubscriptionPurchaseConfig() when $default != null:
        return $default(
            _that.maxVersion, _that.minVersion, _that.blacklistedVersions);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            @JsonKey(name: 'max_version') String maxVersion,
            @JsonKey(name: 'min_version') String minVersion,
            @JsonKey(name: 'blacklisted_versions')
            List<String> blacklistedVersions)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubscriptionPurchaseConfig():
        return $default(
            _that.maxVersion, _that.minVersion, _that.blacklistedVersions);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            @JsonKey(name: 'max_version') String maxVersion,
            @JsonKey(name: 'min_version') String minVersion,
            @JsonKey(name: 'blacklisted_versions')
            List<String> blacklistedVersions)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubscriptionPurchaseConfig() when $default != null:
        return $default(
            _that.maxVersion, _that.minVersion, _that.blacklistedVersions);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SubscriptionPurchaseConfig
    with DiagnosticableTreeMixin
    implements SubscriptionPurchaseConfig {
  const _SubscriptionPurchaseConfig(
      {@JsonKey(name: 'max_version') required this.maxVersion,
      @JsonKey(name: 'min_version') required this.minVersion,
      @JsonKey(name: 'blacklisted_versions')
      required final List<String> blacklistedVersions})
      : _blacklistedVersions = blacklistedVersions;
  factory _SubscriptionPurchaseConfig.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPurchaseConfigFromJson(json);

  @override
  @JsonKey(name: 'max_version')
  final String maxVersion;
  @override
  @JsonKey(name: 'min_version')
  final String minVersion;
  final List<String> _blacklistedVersions;
  @override
  @JsonKey(name: 'blacklisted_versions')
  List<String> get blacklistedVersions {
    if (_blacklistedVersions is EqualUnmodifiableListView)
      return _blacklistedVersions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_blacklistedVersions);
  }

  /// Create a copy of SubscriptionPurchaseConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SubscriptionPurchaseConfigCopyWith<_SubscriptionPurchaseConfig>
      get copyWith => __$SubscriptionPurchaseConfigCopyWithImpl<
          _SubscriptionPurchaseConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SubscriptionPurchaseConfigToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'SubscriptionPurchaseConfig'))
      ..add(DiagnosticsProperty('maxVersion', maxVersion))
      ..add(DiagnosticsProperty('minVersion', minVersion))
      ..add(DiagnosticsProperty('blacklistedVersions', blacklistedVersions));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SubscriptionPurchaseConfig &&
            (identical(other.maxVersion, maxVersion) ||
                other.maxVersion == maxVersion) &&
            (identical(other.minVersion, minVersion) ||
                other.minVersion == minVersion) &&
            const DeepCollectionEquality()
                .equals(other._blacklistedVersions, _blacklistedVersions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, maxVersion, minVersion,
      const DeepCollectionEquality().hash(_blacklistedVersions));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SubscriptionPurchaseConfig(maxVersion: $maxVersion, minVersion: $minVersion, blacklistedVersions: $blacklistedVersions)';
  }
}

/// @nodoc
abstract mixin class _$SubscriptionPurchaseConfigCopyWith<$Res>
    implements $SubscriptionPurchaseConfigCopyWith<$Res> {
  factory _$SubscriptionPurchaseConfigCopyWith(
          _SubscriptionPurchaseConfig value,
          $Res Function(_SubscriptionPurchaseConfig) _then) =
      __$SubscriptionPurchaseConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'max_version') String maxVersion,
      @JsonKey(name: 'min_version') String minVersion,
      @JsonKey(name: 'blacklisted_versions') List<String> blacklistedVersions});
}

/// @nodoc
class __$SubscriptionPurchaseConfigCopyWithImpl<$Res>
    implements _$SubscriptionPurchaseConfigCopyWith<$Res> {
  __$SubscriptionPurchaseConfigCopyWithImpl(this._self, this._then);

  final _SubscriptionPurchaseConfig _self;
  final $Res Function(_SubscriptionPurchaseConfig) _then;

  /// Create a copy of SubscriptionPurchaseConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? maxVersion = null,
    Object? minVersion = null,
    Object? blacklistedVersions = null,
  }) {
    return _then(_SubscriptionPurchaseConfig(
      maxVersion: null == maxVersion
          ? _self.maxVersion
          : maxVersion // ignore: cast_nullable_to_non_nullable
              as String,
      minVersion: null == minVersion
          ? _self.minVersion
          : minVersion // ignore: cast_nullable_to_non_nullable
              as String,
      blacklistedVersions: null == blacklistedVersions
          ? _self._blacklistedVersions
          : blacklistedVersions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

// dart format on
