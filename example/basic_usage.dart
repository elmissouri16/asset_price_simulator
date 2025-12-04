// ignore_for_file: avoid_print

import 'package:asset_price_simulator/asset_price_simulator.dart';

void main() {
  print('=== Asset Price Simulator Examples ===\n');

  // Example 1: Simple crypto price simulation
  cryptoSimpleExample();

  print('\n${'=' * 50}\n');

  // Example 2: Stock candlestick simulation
  stockCandlestickExample();

  print('\n${'=' * 50}\n');

  // Example 3: Crypto with supply growth (inflationary)
  inflationaryCryptoExample();

  print('\n${'=' * 50}\n');

  // Example 4: Sideways market movement
  sidewaysMarketExample();
}

/// Example 1: Bitcoin-like volatile crypto with simple price points
void cryptoSimpleExample() {
  print('Example 1: Bitcoin-like Crypto (Simple Points)\n');

  final config = SimulationConfig(
    initialPrice: 50000.0,
    drift: 0.0002, // Slight upward trend
    volatility: 0.025, // 2.5% volatility (high like crypto)
    dataPoints: 20,
    timeInterval: const Duration(hours: 1),
    priceRange: PriceRange(min: 30000, max: 70000),
    outputFormat: OutputFormat.simple,
    includeVolume: true,
    baseVolume: 1500000000, // $1.5B average volume
    circulatingSupply: 21000000, // Like Bitcoin's max supply
    seed: 42, // For reproducible results
  );

  final simulator = PriceSimulator(config);
  final prices = simulator.generateSimple();

  print('First 5 price points:');
  for (var i = 0; i < 5 && i < prices.length; i++) {
    final point = prices[i];
    print('  ${point.timestamp.hour.toString().padLeft(2, '0')}:00 - '
          '\$${point.price.toStringAsFixed(2)} | '
          'Vol: \$${(point.volume! / 1000000).toStringAsFixed(0)}M | '
          'MCap: \$${(point.marketCap! / 1000000000).toStringAsFixed(1)}B');
  }

  print('\nLast price: \$${prices.last.price.toStringAsFixed(2)}');
  print('Price change: ${((prices.last.price / prices.first.price - 1) * 100).toStringAsFixed(2)}%');
}

/// Example 2: Apple-like stock with candlestick data
void stockCandlestickExample() {
  print('Example 2: Stock Market (Candlestick Data)\n');

  final config = SimulationConfig(
    initialPrice: 175.0,
    drift: 0.00005, // Very slight upward trend
    volatility: 0.012, // 1.2% volatility (moderate for stocks)
    dataPoints: 10,
    timeInterval: const Duration(days: 1),
    outputFormat: OutputFormat.candlestick,
    includeVolume: true,
    baseVolume: 50000000, // 50M shares
    seed: 123,
  );

  final simulator = PriceSimulator(config);
  final candles = simulator.generateCandlesticks();

  print('Day | Open    | High    | Low     | Close   | Volume');
  print('-' * 60);
  for (var i = 0; i < candles.length; i++) {
    final c = candles[i];
    print('${(i + 1).toString().padLeft(3)} | '
          '\$${c.open.toStringAsFixed(2).padLeft(6)} | '
          '\$${c.high.toStringAsFixed(2).padLeft(6)} | '
          '\$${c.low.toStringAsFixed(2).padLeft(6)} | '
          '\$${c.close.toStringAsFixed(2).padLeft(6)} | '
          '${(c.volume / 1000000).toStringAsFixed(1)}M');
  }
}

/// Example 3: Inflationary crypto (supply increases over time)
void inflationaryCryptoExample() {
  print('Example 3: Inflationary Crypto\n');

  final config = SimulationConfig(
    initialPrice: 2.50,
    drift: 0.0001,
    volatility: 0.03, // 3% volatility
    dataPoints: 10,
    timeInterval: const Duration(days: 1),
    outputFormat: OutputFormat.simple,
    includeVolume: true,
    baseVolume: 10000000, // $10M volume
    circulatingSupply: 1000000000, // 1B initial supply
    supplyGrowthRate: 0.0002, // 0.02% daily inflation
    seed: 999,
  );

  final simulator = PriceSimulator(config);
  final prices = simulator.generateSimple();

  print('Day | Price   | Supply       | Market Cap');
  print('-' * 50);
  for (var i = 0; i < prices.length; i++) {
    final p = prices[i];
    print('${(i + 1).toString().padLeft(3)} | '
          '\$${p.price.toStringAsFixed(3)} | '
          '${(p.circulatingSupply! / 1000000).toStringAsFixed(2)}M | '
          '\$${(p.marketCap! / 1000000).toStringAsFixed(1)}M');
  }

  final supplyChange = (prices.last.circulatingSupply! / prices.first.circulatingSupply! - 1) * 100;
  print('\nSupply increased by: ${supplyChange.toStringAsFixed(3)}%');
}

/// Example 4: Sideways market (low drift, moderate volatility)
void sidewaysMarketExample() {
  print('Example 4: Sideways/Ranging Market\n');

  final config = SimulationConfig(
    initialPrice: 100.0,
    drift: 0.0, // No trend
    volatility: 0.015, // 1.5% volatility
    dataPoints: 15,
    timeInterval: const Duration(hours: 4),
    priceRange: PriceRange(min: 95, max: 105), // Tight range
    outputFormat: OutputFormat.simple,
    includeVolume: true,
    baseVolume: 5000000,
    seed: 777,
  );

  final simulator = PriceSimulator(config);
  final prices = simulator.generateSimple();

  print('Prices over time:');
  for (var i = 0; i < prices.length; i++) {
    final p = prices[i];
    final bar = '█' * ((p.price - 95) * 2).round();
    print('${(i + 1).toString().padLeft(2)}: \$${p.price.toStringAsFixed(2)} $bar');
  }

  final priceStdDev = _calculateStdDev(prices.map((p) => p.price).toList());
  print('\nPrice std dev: \$${priceStdDev.toStringAsFixed(2)}');
  print('Price range: \$${prices.map((p) => p.price).reduce((a, b) => a < b ? a : b).toStringAsFixed(2)} - '
        '\$${prices.map((p) => p.price).reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}');
}

/// Helper function to calculate standard deviation
double _calculateStdDev(List<double> values) {
  if (values.isEmpty) return 0;
  final mean = values.reduce((a, b) => a + b) / values.length;
  final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
  return _sqrt(variance);
}

/// Simple square root implementation
double _sqrt(double value) {
  if (value <= 0) return 0;
  var guess = value / 2;
  for (var i = 0; i < 10; i++) {
    guess = (guess + value / guess) / 2;
  }
  return guess;
}

