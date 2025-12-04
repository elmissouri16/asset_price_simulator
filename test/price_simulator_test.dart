import 'package:asset_price_simulator/asset_price_simulator.dart';
import 'package:test/test.dart';

void main() {
  group('PriceSimulator', () {
    test('generates correct number of simple price points', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0001,
        volatility: 0.01,
        dataPoints: 50,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 42,
      );

      final simulator = PriceSimulator(config);
      final prices = simulator.generateSimple();

      expect(prices.length, equals(50));
      // First price point has GBM applied, so it won't exactly equal initialPrice
      expect(prices.first.price, closeTo(100.0, 5.0));
    });

    test('generates correct number of candlesticks', () {
      final config = SimulationConfig(
        initialPrice: 150.0,
        drift: 0.0,
        volatility: 0.02,
        dataPoints: 30,
        timeInterval: const Duration(days: 1),
        outputFormat: OutputFormat.candlestick,
        includeVolume: true,
        baseVolume: 1000000,
        seed: 123,
      );

      final simulator = PriceSimulator(config);
      final candles = simulator.generateCandlesticks();

      expect(candles.length, equals(30));
      expect(candles.first.open, equals(150.0));
    });

    test('respects price range constraints', () {
      final config = SimulationConfig(
        initialPrice: 50.0,
        drift: 0.001, // Strong upward drift
        volatility: 0.1, // High volatility
        dataPoints: 100,
        timeInterval: const Duration(minutes: 1),
        priceRange: PriceRange(min: 40, max: 60),
        outputFormat: OutputFormat.simple,
        seed: 999,
      );

      final simulator = PriceSimulator(config);
      final prices = simulator.generateSimple();

      for (final point in prices) {
        expect(point.price, greaterThanOrEqualTo(40.0));
        expect(point.price, lessThanOrEqualTo(60.0));
      }
    });

    test('includes volume when enabled', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.02,
        dataPoints: 10,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        includeVolume: true,
        baseVolume: 1000000,
        seed: 42,
      );

      final simulator = PriceSimulator(config);
      final prices = simulator.generateSimple();

      for (final point in prices) {
        expect(point.volume, isNotNull);
        expect(point.volume, greaterThan(0));
      }
    });

    test('excludes volume when disabled', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.02,
        dataPoints: 10,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        includeVolume: false,
        seed: 42,
      );

      final simulator = PriceSimulator(config);
      final prices = simulator.generateSimple();

      for (final point in prices) {
        expect(point.volume, isNull);
      }
    });

    test('calculates market cap correctly', () {
      final config = SimulationConfig(
        initialPrice: 2.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 5,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        circulatingSupply: 1000000,
        seed: 42,
      );

      final simulator = PriceSimulator(config);
      final prices = simulator.generateSimple();

      for (final point in prices) {
        expect(point.marketCap, isNotNull);
        expect(point.marketCap, closeTo(point.price * 1000000, 0.01));
      }
    });

    test('applies supply growth rate', () {
      final config = SimulationConfig(
        initialPrice: 1.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 10,
        timeInterval: const Duration(days: 1),
        outputFormat: OutputFormat.simple,
        circulatingSupply: 1000000,
        supplyGrowthRate: 0.01, // 1% growth per day
        seed: 42,
      );

      final simulator = PriceSimulator(config);
      final prices = simulator.generateSimple();

      // First point already has growth applied
      expect(prices.first.circulatingSupply, closeTo(1010000, 1));
      
      // After 10 periods with 1% growth per period: 1000000 * 1.01^10
      final expectedSupply = 1000000 * 1.104622125; // 1.01^10 ≈ 1.104622125
      expect(prices.last.circulatingSupply, closeTo(expectedSupply, 1000));
    });

    test('produces reproducible results with same seed', () {
      final config1 = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0001,
        volatility: 0.02,
        dataPoints: 20,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 12345,
      );

      final config2 = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0001,
        volatility: 0.02,
        dataPoints: 20,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 12345,
      );

      final prices1 = PriceSimulator(config1).generateSimple();
      final prices2 = PriceSimulator(config2).generateSimple();

      for (var i = 0; i < prices1.length; i++) {
        expect(prices1[i].price, equals(prices2[i].price));
      }
    });

    test('candlestick high/low values are correct', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 10,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.candlestick,
        includeVolume: true,
        baseVolume: 1000000,
        seed: 42,
      );

      final simulator = PriceSimulator(config);
      final candles = simulator.generateCandlesticks();

      for (final candle in candles) {
        // High should be >= all OHLC values
        expect(candle.high, greaterThanOrEqualTo(candle.open));
        expect(candle.high, greaterThanOrEqualTo(candle.close));
        expect(candle.high, greaterThanOrEqualTo(candle.low));
        
        // Low should be <= all OHLC values
        expect(candle.low, lessThanOrEqualTo(candle.open));
        expect(candle.low, lessThanOrEqualTo(candle.close));
        expect(candle.low, lessThanOrEqualTo(candle.high));
      }
    });

    test('drift affects price direction', () {
      // Upward drift - use very strong drift to overcome volatility
      final upConfig = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.01, // Very strong upward drift (1%)
        volatility: 0.005, // Low volatility
        dataPoints: 100,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 42,
      );

      final upPrices = PriceSimulator(upConfig).generateSimple();
      // With strong drift over 100 periods, price should increase
      expect(upPrices.last.price, greaterThan(upPrices.first.price));

      // Downward drift - use very strong drift to overcome volatility
      final downConfig = SimulationConfig(
        initialPrice: 100.0,
        drift: -0.01, // Very strong downward drift (-1%)
        volatility: 0.005, // Low volatility
        dataPoints: 100,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 42,
      );

      final downPrices = PriceSimulator(downConfig).generateSimple();
      expect(downPrices.last.price, lessThan(downPrices.first.price));
    });
  });

  group('SimulationConfig', () {
    test('validates positive initial price', () {
      expect(
        () => SimulationConfig(
          initialPrice: -10.0,
          drift: 0.0,
          volatility: 0.01,
          dataPoints: 10,
          timeInterval: const Duration(hours: 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('validates non-negative volatility', () {
      expect(
        () => SimulationConfig(
          initialPrice: 100.0,
          drift: 0.0,
          volatility: -0.01,
          dataPoints: 10,
          timeInterval: const Duration(hours: 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('validates positive data points', () {
      expect(
        () => SimulationConfig(
          initialPrice: 100.0,
          drift: 0.0,
          volatility: 0.01,
          dataPoints: 0,
          timeInterval: const Duration(hours: 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('validates base volume when volume is enabled', () {
      expect(
        () => SimulationConfig(
          initialPrice: 100.0,
          drift: 0.0,
          volatility: 0.01,
          dataPoints: 10,
          timeInterval: const Duration(hours: 1),
          includeVolume: true,
          // Missing baseVolume
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('PriceRange', () {
    test('validates min < max', () {
      expect(
        () => PriceRange(min: 100, max: 50),
        throwsA(isA<AssertionError>()),
      );
    });

    test('clamps values correctly', () {
      final range = PriceRange(min: 50, max: 150);
      expect(range.clamp(30), equals(50));
      expect(range.clamp(100), equals(100));
      expect(range.clamp(200), equals(150));
    });
  });
}
