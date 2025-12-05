// ignore_for_file: avoid_print

import 'package:asset_price_simulator/asset_price_simulator.dart';

/// Demonstrates Stream-based real-time simulation.
///
/// This example shows how to use reactive Streams for market data,
/// which is perfect for Flutter apps, async patterns, and reactive UIs.
void main() async {
  print('=== Stream-Based Market Simulation ===\n');

  // Example 1: Basic candlestick stream
  await basicCandlestickStream();

  print('\n${'=' * 60}\n');

  // Example 2: Price stream with listeners
  await priceStreamWithListeners();

  print('\n${'=' * 60}\n');

  // Example 3: Multiple subscribers
  await multipleSubscribers();
}

/// Example 1: Basic candlestick stream
Future<void> basicCandlestickStream() async {
  print('Example 1: Basic Candlestick Stream\n');

  final config = SimulationConfig(
    initialPrice: 100.0,
    drift: 0.0001,
    volatility: 0.02,
    dataPoints: 10,
    timeInterval: const Duration(hours: 1),
    outputFormat: OutputFormat.candlestick,
    includeVolume: true,
    baseVolume: 1000000,
    initialTime: DateTime(2024, 1, 1, 9, 0),
    seed: 42,
  );

  final simulator = RealtimeSimulator(config);

  print('Streaming candlesticks every 300ms...\n');

  await for (final candle in simulator.candlestickStream(
    interval: const Duration(milliseconds: 300),
  )) {
    print('  ${candle.openTime.hour.toString().padLeft(2, '0')}:00 - '
          'Close: \$${candle.close.toStringAsFixed(2)} | '
          'H: \$${candle.high.toStringAsFixed(2)} | '
          'L: \$${candle.low.toStringAsFixed(2)}');
  }

  print('\n✓ Stream completed');
}

/// Example 2: Price stream with event handling
Future<void> priceStreamWithListeners() async {
  print('Example 2: Price Stream with Event Handlers\n');

  final config = SimulationConfig(
    initialPrice: 50.0,
    drift: 0.0002,
    volatility: 0.03,
    dataPoints: 8,
    timeInterval: const Duration(minutes: 15),
    outputFormat: OutputFormat.simple,
    includeVolume: true,
    baseVolume: 500000,
    seed: 123,
  );

  final simulator = RealtimeSimulator(config);

  var highestPrice = 0.0;
  var lowestPrice = double.infinity;
  var count = 0;

  await simulator.priceStream(
    interval: const Duration(milliseconds: 250),
  ).listen(
    (price) {
      count++;
      if (price.price > highestPrice) highestPrice = price.price;
      if (price.price < lowestPrice) lowestPrice = price.price;

      print('  #$count: \$${price.price.toStringAsFixed(2)} | '
            'Vol: \$${(price.volume! / 1000).toStringAsFixed(0)}K');
    },
    onDone: () {
      print('\n📊 Summary:');
      print('  Highest: \$${highestPrice.toStringAsFixed(2)}');
      print('  Lowest: \$${lowestPrice.toStringAsFixed(2)}');
      print('  Range: \$${(highestPrice - lowestPrice).toStringAsFixed(2)}');
    },
    onError: (error) {
      print('❌ Error: $error');
    },
  ).asFuture();
}

/// Example 3: Multiple subscribers with broadcast stream
Future<void> multipleSubscribers() async {
  print('Example 3: Multiple Subscribers (Broadcast Stream)\n');

  final config = SimulationConfig(
    initialPrice: 1000.0,
    drift: 0.00015,
    volatility: 0.025,
    dataPoints: 6,
    timeInterval: const Duration(seconds: 5),
    outputFormat: OutputFormat.candlestick,
    includeVolume: true,
    baseVolume: 2000000,
    circulatingSupply: 1000000,
    seed: 999,
  );

  final simulator = RealtimeSimulator(config);

  // Convert to broadcast stream for multiple subscribers
  final broadcastStream = simulator.candlestickStream(
    interval: const Duration(milliseconds: 400),
  ).asBroadcastStream();

  // Subscriber 1: Price tracker
  broadcastStream.listen((candle) {
    print('  📈 Price Tracker: \$${candle.close.toStringAsFixed(2)}');
  });

  // Subscriber 2: Volume tracker
  broadcastStream.listen((candle) {
    final volumeInM = (candle.volume / 1000000).toStringAsFixed(1);
    print('  📊 Volume Tracker: \$${volumeInM}M');
  });

  // Subscriber 3: Market cap tracker
  broadcastStream.listen((candle) {
    if (candle.marketCap != null) {
      final mcapInM = (candle.marketCap! / 1000000).toStringAsFixed(1);
      print('  💰 MarketCap Tracker: \$${mcapInM}M');
    }
  });

  // Wait for stream to complete
  await broadcastStream.last;

  print('\n✓ All subscribers completed');
}
