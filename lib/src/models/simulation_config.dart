import 'output_format.dart';
import 'price_range.dart';

/// Configuration for price simulation.
class SimulationConfig {
  /// The initial price to start simulation from.
  final double initialPrice;

  /// The drift (trend) rate. Positive = upward bias, negative = downward bias.
  ///
  /// Typical values: 0.0001 to 0.001 for crypto, 0.00001 to 0.0001 for stocks.
  final double drift;

  /// The volatility (amount of randomness).
  ///
  /// Typical values: 0.01-0.05 (1%-5%) for stocks, 0.02-0.10 (2%-10%) for crypto.
  final double volatility;

  /// Optional price range constraints.
  final PriceRange? priceRange;

  /// The number of data points to generate.
  final int dataPoints;

  /// The time interval between each data point.
  final Duration timeInterval;

  /// The output format (simple or candlestick).
  final OutputFormat outputFormat;

  /// Whether to include volume simulation.
  final bool includeVolume;

  /// The base (average) trading volume. Only used if includeVolume is true.
  final double? baseVolume;

  /// The volume volatility (relative variation in volume).
  ///
  /// Typical values: 0.3-0.6 (30%-60% variation).
  final double volumeVolatility;

  /// The circulating supply for market cap calculations (optional).
  ///
  /// Can be a static value or will grow/shrink based on supplyGrowthRate.
  final double? circulatingSupply;

  /// The supply growth rate per time period (optional).
  ///
  /// Positive = inflationary, negative = deflationary, 0 or null = static.
  /// Example: 0.0001 = 0.01% growth per period.
  final double? supplyGrowthRate;

  /// Optional random seed for reproducible results.
  final int? seed;

  /// The initial timestamp for the first data point.
  /// 
  /// If not specified, defaults to the current time when the simulator runs.
  final DateTime? initialTime;

  /// Creates a simulation configuration.
  const SimulationConfig({
    required this.initialPrice,
    required this.drift,
    required this.volatility,
    required this.dataPoints,
    required this.timeInterval,
    this.priceRange,
    this.outputFormat = OutputFormat.simple,
    this.includeVolume = false,
    this.baseVolume,
    this.volumeVolatility = 0.4,
    this.circulatingSupply,
    this.supplyGrowthRate,
    this.seed,
    this.initialTime,
  }) : assert(initialPrice > 0, 'Initial price must be positive'),
       assert(volatility >= 0, 'Volatility must be non-negative'),
       assert(dataPoints > 0, 'Data points must be positive'),
       assert(!includeVolume || baseVolume != null, 
              'Base volume must be provided when includeVolume is true'),
       assert(volumeVolatility >= 0, 'Volume volatility must be non-negative');

  /// Creates a SimulationConfig from a JSON map.
  factory SimulationConfig.fromJson(Map<String, dynamic> json) {
    return SimulationConfig(
      initialPrice: (json['initialPrice'] as num).toDouble(),
      drift: (json['drift'] as num).toDouble(),
      volatility: (json['volatility'] as num).toDouble(),
      dataPoints: json['dataPoints'] as int,
      timeInterval: Duration(microseconds: json['timeIntervalMicros'] as int),
      priceRange: json['priceRange'] != null
          ? PriceRange(
              min: (json['priceRange']['min'] as num).toDouble(),
              max: (json['priceRange']['max'] as num).toDouble(),
            )
          : null,
      outputFormat: OutputFormat.values.firstWhere(
        (e) => e.name == json['outputFormat'],
        orElse: () => OutputFormat.simple,
      ),
      includeVolume: json['includeVolume'] as bool? ?? false,
      baseVolume: json['baseVolume'] != null
          ? (json['baseVolume'] as num).toDouble()
          : null,
      volumeVolatility:
          (json['volumeVolatility'] as num?)?.toDouble() ?? 0.4,
      circulatingSupply: json['circulatingSupply'] != null
          ? (json['circulatingSupply'] as num).toDouble()
          : null,
      supplyGrowthRate: json['supplyGrowthRate'] != null
          ? (json['supplyGrowthRate'] as num).toDouble()
          : null,
      seed: json['seed'] as int?,
      initialTime: json['initialTime'] != null
          ? DateTime.parse(json['initialTime'] as String)
          : null,
    );
  }

  /// Converts this SimulationConfig to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'initialPrice': initialPrice,
      'drift': drift,
      'volatility': volatility,
      'dataPoints': dataPoints,
      'timeIntervalMicros': timeInterval.inMicroseconds,
      if (priceRange != null)
        'priceRange': {
          'min': priceRange!.min,
          'max': priceRange!.max,
        },
      'outputFormat': outputFormat.name,
      'includeVolume': includeVolume,
      if (baseVolume != null) 'baseVolume': baseVolume,
      'volumeVolatility': volumeVolatility,
      if (circulatingSupply != null) 'circulatingSupply': circulatingSupply,
      if (supplyGrowthRate != null) 'supplyGrowthRate': supplyGrowthRate,
      if (seed != null) 'seed': seed,
      if (initialTime != null) 'initialTime': initialTime!.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SimulationConfig(initialPrice: $initialPrice, drift: $drift, '
           'volatility: $volatility, dataPoints: $dataPoints, '
           'timeInterval: $timeInterval, outputFormat: $outputFormat)';
  }
}
