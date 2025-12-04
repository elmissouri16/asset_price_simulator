/// Represents the current state of a price simulation.
/// 
/// This class captures all the information needed to pause and resume
/// a simulation, making it useful for game persistence.
class SimulationState {
  /// The current price in the simulation.
  final double currentPrice;

  /// The current circulating supply (if applicable).
  final double? currentSupply;

  /// The current timestamp in the simulation.
  final DateTime currentTime;

  /// The number of data points generated so far.
  final int pointsGenerated;

  /// Optional: The random seed state for reproducibility.
  /// 
  /// Note: This is a simplified approach. For true reproducibility,
  /// you'd need to save the full random generator state.
  final int? randomSeed;

  /// Creates a simulation state.
  const SimulationState({
    required this.currentPrice,
    required this.currentTime,
    required this.pointsGenerated,
    this.currentSupply,
    this.randomSeed,
  });

  /// Creates a SimulationState from a JSON map.
  factory SimulationState.fromJson(Map<String, dynamic> json) {
    return SimulationState(
      currentPrice: (json['currentPrice'] as num).toDouble(),
      currentTime: DateTime.parse(json['currentTime'] as String),
      pointsGenerated: json['pointsGenerated'] as int,
      currentSupply: json['currentSupply'] != null
          ? (json['currentSupply'] as num).toDouble()
          : null,
      randomSeed: json['randomSeed'] as int?,
    );
  }

  /// Converts this SimulationState to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'currentPrice': currentPrice,
      'currentTime': currentTime.toIso8601String(),
      'pointsGenerated': pointsGenerated,
      if (currentSupply != null) 'currentSupply': currentSupply,
      if (randomSeed != null) 'randomSeed': randomSeed,
    };
  }

  @override
  String toString() {
    return 'SimulationState(price: $currentPrice, time: $currentTime, '
           'points: $pointsGenerated)';
  }
}
