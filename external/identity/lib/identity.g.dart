// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubscriptionPurchaseConfig _$SubscriptionPurchaseConfigFromJson(
        Map<String, dynamic> json) =>
    _SubscriptionPurchaseConfig(
      maxVersion: json['max_version'] as String,
      minVersion: json['min_version'] as String,
      blacklistedVersions: (json['blacklisted_versions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SubscriptionPurchaseConfigToJson(
        _SubscriptionPurchaseConfig instance) =>
    <String, dynamic>{
      'max_version': instance.maxVersion,
      'min_version': instance.minVersion,
      'blacklisted_versions': instance.blacklistedVersions,
    };
