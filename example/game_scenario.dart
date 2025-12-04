// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:asset_price_simulator/asset_price_simulator.dart';

/// Example demonstrating the Asset class for game scenarios.
/// 
/// This shows how to:
/// 1. Create assets
/// 2. Generate and save price data
/// 3. Load and resume seamlessly
void main() {
  print('=== Game Asset Management Example ===\n');

  // Step 1: Create a new asset (first time)
  print('--- Creating new Bitcoin asset ---\n');
  
  final bitcoin = Asset.create(
    id: 'btc',
    name: 'Bitcoin',
    config: SimulationConfig(
      initialPrice: 50000.0,
      drift: 0.0001,
      volatility: 0.02,
      dataPoints: 24, // 24 hours of data
      timeInterval: const Duration(hours: 1),
      outputFormat: OutputFormat.simple,
      includeVolume: true,
      baseVolume: 1500000000,
      circulatingSupply: 21000000,
      seed: 42,
    ),
  );

  print('Created: $bitcoin');
  
  // Step 2: Generate initial price data
  print('\n--- Generating initial price data ---\n');
  
  final simulator1 = PriceSimulator(bitcoin.config);
  final initialPrices = simulator1.generateSimple();
  
  print('Generated ${initialPrices.length} price points');
  print('First: \$${initialPrices.first.price.toStringAsFixed(2)}');
  print('Last:  \$${initialPrices.last.price.toStringAsFixed(2)}');
  
  // Update asset with new data
  final updatedBitcoin = bitcoin.addPricePoints(initialPrices);
  print('\nAsset updated: $updatedBitcoin');
  
  // Step 3: Save to storage (simulated)
  print('\n--- Saving to storage ---\n');
  
  final saveJson = jsonEncode(updatedBitcoin.toJson());
  print('Saved ${saveJson.length} characters');
  // In real game: await prefs.setString('asset_btc', saveJson);
  
  print('\n${'=' * 50}');
  print('--- USER CLOSES APP ---');
  print('${'=' * 50}\n');
  
  // Step 4: Load from storage (simulated)
  print('--- USER REOPENS APP - Loading Bitcoin ---\n');
  
  final loadedJson = jsonDecode(saveJson) as Map<String, dynamic>;
  final loadedBitcoin = Asset.fromJson(loadedJson);
  
  print('Loaded: $loadedBitcoin');
  print('Has ${loadedBitcoin.priceHistory.length} historical points');
  print('Current Price: \$${loadedBitcoin.currentPrice!.toStringAsFixed(2)}');
  print('Last Updated: ${loadedBitcoin.lastUpdated}');
  
  // Step 5: Resume simulation (generate more data)
  print('\n--- Generating next 12 hours of data ---\n');
  
  // THIS IS THE KEY: getResumeConfig() handles everything!
  final resumeConfig = loadedBitcoin.getResumeConfig(additionalPoints: 12);
  
  final simulator2 = PriceSimulator(resumeConfig);
  final newPrices = simulator2.generateSimple();
  
  print('Generated ${newPrices.length} new points');
  print('Resumed from: \$${newPrices.first.price.toStringAsFixed(2)}');
  print('Latest price: \$${newPrices.last.price.toStringAsFixed(2)}');
  
  // Update asset with new data
  final finalBitcoin = loadedBitcoin.addPricePoints(newPrices);
  
  print('\nFinal state: $finalBitcoin');
  print('Total history: ${finalBitcoin.priceHistory.length} points');
  
  // Step 6: Save again
  print('\n--- Saving updated state ---\n');
  final finalJson = jsonEncode(finalBitcoin.toJson());
  print('Saved ${finalJson.length} characters');
  
  print('\n${'=' * 50}\n');
  
  // Demonstrate multiple assets
  multipleAssetsExample();
}

void multipleAssetsExample() {
  print('=== Managing Multiple Assets ===\n');
  
  // Create multiple assets
  final assets = [
    Asset.create(
      id: 'btc',
      name: 'Bitcoin',
      config: SimulationConfig(
        initialPrice: 50000.0,
        drift: 0.0002,
        volatility: 0.025,
        dataPoints: 10,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        includeVolume: true,
        baseVolume: 1500000000,
        seed: 1,
      ),
    ),
    Asset.create(
      id: 'eth',
      name: 'Ethereum',
      config: SimulationConfig(
        initialPrice: 3000.0,
        drift: 0.0001,
        volatility: 0.03,
        dataPoints: 10,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        includeVolume: true,
        baseVolume: 800000000,
        seed: 2,
      ),
    ),
    Asset.create(
      id: 'aapl',
      name: 'Apple Inc.',
      config: SimulationConfig(
        initialPrice: 175.0,
        drift: 0.00005,
        volatility: 0.012,
        dataPoints: 10,
        timeInterval: const Duration(days: 1),
        outputFormat: OutputFormat.simple,
        includeVolume: true,
        baseVolume: 50000000,
        seed: 3,
      ),
    ),
  ];
  
  // Save all assets
  final assetMap = <String, String>{};
  for (final asset in assets) {
    assetMap[asset.id] = jsonEncode(asset.toJson());
  }
  
  print('Saved ${assets.length} assets:');
  for (final asset in assets) {
    print('  - ${asset.name} (${asset.id})');
  }
  
  print('\n--- User clicks on Ethereum ---\n');
  
  // Load specific asset
  final ethJson = assetMap['eth']!;
  final ethereum = Asset.fromJson(jsonDecode(ethJson) as Map<String, dynamic>);
  
  print('Loaded: $ethereum');
  
  // Generate price data
  final simulator = PriceSimulator(ethereum.config);
  final prices = simulator.generateSimple();
  
  print('First price: \$${prices.first.price.toStringAsFixed(2)}');
  print('Last price:  \$${prices.last.price.toStringAsFixed(2)}');
  
  // Update and save
  final updatedEth = ethereum.addPricePoints(prices);
  assetMap['eth'] = jsonEncode(updatedEth.toJson());
  
  print('\nUpdated Ethereum saved back to storage!');
  print('Total history: ${updatedEth.priceHistory.length} points');
}
