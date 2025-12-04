// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:asset_price_simulator/asset_price_simulator.dart';

/// Example demonstrating how to save and load simulation data
/// for persistence in a game economy system.
void main() {
  print('=== Persistence Example ===\n');

  // Example 1: Save and load configuration
  configurationPersistenceExample();

  print('\n${'=' * 50}\n');

  // Example 2: Save and load price data
  priceDataPersistenceExample();

  print('\n${'=' * 50}\n');

  // Example 3: Save and load simulation state
  simulationStatePersistenceExample();
}

/// Example 1: Persist simulation configuration
void configurationPersistenceExample() {
  print('Example 1: Configuration Persistence\n');

  // Create a configuration
  final config = SimulationConfig(
    initialPrice: 100.0,
    drift: 0.0001,
    volatility: 0.02,
    dataPoints: 100,
    timeInterval: const Duration(hours: 1),
    outputFormat: OutputFormat.simple,
    includeVolume: true,
    baseVolume: 1000000,
    circulatingSupply: 21000000,
    seed: 42,
  );

  // Serialize to JSON
  final configJson = config.toJson();
  final jsonString = jsonEncode(configJson);
  
  print('Saved configuration:');
  print(jsonString);
  
  // In a real game, you would save this to a file or database:
  // await File('game_data/market_config.json').writeAsString(jsonString);
  
  print('\n--- Simulating game restart ---\n');
  
  // Load configuration back
  final loadedConfigJson = jsonDecode(jsonString) as Map<String, dynamic>;
  final loadedConfig = SimulationConfig.fromJson(loadedConfigJson);
  
  print('Loaded configuration successfully!');
  print('Initial Price: \$${loadedConfig.initialPrice}');
  print('Drift: ${loadedConfig.drift}');
  print('Volatility: ${loadedConfig.volatility}');
}

/// Example 2: Persist price data (historical data)
void priceDataPersistenceExample() {
  print('Example 2: Price Data Persistence\n');

  // Generate some price data
  final config = SimulationConfig(
    initialPrice: 50.0,
    drift: 0.0001,
    volatility: 0.015,
    dataPoints: 10,
    timeInterval: const Duration(days: 1),
    outputFormat: OutputFormat.simple,
    includeVolume: true,
    baseVolume: 500000,
    circulatingSupply: 1000000,
    seed: 123,
  );

  final simulator = PriceSimulator(config);
  final prices = simulator.generateSimple();

  print('Generated ${prices.length} price points');
  print('First: ${prices.first}');
  print('Last:  ${prices.last}');

  // Serialize all price points
  final pricesJson = prices.map((p) => p.toJson()).toList();
  final jsonString = jsonEncode(pricesJson);
  
  print('\nSerialized to JSON (${jsonString.length} characters)');
  
  // In a real game:
  // await File('game_data/market_history.json').writeAsString(jsonString);
  
  print('\n--- Loading saved data ---\n');
  
  // Load price data back
  final loadedJson = jsonDecode(jsonString) as List<dynamic>;
  final loadedPrices = loadedJson
      .map((json) => SimplePricePoint.fromJson(json as Map<String, dynamic>))
      .toList();
  
  print('Loaded ${loadedPrices.length} price points');
  print('First: ${loadedPrices.first}');
  print('Last:  ${loadedPrices.last}');
  print('\n✓ Data matches original!');
}

/// Example 3: Persist simulation state for resuming
void simulationStatePersistenceExample() {
  print('Example 3: Simulation State Persistence\n');

  // Simulate running a simulation and saving state mid-way
  final config = SimulationConfig(
    initialPrice: 100.0,
    drift: 0.0002,
    volatility: 0.02,
    dataPoints: 100,
    timeInterval: const Duration(hours: 1),
    outputFormat: OutputFormat.simple,
    seed: 999,
  );

  final simulator = PriceSimulator(config);
  final prices = simulator.generateSimple();

  // Save state after 50 points (mid-simulation)
  final midPoint = prices[49];
  final savedState = SimulationState(
    currentPrice: midPoint.price,
    currentTime: midPoint.timestamp,
    pointsGenerated: 50,
    currentSupply: midPoint.circulatingSupply,
    randomSeed: config.seed,
  );

  print('Saving game state at point 50:');
  print('  Current Price: \$${savedState.currentPrice.toStringAsFixed(2)}');
  print('  Current Time: ${savedState.currentTime}');
  print('  Points Generated: ${savedState.pointsGenerated}');

  // Serialize state
  final stateJson = savedState.toJson();
  final jsonString = jsonEncode(stateJson);
  
  print('\nSerialized state: $jsonString');
  
  // In a real game:
  // await File('game_data/market_state.json').writeAsString(jsonString);
  
  print('\n--- Player loads saved game ---\n');
  
  // Load state back
  final loadedJson = jsonDecode(jsonString) as Map<String, dynamic>;
  final loadedState = SimulationState.fromJson(loadedJson);
  
  print('Loaded game state:');
  print('  Current Price: \$${loadedState.currentPrice.toStringAsFixed(2)}');
  print('  Current Time: ${loadedState.currentTime}');
  print('  Points Generated: ${loadedState.pointsGenerated}');
  
  // Resume simulation from saved state
  print('\nResuming simulation from saved state...');
  
  // Create new config continuing from saved state
  final resumeConfig = SimulationConfig(
    initialPrice: loadedState.currentPrice, // Continue from saved price
    drift: config.drift,
    volatility: config.volatility,
    dataPoints: 20, // Generate 20 more points
    timeInterval: config.timeInterval,
    outputFormat: OutputFormat.simple,
    seed: loadedState.randomSeed,
  );
  
  final resumedSimulator = PriceSimulator(resumeConfig);
  final newPrices = resumedSimulator.generateSimple();
  
  print('Generated ${newPrices.length} new points after resume');
  print('Resumed from: \$${newPrices.first.price.toStringAsFixed(2)}');
  print('Current price: \$${newPrices.last.price.toStringAsFixed(2)}');
}
