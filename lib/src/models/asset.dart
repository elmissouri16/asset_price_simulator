import 'simulation_config.dart';
import 'simple_price_point.dart';
import 'candlestick_point.dart';

/// Represents a complete asset with its configuration, history, and current state.
/// 
/// This is a convenience class for game persistence - it bundles everything
/// you need to save and resume a simulation.
class Asset {
  /// Unique identifier for this asset (e.g., "BTC", "AAPL", "asset_1").
  final String id;

  /// Display name for this asset (e.g., "Bitcoin", "Apple Inc.").
  final String name;

  /// The simulation configuration for this asset.
  final SimulationConfig config;

  /// Historical price data (can be empty for new assets).
  final List<SimplePricePoint> priceHistory;

  /// Optional: Last known price for quick access.
  final double? currentPrice;

  /// Optional: Last known supply for quick access.
  final double? currentSupply;

  /// Optional: Timestamp of last update.
  final DateTime? lastUpdated;

  /// Creates an asset.
  const Asset({
    required this.id,
    required this.name,
    required this.config,
    this.priceHistory = const [],
    this.currentPrice,
    this.currentSupply,
    this.lastUpdated,
  });

  /// Creates a new asset with initial configuration.
  factory Asset.create({
    required String id,
    required String name,
    required SimulationConfig config,
  }) {
    return Asset(
      id: id,
      name: name,
      config: config,
      priceHistory: [],
      currentPrice: config.initialPrice,
      currentSupply: config.circulatingSupply,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates an Asset from a JSON map.
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      name: json['name'] as String,
      config: SimulationConfig.fromJson(
        json['config'] as Map<String, dynamic>,
      ),
      priceHistory: (json['priceHistory'] as List<dynamic>?)
              ?.map((p) => SimplePricePoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      currentPrice: json['currentPrice'] != null
          ? (json['currentPrice'] as num).toDouble()
          : null,
      currentSupply: json['currentSupply'] != null
          ? (json['currentSupply'] as num).toDouble()
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  /// Converts this Asset to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'config': config.toJson(),
      'priceHistory': priceHistory.map((p) => p.toJson()).toList(),
      if (currentPrice != null) 'currentPrice': currentPrice,
      if (currentSupply != null) 'currentSupply': currentSupply,
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
    };
  }

  /// Creates a copy of this asset with updated values.
  Asset copyWith({
    String? id,
    String? name,
    SimulationConfig? config,
    List<SimplePricePoint>? priceHistory,
    double? currentPrice,
    double? currentSupply,
    DateTime? lastUpdated,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      config: config ?? this.config,
      priceHistory: priceHistory ?? this.priceHistory,
      currentPrice: currentPrice ?? this.currentPrice,
      currentSupply: currentSupply ?? this.currentSupply,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Updates this asset with new price points and current state.
  Asset addPricePoints(List<SimplePricePoint> newPoints) {
    if (newPoints.isEmpty) return this;

    final updated = [...priceHistory, ...newPoints];
    final latest = newPoints.last;

    return copyWith(
      priceHistory: updated,
      currentPrice: latest.price,
      currentSupply: latest.circulatingSupply ?? currentSupply,
      lastUpdated: latest.timestamp,
    );
  }

  /// Gets a resumable config that continues from the current state.
  /// 
  /// This allows seamless continuation of the simulation.
  SimulationConfig getResumeConfig({int? additionalPoints}) {
    return SimulationConfig(
      initialPrice: currentPrice ?? config.initialPrice,
      drift: config.drift,
      volatility: config.volatility,
      dataPoints: additionalPoints ?? config.dataPoints,
      timeInterval: config.timeInterval,
      priceRange: config.priceRange,
      outputFormat: config.outputFormat,
      includeVolume: config.includeVolume,
      baseVolume: config.baseVolume,
      volumeVolatility: config.volumeVolatility,
      circulatingSupply: currentSupply ?? config.circulatingSupply,
      supplyGrowthRate: config.supplyGrowthRate,
      seed: config.seed,
    );
  }

  @override
  String toString() {
    return 'Asset($id: $name, price: \$${currentPrice?.toStringAsFixed(2) ?? "N/A"}, '
           'history: ${priceHistory.length} points)';
  }
}
