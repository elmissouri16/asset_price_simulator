import '../models/candlestick_point.dart';
import '../models/output_format.dart';
import '../models/simple_price_point.dart';
import '../models/simulation_config.dart';
import 'price_simulator.dart';

/// A tick-based real-time simulator that provides controlled, progressive
/// access to simulated market data.
///
/// This simulator pre-generates all data points but exposes them one at a time
/// through [tick], giving you full control over the simulation speed and
/// allowing easy pause/resume functionality.
///
/// Example usage:
/// ```dart
/// final config = SimulationConfig(
///   initialPrice: 100.0,
///   drift: 0.0001,
///   volatility: 0.02,
///   dataPoints: 100,
///   timeInterval: Duration(hours: 1),
///   outputFormat: OutputFormat.candlestick,
///   includeVolume: true,
///   baseVolume: 1000000,
/// );
///
/// final simulator = RealtimeSimulator(config);
///
/// // In your game loop or timer
/// Timer.periodic(Duration(seconds: 1), (timer) {
///   final candle = simulator.nextCandlestick();
///   if (candle == null) {
///     timer.cancel();
///     return;
///   }
///   updateGameUI(candle);
/// });
/// ```
class RealtimeSimulator {
  final SimulationConfig config;
  final List<Object> _allData;
  int _currentIndex = 0;

  /// Creates a real-time simulator with pre-generated data.
  ///
  /// All simulation data is generated immediately upon construction.
  RealtimeSimulator(this.config)
      : _allData = PriceSimulator(config).generate();

  /// Returns the next data point and advances the simulation.
  ///
  /// Returns `null` if all data points have been consumed.
  /// The return type depends on [config.outputFormat]:
  /// - [SimplePricePoint] for [OutputFormat.simple]
  /// - [CandlestickPoint] for [OutputFormat.candlestick]
  Object? tick() {
    if (_currentIndex >= _allData.length) return null;
    return _allData[_currentIndex++];
  }

  /// Returns the next candlestick and advances the simulation.
  ///
  /// Only works if [config.outputFormat] is [OutputFormat.candlestick].
  /// Returns `null` if all data points have been consumed.
  ///
  /// Throws [StateError] if the output format is not candlestick.
  CandlestickPoint? nextCandlestick() {
    if (config.outputFormat != OutputFormat.candlestick) {
      throw StateError(
        'nextCandlestick() requires OutputFormat.candlestick. '
        'Current format: ${config.outputFormat}',
      );
    }
    final data = tick();
    return data as CandlestickPoint?;
  }

  /// Returns the next simple price point and advances the simulation.
  ///
  /// Only works if [config.outputFormat] is [OutputFormat.simple].
  /// Returns `null` if all data points have been consumed.
  ///
  /// Throws [StateError] if the output format is not simple.
  SimplePricePoint? nextPrice() {
    if (config.outputFormat != OutputFormat.simple) {
      throw StateError(
        'nextPrice() requires OutputFormat.simple. '
        'Current format: ${config.outputFormat}',
      );
    }
    final data = tick();
    return data as SimplePricePoint?;
  }

  /// Peeks at upcoming data without advancing the simulation.
  ///
  /// [offset] determines how far ahead to look (0 = current, 1 = next, etc.).
  /// Returns `null` if the requested index is out of bounds.
  Object? peek([int offset = 0]) {
    final index = _currentIndex + offset;
    if (index < 0 || index >= _allData.length) return null;
    return _allData[index];
  }

  /// Peeks at the upcoming candlestick without advancing.
  ///
  /// [offset] determines how far ahead to look (0 = current, 1 = next, etc.).
  /// Returns `null` if the requested index is out of bounds.
  ///
  /// Throws [StateError] if the output format is not candlestick.
  CandlestickPoint? peekCandlestick([int offset = 0]) {
    if (config.outputFormat != OutputFormat.candlestick) {
      throw StateError(
        'peekCandlestick() requires OutputFormat.candlestick. '
        'Current format: ${config.outputFormat}',
      );
    }
    final data = peek(offset);
    return data as CandlestickPoint?;
  }

  /// Peeks at the upcoming price point without advancing.
  ///
  /// [offset] determines how far ahead to look (0 = current, 1 = next, etc.).
  /// Returns `null` if the requested index is out of bounds.
  ///
  /// Throws [StateError] if the output format is not simple.
  SimplePricePoint? peekPrice([int offset = 0]) {
    if (config.outputFormat != OutputFormat.simple) {
      throw StateError(
        'peekPrice() requires OutputFormat.simple. '
        'Current format: ${config.outputFormat}',
      );
    }
    final data = peek(offset);
    return data as SimplePricePoint?;
  }

  /// Resets the simulator to the beginning.
  void reset() {
    _currentIndex = 0;
  }

  /// Skips forward by [count] data points.
  ///
  /// Returns the number of points actually skipped (may be less than [count]
  /// if reaching the end of data).
  int skip(int count) {
    final oldIndex = _currentIndex;
    _currentIndex = (_currentIndex + count).clamp(0, _allData.length);
    return _currentIndex - oldIndex;
  }

  /// Seeks to a specific index in the simulation.
  ///
  /// [index] must be between 0 and [total] - 1.
  /// Throws [RangeError] if the index is out of bounds.
  void seekTo(int index) {
    if (index < 0 || index >= _allData.length) {
      throw RangeError.range(index, 0, _allData.length - 1, 'index');
    }
    _currentIndex = index;
  }

  /// Returns true if there are more data points available.
  bool get hasMore => _currentIndex < _allData.length;

  /// Returns true if all data points have been consumed.
  bool get isComplete => _currentIndex >= _allData.length;

  /// Returns the current position in the simulation (0-indexed).
  int get currentIndex => _currentIndex;

  /// Returns the total number of data points in the simulation.
  int get total => _allData.length;

  /// Returns the number of remaining data points.
  int get remaining => _allData.length - _currentIndex;

  /// Returns the completion progress as a fraction (0.0 to 1.0).
  double get progress => _allData.isEmpty ? 1.0 : _currentIndex / _allData.length;

  /// Returns all remaining data points without consuming them.
  ///
  /// The simulation position is not advanced.
  List<Object> peekRemaining() {
    return _allData.sublist(_currentIndex);
  }

  /// Consumes and returns all remaining data points.
  ///
  /// After calling this, [hasMore] will be false.
  List<Object> consumeRemaining() {
    final remaining = _allData.sublist(_currentIndex);
    _currentIndex = _allData.length;
    return remaining;
  }
}
