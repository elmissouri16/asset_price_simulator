import 'dart:math' as math;

import '../models/candlestick_point.dart';
import '../models/output_format.dart';
import '../models/simple_price_point.dart';
import '../models/simulation_config.dart';
import '../utils/random_generator.dart';

/// Simulates realistic asset price movements using Geometric Brownian Motion.
class PriceSimulator {
  final SimulationConfig config;
  final RandomGenerator _random;

  /// Creates a price simulator with the given configuration.
  PriceSimulator(this.config)
      : _random = RandomGenerator(config.seed);

  /// Generates simple price points based on the configuration.
  List<SimplePricePoint> generateSimple() {
    assert(
      config.outputFormat == OutputFormat.simple,
      'Use generateCandlesticks() for candlestick output format',
    );

    final points = <SimplePricePoint>[];
    var currentPrice = config.initialPrice;
    var currentSupply = config.circulatingSupply;
    var currentTime = config.initialTime ?? DateTime.now();

    for (var i = 0; i < config.dataPoints; i++) {
      // Apply Geometric Brownian Motion: dS = μS dt + σS dW
      final dt = 1.0; // Time step (normalized)
      final drift = config.drift * currentPrice * dt;
      final randomShock = config.volatility * currentPrice * _random.nextGaussian();
      
      currentPrice += drift + randomShock;

      // Apply price range constraints if specified
      if (config.priceRange != null) {
        currentPrice = config.priceRange!.clamp(currentPrice);
      }

      // Generate volume if enabled
      double? volume;
      if (config.includeVolume) {
        // Volume is log-normally distributed and correlated with price volatility
        final volumeMean = math.log(config.baseVolume!);
        volume = _random.nextLogNormal(volumeMean, config.volumeVolatility);
      }

      // Update supply if growth rate is specified
      if (currentSupply != null && config.supplyGrowthRate != null) {
        currentSupply *= (1.0 + config.supplyGrowthRate!);
      }

      points.add(
        SimplePricePoint(
          timestamp: currentTime,
          price: currentPrice,
          volume: volume,
          circulatingSupply: currentSupply,
        ),
      );

      currentTime = currentTime.add(config.timeInterval);
    }

    return points;
  }

  /// Generates candlestick (OHLC) data points based on the configuration.
  List<CandlestickPoint> generateCandlesticks() {
    assert(
      config.outputFormat == OutputFormat.candlestick,
      'Use generateSimple() for simple output format',
    );

    final candles = <CandlestickPoint>[];
    var currentPrice = config.initialPrice;
    var currentSupply = config.circulatingSupply;
    var currentTime = config.initialTime ?? DateTime.now();

    for (var i = 0; i < config.dataPoints; i++) {
      final open = currentPrice;
      final openTime = currentTime;
      final closeTime = currentTime.add(config.timeInterval);

      // Simulate intra-period price movements to get high/low/close
      final intraPeriodMoves = 10; // Number of micro-movements within the period
      var high = open;
      var low = open;

      for (var j = 0; j < intraPeriodMoves; j++) {
        final dt = 1.0 / intraPeriodMoves;
        final drift = config.drift * currentPrice * dt;
        final randomShock = config.volatility * currentPrice * 
                           _random.nextGaussian() * math.sqrt(dt);
        
        currentPrice += drift + randomShock;

        // Apply price range constraints if specified
        if (config.priceRange != null) {
          currentPrice = config.priceRange!.clamp(currentPrice);
        }

        high = math.max(high, currentPrice);
        low = math.min(low, currentPrice);
      }

      final close = currentPrice;

      // Generate volume if enabled
      double volume = 0;
      if (config.includeVolume) {
        final volumeMean = math.log(config.baseVolume!);
        volume = _random.nextLogNormal(volumeMean, config.volumeVolatility);
      }

      // Update supply if growth rate is specified
      if (currentSupply != null && config.supplyGrowthRate != null) {
        currentSupply *= (1.0 + config.supplyGrowthRate!);
      }

      candles.add(
        CandlestickPoint(
          timestamp: openTime,
          open: open,
          high: high,
          low: low,
          close: close,
          closeTime: closeTime,
          volume: volume,
          circulatingSupply: currentSupply,
        ),
      );

      currentTime = closeTime;
    }

    return candles;
  }

  /// Generates data in the format specified by the configuration.
  ///
  /// Returns either List<SimplePricePoint> or List<CandlestickPoint>
  /// depending on the outputFormat in the config.
  List<Object> generate() {
    return config.outputFormat == OutputFormat.simple
        ? generateSimple()
        : generateCandlesticks();
  }
}
