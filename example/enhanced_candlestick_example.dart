// ignore_for_file: avoid_print

import 'package:asset_price_simulator/asset_price_simulator.dart';

/// Demonstrates enhanced candlestick simulation with intra-period data.
///
/// This example shows:
/// 1. Backward compatible default behavior
/// 2. Enhanced candlesticks with intra-period price movements
/// 3. Real-time candle formation simulation
/// 4. Different realism levels (tick counts)
void main() {
  print('=== Enhanced Candlestick Simulation Examples ===\n');

  example1_backwardCompatible();
  print('\n${'=' * 70}\n');

  example2_intraPeriodData();
  print('\n${'=' * 70}\n');

  example3_realtimeCandleFormation();
  print('\n${'=' * 70}\n');

  example4_realismLevels();
}

/// Example 1: Default behavior (backward compatible)
void example1_backwardCompatible() {
  print('Example 1: Default Behavior (Backward Compatible)\n');

  final config = SimulationConfig(
    initialPrice: 100.0,
    drift: 0.0001,
    volatility: 0.02,
    dataPoints: 5,
    timeInterval: const Duration(hours: 1),
    outputFormat: OutputFormat.candlestick,
    includeVolume: true,
    baseVolume: 1000000,
    initialTime: DateTime(2024, 1, 1, 9, 0),
    seed: 42,
  );

  final simulator = PriceSimulator(config);
  final candles = simulator.generateCandlesticks();

  print('Generated ${candles.length} candles with default settings:');
  print('- intraCandleTicks: ${config.intraCandleTicks} (default)');
  print('- includeIntraPeriodData: ${config.includeIntraPeriodData} (default)\n');

  for (final candle in candles) {
    print('${candle.openTime.hour.toString().padLeft(2, '0')}:00 - '
          'O: \$${candle.open.toStringAsFixed(2)} | '
          'H: \$${candle.high.toStringAsFixed(2)} | '
          'L: \$${candle.low.toStringAsFixed(2)} | '
          'C: \$${candle.close.toStringAsFixed(2)} | '
          'Vol: ${(candle.volume / 1000000).toStringAsFixed(2)}M');
  }

  print('\n✓ Traditional OHLCV data only (no intra-period tracking)');
}

/// Example 2: Capturing intra-period price movements
void example2_intraPeriodData() {
  print('Example 2: Enhanced Candlesticks with Intra-Period Data\n');

  final config = SimulationConfig(
    initialPrice: 100.0,
    drift: 0.0002,
    volatility: 0.03,
    dataPoints: 3,
    timeInterval: const Duration(hours: 1),
    outputFormat: OutputFormat.candlestick,
    includeVolume: true,
    baseVolume: 2000000,
    intraCandleTicks: 12, // One tick every 5 minutes
    includeIntraPeriodData: true, // Enable intra-period tracking
    initialTime: DateTime(2024, 1, 1, 10, 0),
    seed: 123,
  );

  final simulator = PriceSimulator(config);
  final candles = simulator.generateCandlesticks();

  print('Generated ${candles.length} candles with intra-period tracking:');
  print('- intraCandleTicks: ${config.intraCandleTicks}');
  print('- includeIntraPeriodData: ${config.includeIntraPeriodData}\n');

  for (var i = 0; i < candles.length; i++) {
    final candle = candles[i];
    print('Candle #${i + 1} (${candle.openTime.hour}:00 - ${candle.closeTime.hour}:00)');
    print('  OHLC: O=\$${candle.open.toStringAsFixed(2)}, '
          'H=\$${candle.high.toStringAsFixed(2)}, '
          'L=\$${candle.low.toStringAsFixed(2)}, '
          'C=\$${candle.close.toStringAsFixed(2)}');
    print('  Has ${candle.intraPeriodCount} intra-period ticks\n');

    if (candle.hasIntraPeriodData) {
      print('  Tick-by-tick price movement:');
      for (var j = 0; j < candle.intraPeriodCount; j++) {
        final price = candle.intraPeriodPrices![j];
        final time = candle.intraPeriodTimestamps![j];
        final marker = j == 0 ? '→' : j == candle.intraPeriodCount - 1 ? '●' : ' ';
        print('    $marker ${time.hour}:${time.minute.toString().padLeft(2, '0')} '
              '- \$${price.toStringAsFixed(2)}');
      }
      print('');
    }
  }

  print('✓ Full price path captured for each candle');
}

