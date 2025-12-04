/// Represents a candlestick (OHLC) data point for charting.
class CandlestickPoint {
  /// The timestamp for the start of this candlestick period.
  final DateTime timestamp;

  /// The opening price for this period.
  final double open;

  /// The highest price during this period.
  final double high;

  /// The lowest price during this period.
  final double low;

  /// The closing price for this period.
  final double close;

  /// The trading volume during this period.
  final double volume;

  /// The circulating supply at the end of this period (optional).
  final double? circulatingSupply;

  /// The market capitalization based on the closing price (optional).
  ///
  /// This is automatically calculated if circulatingSupply is available.
  double? get marketCap {
    if (circulatingSupply != null) {
      return close * circulatingSupply!;
    }
    return null;
  }

  /// Creates a candlestick point.
  const CandlestickPoint({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    this.circulatingSupply,
  });

  /// Creates a CandlestickPoint from a JSON map.
  factory CandlestickPoint.fromJson(Map<String, dynamic> json) {
    return CandlestickPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      circulatingSupply: json['circulatingSupply'] != null
          ? (json['circulatingSupply'] as num).toDouble()
          : null,
    );
  }

  /// Converts this CandlestickPoint to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
      if (circulatingSupply != null) 'circulatingSupply': circulatingSupply,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer('CandlestickPoint(');
    buffer.write('timestamp: $timestamp, ');
    buffer.write('O: ${open.toStringAsFixed(2)}, ');
    buffer.write('H: ${high.toStringAsFixed(2)}, ');
    buffer.write('L: ${low.toStringAsFixed(2)}, ');
    buffer.write('C: ${close.toStringAsFixed(2)}, ');
    buffer.write('V: ${volume.toStringAsFixed(0)}');
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
