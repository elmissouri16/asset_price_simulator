// ignore_for_file: avoid_print

import 'dart:async';
import 'package:asset_price_simulator/asset_price_simulator.dart';

/// Demonstrates real-time market simulation using the RealtimeSimulator.
///
/// This example shows how to use tick-based simulation for game economies
/// or real-time trading simulations where you need controlled progression
/// of market data.
void main() async {
  print('=== Real-Time Market Simulation Examples ===\n');

  // Example 1: Basic timer-based updates
  await basicTickExample();

  print('\n${'=' * 60}\n');

  // Example 2: Controlled progression with peeking
  await controlledProgressionExample();

  print('\n${'=' * 60}\n');

  // Example 3: Game-like real-time price updates
  await gameLikeExample();
}

/// Example 1: Basic tick-based simulation with Timer
Future<void> basicTickExample() async {
  print('Example 1: Basic Timer-Based Simulation\n');

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

  print('Starting simulation with ${simulator.total} candlesticks...');
  print('Progress: ${(simulator.progress * 100).toStringAsFixed(0)}%\n');

  var tickCount = 0;
  final timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
    final candle = simulator.nextCandlestick();

    if (candle == null) {
      timer.cancel();
      print('\n✓ Simulation complete!');
      return;
    }

    tickCount++;
    print('  Tick #$tickCount: '
          '${candle.openTime.hour.toString().padLeft(2, '0')}:00 - '
          'Close: \$${candle.close.toStringAsFixed(2)} | '
          'H: \$${candle.high.toStringAsFixed(2)} | '
          'L: \$${candle.low.toStringAsFixed(2)} | '
          'Progress: ${(simulator.progress * 100).toStringAsFixed(0)}%');
  });

  // Wait for simulation to complete
  await Future.delayed(Duration(milliseconds: 500 * (simulator.total + 1)));
}

/// Example 2: Controlled progression with peeking ahead
Future<void> controlledProgressionExample() async {
  print('Example 2: Controlled Progression with Preview\n');

  final config = SimulationConfig(
    initialPrice: 50.0,
    drift: 0.0002,
    volatility: 0.03,
    dataPoints: 15,
    timeInterval: const Duration(minutes: 15),
    outputFormat: OutputFormat.simple,
    includeVolume: true,
    baseVolume: 500000,
    seed: 123,
  );

  final simulator = RealtimeSimulator(config);

  print('Simulating with peek-ahead capability...\n');

  for (var i = 0; i < 5; i++) {
    final current = simulator.nextPrice();
    if (current == null) break;

    // Peek at the next 3 prices without consuming them
    final next1 = simulator.peekPrice(0);
    final next2 = simulator.peekPrice(1);
    final next3 = simulator.peekPrice(2);

    print('Current: \$${current.price.toStringAsFixed(2)}');
    if (next1 != null) {
      print('  Preview +1: \$${next1.price.toStringAsFixed(2)}');
    }
    if (next2 != null) {
      print('  Preview +2: \$${next2.price.toStringAsFixed(2)}');
    }
    if (next3 != null) {
      print('  Preview +3: \$${next3.price.toStringAsFixed(2)}');
    }

    // Predict trend
    if (next1 != null) {
      final trend = next1.price > current.price ? '📈 Up' : '📉 Down';
      print('  Trend: $trend');
    }
    print('');

    await Future.delayed(const Duration(milliseconds: 300));
  }

  print('Remaining points: ${simulator.remaining}');
  print('Can reset and replay: ${simulator.isComplete ? "No" : "Yes"}\n');

  // Demonstrate reset
  simulator.reset();
  print('✓ Simulator reset to beginning');
  print('Has more data: ${simulator.hasMore}');
}

/// Example 3: Game-like real-time updates with price alerts
Future<void> gameLikeExample() async {
  print('Example 3: Game-Like Real-Time Market\n');

  final config = SimulationConfig(
    initialPrice: 1000.0,
    drift: 0.00015,
    volatility: 0.025,
    dataPoints: 20,
    timeInterval: const Duration(seconds: 5),
    outputFormat: OutputFormat.candlestick,
    includeVolume: true,
    baseVolume: 2000000,
    circulatingSupply: 1000000,
    initialTime: DateTime.now(),
    seed: 999,
  );

  final simulator = RealtimeSimulator(config);

  // Game settings
  final priceAlertHigh = 1050.0;
  final priceAlertLow = 950.0;
  var playerBalance = 10000.0;
  var playerShares = 0.0;

  print('🎮 Game Market Simulation Started');
  print('Starting Balance: \$${playerBalance.toStringAsFixed(2)}');
  print('Price Alerts: High \$$priceAlertHigh | Low \$$priceAlertLow\n');

  var updateCount = 0;
  final gameTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
    final candle = simulator.nextCandlestick();

    if (candle == null) {
      timer.cancel();
      print('\n🏁 Market Closed!');
      print('Final Balance: \$${playerBalance.toStringAsFixed(2)}');
      print('Holdings: ${playerShares.toStringAsFixed(2)} shares');
      if (playerShares > 0) {
        print('Portfolio Value: \$${(playerBalance + (playerShares * (simulator.peekCandlestick(-1)?.close ?? 0))).toStringAsFixed(2)}');
      }
      return;
    }

    updateCount++;

    // Display current market state
    var statusLine = '  [$updateCount/${simulator.total}] '
                     '${candle.closeTime.hour.toString().padLeft(2, '0')}:'
                     '${candle.closeTime.minute.toString().padLeft(2, '0')} - '
                     '\$${candle.close.toStringAsFixed(2)}';

    // Check price alerts
    if (candle.close >= priceAlertHigh) {
      statusLine += ' 🔴 HIGH ALERT!';
    } else if (candle.close <= priceAlertLow) {
      statusLine += ' 🟢 LOW ALERT!';
    }

    // Show volume spike
    if (candle.volume > config.baseVolume! * 1.5) {
      statusLine += ' 📊 Volume Spike';
    }

    print(statusLine);

    // Simulate simple trading logic (example only)
    if (updateCount == 5 && playerBalance >= candle.close) {
      // Buy at update 5
      final sharesToBuy = (playerBalance * 0.5) / candle.close;
      playerShares += sharesToBuy;
      playerBalance -= sharesToBuy * candle.close;
      print('    💰 BOUGHT ${sharesToBuy.toStringAsFixed(2)} shares at \$${candle.close.toStringAsFixed(2)}');
    } else if (updateCount == 15 && playerShares > 0) {
      // Sell at update 15
      final saleValue = playerShares * candle.close;
      playerBalance += saleValue;
      print('    💸 SOLD ${playerShares.toStringAsFixed(2)} shares at \$${candle.close.toStringAsFixed(2)}');
      playerShares = 0;
    }
  });

  // Wait for simulation to complete
  await Future.delayed(Duration(milliseconds: 400 * (simulator.total + 1)));
}
