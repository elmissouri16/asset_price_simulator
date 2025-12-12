// ignore_for_file: avoid_print

import 'package:asset_price_simulator/asset_price_simulator.dart';
import 'package:test/test.dart';

void main() {
  group('Enhanced Candlestick Simulation', () {
    test('Default behavior matches previous version (backward compatibility)', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0001,
        volatility: 0.02,
        dataPoints: 10,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.candlestick,
        includeVolume: true,
        baseVolume: 1000000,
        seed: 42,
      );

      final simulator = PriceSimulator(config);
      final candles = simulator.generateCandlesticks();

      expect(candles.length, 10);
      expect(config.intraCandleTicks, 10); // Default value
      expect(config.includeIntraPeriodData, false); // Default value
      
      // Verify candles don't have intra-period data by default
      for (final candle in candles) {
        expect(candle.hasIntraPeriodData, false);
        expect(candle.intraPeriodCount, 0);
        expect(candle.open > 0, true);
        expect(candle.high >= candle.open, true);
        expect(candle.high >= candle.close, true);
        expect(candle.low <= candle.open, true);
        expect(candle.low <= candle.close, true);
      }
    });

    test('Intra-period data is captured when enabled', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0001,
        volatility: 0.02,
        dataPoints: 5,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.candlestick,
        includeVolume: true,
        baseVolume: 1000000,
        intraCandleTicks: 20,
        includeIntraPeriodData: true,
        seed: 123,
      );

      final simulator = PriceSimulator(config);
      final candles = simulator.generateCandlesticks();

      expect(candles.length, 5);

      for (final candle in candles) {
        // Verify intra-period data is present
        expect(candle.hasIntraPeriodData, true);
        expect(candle.intraPeriodCount, 20);
        expect(candle.intraPeriodPrices, isNotNull);
        expect(candle.intraPeriodTimestamps, isNotNull);
        expect(candle.intraPeriodPrices!.length, 20);
        expect(candle.intraPeriodTimestamps!.length, 20);

        // Verify last price matches close
        expect(candle.intraPeriodPrices!.last, candle.close);

        // Verify timestamps are within candle period
        for (final timestamp in candle.intraPeriodTimestamps!) {
          expect(timestamp.isAfter(candle.timestamp) || 
                 timestamp.isAtSameMomentAs(candle.timestamp), true);
          expect(timestamp.isBefore(candle.closeTime) || 
                 timestamp.isAtSameMomentAs(candle.closeTime), true);
        }

        // Verify high/low are accurate
        final maxIntraPeriod = candle.intraPeriodPrices!.reduce((a, b) => a > b ? a : b);
        final minIntraPeriod = candle.intraPeriodPrices!.reduce((a, b) => a < b ? a : b);
        
        expect(candle.high >= maxIntraPeriod, true);
        expect(candle.low <= minIntraPeriod, true);
      }
    });

    test('Different intraCandleTicks values produce valid candles', () {
      for (final tickCount in [3, 10, 50, 100]) {
        final config = SimulationConfig(
          initialPrice: 100.0,
          drift: 0.0001,
          volatility: 0.02,
          dataPoints: 3,
          timeInterval: const Duration(minutes: 30),
          outputFormat: OutputFormat.candlestick,
          includeVolume: true,
          baseVolume: 500000,
          intraCandleTicks: tickCount,
          includeIntraPeriodData: true,
          seed: 999,
        );

        final simulator = PriceSimulator(config);
        final candles = simulator.generateCandlesticks();

        expect(candles.length, 3);

        for (final candle in candles) {
          expect(candle.intraPeriodCount, tickCount);
          expect(candle.open > 0, true);
          expect(candle.high >= candle.low, true);
          expect(candle.close > 0, true);
        }
      }
    });

    test('CandlestickPoint JSON serialization with intra-period data', () {
      final original = CandlestickPoint(
        timestamp: DateTime(2024, 1, 1, 10, 0),
        open: 100.0,
        high: 105.0,
        low: 98.0,
        close: 102.0,
        closeTime: DateTime(2024, 1, 1, 11, 0),
        volume: 1000000,
        intraPeriodPrices: [100.0, 102.0, 101.0, 103.0, 102.0],
        intraPeriodTimestamps: [
          DateTime(2024, 1, 1, 10, 12),
          DateTime(2024, 1, 1, 10, 24),
          DateTime(2024, 1, 1, 10, 36),
          DateTime(2024, 1, 1, 10, 48),
          DateTime(2024, 1, 1, 11, 0),
        ],
      );

      final json = original.toJson();
      final restored = CandlestickPoint.fromJson(json);

      expect(restored.open, original.open);
      expect(restored.high, original.high);
      expect(restored.low, original.low);
      expect(restored.close, original.close);
      expect(restored.hasIntraPeriodData, true);
      expect(restored.intraPeriodCount, 5);
      expect(restored.intraPeriodPrices, original.intraPeriodPrices);
      expect(restored.intraPeriodTimestamps, original.intraPeriodTimestamps);
    });

    test('SimulationConfig copyWith includes new parameters', () {
      final original = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0001,
        volatility: 0.02,
        dataPoints: 100,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.candlestick,
        includeVolume: true,
        baseVolume: 1000000,
      );

      final modified = original.copyWith(
        intraCandleTicks: 50,
        includeIntraPeriodData: true,
      );

      expect(modified.intraCandleTicks, 50);
      expect(modified.includeIntraPeriodData, true);
      expect(modified.initialPrice, original.initialPrice);
      expect(modified.drift, original.drift);
    });

    test('SimulationConfig JSON serialization with new fields', () {
      final original = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0001,
        volatility: 0.02,
        dataPoints: 100,
        timeInterval: const Duration(hours: 1),
        outputFormat: OutputFormat.candlestick,
        includeVolume: true,
        baseVolume: 1000000,
        intraCandleTicks: 25,
        includeIntraPeriodData: true,
      );

      final json = original.toJson();
      final restored = SimulationConfig.fromJson(json);

      expect(restored.intraCandleTicks, 25);
      expect(restored.includeIntraPeriodData, true);
      expect(restored.initialPrice, original.initialPrice);
    });

    test('Higher tick counts produce more accurate high/low values', () {
      final configs = [
        SimulationConfig(
          initialPrice: 100.0,
          drift: 0.0001,
          volatility: 0.05, // High volatility for testing
          dataPoints: 10,
          timeInterval: const Duration(hours: 1),
          outputFormat: OutputFormat.candlestick,
          includeVolume: true,
          baseVolume: 1000000,
          intraCandleTicks: 5, // Low tick count
          seed: 777,
        ),
        SimulationConfig(
          initialPrice: 100.0,
          drift: 0.0001,
          volatility: 0.05,
          dataPoints: 10,
          timeInterval: const Duration(hours: 1),
          outputFormat: OutputFormat.candlestick,
          includeVolume: true,
          baseVolume: 1000000,
          intraCandleTicks: 100, // High tick count
          seed: 777, // Same seed for comparison
        ),
      ];

      final candles5 = PriceSimulator(configs[0]).generateCandlesticks();
      final candles100 = PriceSimulator(configs[1]).generateCandlesticks();

      // With more ticks, we should generally see wider high-low ranges
      // (though not guaranteed for every candle due to randomness)
      var widerRangeCount = 0;
      for (var i = 0; i < candles5.length; i++) {
        final range5 = candles5[i].high - candles5[i].low;
        final range100 = candles100[i].high - candles100[i].low;
        if (range100 >= range5) {
          widerRangeCount++;
        }
      }

      // Most candles should have equal or wider ranges with more ticks
      expect(widerRangeCount >= candles5.length * 0.5, true);
    });

    test('Memory efficiency: no intra-period data when disabled', () {
      final config = SimulationConfig(
        initialPrice: 100.0,
        drift: 0.0001,
        volatility: 0.02,
        dataPoints: 1000,
        timeInterval: const Duration(minutes: 1),
        outputFormat: OutputFormat.candlestick,
        includeVolume: true,
        baseVolume: 1000000,
        intraCandleTicks: 100, // High tick count
        includeIntraPeriodData: false, // But not capturing
      );

      final simulator = PriceSimulator(config);
      final candles = simulator.generateCandlesticks();

      // Despite high tick count, no intra-period data should be stored
      for (final candle in candles) {
        expect(candle.hasIntraPeriodData, false);
        expect(candle.intraPeriodPrices, isNull);
        expect(candle.intraPeriodTimestamps, isNull);
      }
    });
  });
}
