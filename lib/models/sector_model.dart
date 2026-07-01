import 'dart:convert';

class SectorModel {
  final int id;
  final String name;
  final String slug;
  final String icon;
  final bool isEnabled;
  final Map<String, dynamic>? schemaDefinition;
  final List<ServiceModel> services;

  SectorModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    required this.isEnabled,
    this.schemaDefinition,
    required this.services,
  });

  factory SectorModel.fromJson(Map<String, dynamic> json) {
    return SectorModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'] ?? '',
      isEnabled: json['is_enabled'] == 1 || json['is_enabled'] == true,
      schemaDefinition: json['schema_definition'] != null 
          ? Map<String, dynamic>.from(json['schema_definition']) 
          : null,
      services: json['services'] != null
          ? List<ServiceModel>.from(
              json['services'].map((x) => ServiceModel.fromJson(x)))
          : [],
    );
  }
}

class ServiceModel {
  final int id;
  final int sectorId;
  final String name;
  final String slug;
  final double price;
  final bool isActive;
  final Map<String, dynamic>? config;
  final List<String>? features;

  ServiceModel({
    required this.id,
    required this.sectorId,
    required this.name,
    required this.slug,
    required this.price,
    required this.isActive,
    this.config,
    this.features,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? 0,
      sectorId: json['sector_id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      config: json['config'] != null ? Map<String, dynamic>.from(json['config']) : null,
      features: json['features'] != null ? List<String>.from(json['features']) : null,
    );
  }
}
