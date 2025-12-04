/// Represents a simple price data point with timestamp and optional metadata.
class SimplePricePoint {
  /// The timestamp when this price point was recorded.
  final DateTime timestamp;

  /// The asset price at this timestamp.
  final double price;

  /// The trading volume at this timestamp (optional).
  final double? volume;

  /// The circulating supply at this timestamp (optional).
  final double? circulatingSupply;

  /// The market capitalization (price × supply) at this timestamp (optional).
  ///
  /// This is automatically calculated if both price and circulatingSupply are available.
  double? get marketCap {
    if (circulatingSupply != null) {
      return price * circulatingSupply!;
    }
    return null;
  }

  /// Creates a simple price point.
  const SimplePricePoint({
    required this.timestamp,
    required this.price,
    this.volume,
    this.circulatingSupply,
  });

  /// Creates a SimplePricePoint from a JSON map.
  factory SimplePricePoint.fromJson(Map<String, dynamic> json) {
    return SimplePricePoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      price: (json['price'] as num).toDouble(),
      volume: json['volume'] != null ? (json['volume'] as num).toDouble() : null,
      circulatingSupply: json['circulatingSupply'] != null
          ? (json['circulatingSupply'] as num).toDouble()
          : null,
    );
  }

  /// Converts this SimplePricePoint to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'price': price,
      if (volume != null) 'volume': volume,
      if (circulatingSupply != null) 'circulatingSupply': circulatingSupply,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer('SimplePricePoint(');
    buffer.write('timestamp: $timestamp, ');
    buffer.write('price: ${price.toStringAsFixed(2)}');
    if (volume != null) buffer.write(', volume: ${volume!.toStringAsFixed(0)}');
    if (circulatingSupply != null) {
      buffer.write(', supply: ${circulatingSupply!.toStringAsFixed(0)}');
    }
    if (marketCap != null) {
      buffer.write(', marketCap: ${marketCap!.toStringAsFixed(0)}');
    }
    buffer.write(')');
    return buffer.toString();
  }
}