/// Example 3: Simulating real-time candle formation
void example3_realtimeCandleFormation() {
  print('Example 3: Real-Time Candle Formation Simulation\n');

  final config = SimulationConfig(
    initialPrice: 1000.0,
    drift: 0.00015,
    volatility: 0.025,
    dataPoints: 2,
    timeInterval: const Duration(minutes: 30),
    outputFormat: OutputFormat.candlestick,
    includeVolume: true,
    baseVolume: 5000000,
    intraCandleTicks: 6, // 6 ticks = one every 5 minutes
    includeIntraPeriodData: true,
    initialTime: DateTime(2024, 6, 15, 14, 0),
    seed: 999,
  );

  final simulator = PriceSimulator(config);
  final candles = simulator.generateCandlesticks();

  print('Simulating live candle formation (2 candles, 6 ticks each):\n');

  for (var candleIdx = 0; candleIdx < candles.length; candleIdx++) {
    final candle = candles[candleIdx];
    
    print('━━━ Candle ${candleIdx + 1} Opening ━━━');
    print('Time: ${candle.openTime.hour}:${candle.openTime.minute.toString().padLeft(2, '0')}');
    print('Open: \$${candle.open.toStringAsFixed(2)}\n');

    // Simulate tick-by-tick updates
    var currentHigh = candle.open;
    var currentLow = candle.open;

    if (candle.hasIntraPeriodData) {
      for (var tickIdx = 0; tickIdx < candle.intraPeriodCount; tickIdx++) {
        final price = candle.intraPeriodPrices![tickIdx];
        final time = candle.intraPeriodTimestamps![tickIdx];
        
        currentHigh = price > currentHigh ? price : currentHigh;
        currentLow = price < currentLow ? price : currentLow;

        final priceChange = price - candle.open;
        final changeSymbol = priceChange >= 0 ? '▲' : '▼';
        final changePercent = (priceChange / candle.open * 100).abs();

        print('  Tick ${tickIdx + 1}/6 @ ${time.hour}:${time.minute.toString().padLeft(2, '0')} '
              '→ \$${price.toStringAsFixed(2)} $changeSymbol ${changePercent.toStringAsFixed(2)}%');
        print('    Current: H=\$${currentHigh.toStringAsFixed(2)} '
              'L=\$${currentLow.toStringAsFixed(2)}');
      }
    }

    print('\n━━━ Candle ${candleIdx + 1} Closed ━━━');
    print('Time: ${candle.closeTime.hour}:${candle.closeTime.minute.toString().padLeft(2, '0')}');
    print('Close: \$${candle.close.toStringAsFixed(2)}');
    print('Final: H=\$${candle.high.toStringAsFixed(2)} L=\$${candle.low.toStringAsFixed(2)}');
    print('Range: \$${(candle.high - candle.low).toStringAsFixed(2)}\n');
  }

  print('✓ Real-time candle formation simulated');
}

/// Example 4: Comparing different realism levels
void example4_realismLevels() {
  print('Example 4: Effect of Different Realism Levels\n');

  final tickCounts = [5, 10, 50, 100];
  final results = <String, Map<String, double>>{};

  for (final ticks in tickCounts) {
    final config = SimulationConfig(
      initialPrice: 100.0,
      drift: 0.0001,
      volatility: 0.04, // Higher volatility shows difference better
      dataPoints: 20,
      timeInterval: const Duration(hours: 1),
      outputFormat: OutputFormat.candlestick,
      includeVolume: true,
      baseVolume: 1000000,
      intraCandleTicks: ticks,
      seed: 777, // Same seed for fair comparison
    );

    final candles = PriceSimulator(config).generateCandlesticks();
    
    // Calculate statistics
    final ranges = candles.map((c) => c.high - c.low).toList();
    final avgRange = ranges.reduce((a, b) => a + b) / ranges.length;
    final maxRange = ranges.reduce((a, b) => a > b ? a : b);
    
    results['$ticks ticks'] = {
      'avgRange': avgRange,
      'maxRange': maxRange,
    };
  }

  print('Comparing 20 candles with different tick counts:\n');
  print('${'Tick Count'.padRight(15)} | ${'Avg Range'.padRight(12)} | ${'Max Range'.padRight(12)}');
  print('${'-' * 15}-+-${'-' * 12}-+-${'-' * 12}');

  for (final entry in results.entries) {
    final label = entry.key.padRight(15);
    final avg = '\$${entry.value['avgRange']!.toStringAsFixed(3)}'.padRight(12);
    final max = '\$${entry.value['maxRange']!.toStringAsFixed(3)}'.padRight(12);
    print('$label | $avg | $max');
  }

  print('\n💡 Key takeaway:');
  print('   - More ticks = better high/low accuracy (capture more extremes)');
  print('   - Fewer ticks = faster generation (less computation)');
  print('   - Default (10 ticks) offers good balance\n');

  print('✓ Realism levels compared');
}
