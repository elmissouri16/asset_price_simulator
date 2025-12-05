import 'package:asset_price_simulator/asset_price_simulator.dart';
import 'package:test/test.dart';

void main() {
  group('RealtimeSimulator', () {
    test('generates correct number of data points', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0001,
        volatility: 0.01,
        dataPoints: 50,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);

      expect(simulator.total, equals(50));
      expect(simulator.currentIndex, equals(0));
      expect(simulator.hasMore, isTrue);
      expect(simulator.isComplete, isFalse);
    });

    test('tick advances through simple price points correctly', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 5,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);
      final points = <SimplePricePoint>[];

      while (simulator.hasMore) {
        final point = simulator.nextPrice();
        if (point != null) {
          points.add(point);
        }
      }

      expect(points.length, equals(5));
      expect(simulator.isComplete, isTrue);
      expect(simulator.hasMore, isFalse);
      expect(simulator.nextPrice(), isNull);
    });

    test('tick advances through candlesticks correctly', () {
      final config = SimulationConfig(
        initialPrice: 150.0,
        drift: 0.0,
        volatility: 0.02,
        dataPoints: 10,
        timeInterval: const Duration(days: 1),
        outputFormat: OutputFormat.candlestick,
        includeVolume: true,
        baseVolume: 1000000,
        seed: 123,
      );

      final simulator = RealtimeSimulator(config);
      var count = 0;

      while (simulator.hasMore) {
        final candle = simulator.nextCandlestick();
        if (candle != null) {
          count++;
          expect(candle.open, greaterThan(0));
          expect(candle.high, greaterThanOrEqualTo(candle.low));
        }
      }

      expect(count, equals(10));
      expect(simulator.currentIndex, equals(10));
    });

    test('peek does not advance index', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 5,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);

      final peek1 = simulator.peek(0);
      final peek2 = simulator.peek(1);
      final peek3 = simulator.peek(2);

      expect(peek1, isNotNull);
      expect(peek2, isNotNull);
      expect(peek3, isNotNull);
      expect(simulator.currentIndex, equals(0)); // Should not have advanced

      final first = simulator.tick();
      expect(first, equals(peek1)); // Should be the same as first peek
      expect(simulator.currentIndex, equals(1));
    });

    test('peekPrice and peekCandlestick work correctly', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 3,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.candlestick,
        includeVolume: true,
        baseVolume: 1000000,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);

      final peek0 = simulator.peekCandlestick(0);
      final peek1 = simulator.peekCandlestick(1);

      expect(peek0, isNotNull);
      expect(peek1, isNotNull);
      expect(simulator.currentIndex, equals(0));

      final first = simulator.nextCandlestick();
      expect(first, equals(peek0));
    });

    test('throws error when using wrong type methods', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 5,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);

      expect(
        () => simulator.nextCandlestick(),
        throwsA(isA<StateError>()),
      );

      expect(
        () => simulator.peekCandlestick(),
        throwsA(isA<StateError>()),
      );
    });

    test('reset works correctly', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 5,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);

      // Consume some data
      final first1 = simulator.nextPrice();
      simulator.nextPrice();
      simulator.nextPrice();

      expect(simulator.currentIndex, equals(3));

      // Reset
      simulator.reset();

      expect(simulator.currentIndex, equals(0));
      expect(simulator.hasMore, isTrue);

      final first2 = simulator.nextPrice();
      expect(first2, equals(first1)); // Should be the same after reset
    });

    test('skip advances by correct amount', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 10,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);

      final skipped = simulator.skip(3);
      expect(skipped, equals(3));
      expect(simulator.currentIndex, equals(3));

      // Try to skip past the end
      final skipped2 = simulator.skip(100);
      expect(skipped2, equals(7)); // Only 7 remaining
      expect(simulator.currentIndex, equals(10));
      expect(simulator.hasMore, isFalse);
    });

    test('seekTo positions correctly', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 10,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);

      simulator.seekTo(5);
      expect(simulator.currentIndex, equals(5));
      expect(simulator.remaining, equals(5));

      simulator.seekTo(0);
      expect(simulator.currentIndex, equals(0));

      expect(
        () => simulator.seekTo(100),
        throwsA(isA<RangeError>()),
      );
    });

    test('progress calculation is correct', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 10,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);

      expect(simulator.progress, equals(0.0));

      simulator.skip(5);
      expect(simulator.progress, equals(0.5));

      simulator.skip(5);
      expect(simulator.progress, equals(1.0));
    });

    test('peekRemaining and consumeRemaining work correctly', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 5,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);

      simulator.nextPrice();
      simulator.nextPrice();

      final remaining = simulator.peekRemaining();
      expect(remaining.length, equals(3));
      expect(simulator.currentIndex, equals(2)); // Should not advance

      final consumed = simulator.consumeRemaining();
      expect(consumed.length, equals(3));
      expect(simulator.currentIndex, equals(5)); // Should advance to end
      expect(simulator.hasMore, isFalse);
    });

    test('works with custom initial time', () {
      final initialTime = DateTime(2024, 6, 15, 9, 0);
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 3,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.candlestick,
        includeVolume: true,
        baseVolume: 1000000,
        initialTime: initialTime,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);

      final first = simulator.nextCandlestick();
      expect(first?.openTime, equals(initialTime));
      expect(
        first?.closeTime,
        equals(initialTime.add(const Duration(hours: 1))),
      );
    });

    test('candlestickStream emits all data points', () async {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 5,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.candlestick,
        includeVolume: true,
        baseVolume: 1000000,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);
      final candles = <CandlestickPoint>[];

      await for (final candle in simulator.candlestickStream(
        interval: Duration.zero, // No delay for tests
      )) {
        candles.add(candle);
      }

      expect(candles.length, equals(5));
      expect(simulator.isComplete, isTrue);
    });

    test('priceStream emits all data points', () async {
      final config = SimulationConfig(
        initialPrice: 50.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 3,
        timeInterval: const Duration(minutes: 15),
        outputFormat: OutputFormat.simple,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);
      final prices = <SimplePricePoint>[];

      await for (final price in simulator.priceStream(
        interval: Duration.zero,
      )) {
        prices.add(price);
      }

      expect(prices.length, equals(3));
      expect(simulator.isComplete, isTrue);
    });

    test('candlestickStream throws error for wrong output format', () async {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 5,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple, // Wrong format
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);

      expect(
        () async {
          await for (final _ in simulator.candlestickStream(
            interval: Duration.zero,
          )) {}
        },
        throwsA(isA<StateError>()),
      );
    });

    test('priceStream throws error for wrong output format', () async {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 5,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.candlestick, // Wrong format
        includeVolume: true,
        baseVolume: 1000000,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);

      expect(
        () async {
          await for (final _ in simulator.priceStream(
            interval: Duration.zero,
          )) {}
        },
        throwsA(isA<StateError>()),
      );
    });

    test('stream autoStart parameter works correctly', () async {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0,
        volatility: 0.01,
        dataPoints: 5,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.simple,
        seed: 42,
      );

      final simulator = RealtimeSimulator(config);

      // Manually advance
      simulator.skip(2);
      expect(simulator.currentIndex, equals(2));

      // Stream with autoStart=true should start from current position
      var count = 0;
      await for (final _ in simulator.priceStream(
        interval: Duration.zero,
        autoStart: true,
      )) {
        count++;
      }

      expect(count, equals(3)); // Only remaining 3 points

      // Reset and try with autoStart=false
      simulator.skip(2);
      count = 0;

      await for (final _ in simulator.priceStream(
        interval: Duration.zero,
        autoStart: false, // Should reset first
      )) {
        count++;
      }

      expect(count, equals(5)); // All 5 points
    });
  });
}
