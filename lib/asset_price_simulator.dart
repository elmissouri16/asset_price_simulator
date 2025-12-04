/// A pure Dart package for simulating realistic crypto and stock price movements.
///
/// This library provides tools to generate natural-looking price data for charting
/// and testing purposes using Geometric Brownian Motion (GBM), the industry-standard
/// model for financial price simulation.
///
/// ## Features
///
/// - **Realistic Price Movements**: Uses GBM for natural-looking price paths
/// - **Flexible Output**: Choose between simple price points or candlestick (OHLC) data
/// - **Volume Simulation**: Generate realistic trading volumes correlated with price volatility
/// - **Supply Tracking**: Model circulating supply with growth/reduction over time
/// - **Market Cap**: Automatically calculate market capitalization
/// - **Configurable**: Adjust drift, volatility, price ranges, and more
/// - **Reproducible**: Use seeds for deterministic results
///
/// ## Quick Start
///
/// ```dart
/// import 'package:asset_price_simulator/asset_price_simulator.dart';
///
/// // Configure simulation for a crypto-like asset
/// final config = SimulationConfig(
///   initialPrice: 50000.0,
///   drift: 0.0001,
///   volatility: 0.02,
///   dataPoints: 100,
///   timeInterval: Duration(hours: 1),
///   outputFormat: OutputFormat.simple,
///   includeVolume: true,
///   baseVolume: 1000000,
///   circulatingSupply: 21000000,
/// );
///
/// // Generate price data
/// final simulator = PriceSimulator(config);
/// final prices = simulator.generateSimple();
///
/// // Use the data
/// for (final point in prices) {
///   print('${point.timestamp}: \$${point.price}');
/// }
/// ```
library asset_price_simulator;

// Models
export 'src/models/asset.dart';
export 'src/models/candlestick_point.dart';
export 'src/models/output_format.dart';
export 'src/models/price_range.dart';
export 'src/models/simple_price_point.dart';
export 'src/models/simulation_config.dart';
export 'src/models/simulation_state.dart';

// Simulator
export 'src/simulator/price_simulator.dart';
