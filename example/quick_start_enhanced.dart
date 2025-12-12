// ignore_for_file: avoid_print

import 'package:asset_price_simulator/asset_price_simulator.dart';

/// Quick example showing the most common enhanced candlestick usage.
void main() {
  print('=== Quick Start: Enhanced Candlestick Simulation ===\n');

  // Basic configuration with enhanced realism
  final config = SimulationConfig(
    initialPrice: 100.0,
    drift: 0.0001,
    volatility: 0.03,
    dataPoints: 5,
    timeInterval: const Duration(hours: 1),
    outputFormat: OutputFormat.candlestick,
    includeVolume: true,
    baseVolume: 1000000,
    
    // NEW: Control realism level (default is 10)
    intraCandleTicks: 20, // More accurate high/low detection
    
    // NEW: Capture intra-period price movements (optional)
    includeIntraPeriodData: true, // Enable tick-by-tick data
    
    seed: 42,
  );

  final simulator = PriceSimulator(config);
  final candles = simulator.generateCandlesticks();

  print('Generated ${candles.length} enhanced candles:\n');

  for (var i = 0; i < candles.length; i++) {
    final candle = candles[i];
    
    print('Candle ${i + 1}:');
    print('  OHLC: O=\$${candle.open.toStringAsFixed(2)}, '
          'H=\$${candle.high.toStringAsFixed(2)}, '
          'L=\$${candle.low.toStringAsFixed(2)}, '
          'C=\$${candle.close.toStringAsFixed(2)}');
    
    // NEW: Check if intra-period data is available
    if (candle.hasIntraPeriodData) {
      print('  Intra-period: ${candle.intraPeriodCount} ticks available');
      print('  First tick: \$${candle.intraPeriodPrices!.first.toStringAsFixed(2)}');
      print('  Last tick:  \$${candle.intraPeriodPrices!.last.toStringAsFixed(2)}');
    }
    print('');
  }

  print('✓ Done! Candles include intra-period price movements.');
  print('\nTo use without intra-period data (saves memory):');
  print('  - Set includeIntraPeriodData: false');
  print('  - You still get accurate high/low from intraCandleTicks\n');
}
