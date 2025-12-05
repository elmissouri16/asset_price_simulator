# Asset Price Simulator

A pure Dart package for simulating realistic crypto and stock price movements with natural-looking price data. Perfect for charting, backtesting, demos, and testing trading applications.

[![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue)](https://dart.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

✨ **Realistic Price Movements** - Uses Geometric Brownian Motion (GBM), the industry-standard financial simulation model

📊 **Flexible Output Formats** - Generate simple price points or detailed candlestick (OHLC) data

⏱️ **Time Control** - Configure initial time and get open/close timestamps for candlesticks

🎮 **Real-Time Simulation** - Tick-based simulator for controlled, progressive market updates (perfect for games!)

📈 **Volume Simulation** - Realistic trading volumes using log-normal distribution

💰 **Market Metrics** - Track circulating supply, market cap, and supply growth/reduction

🎛️ **Highly Configurable** - Adjust drift, volatility, price ranges, time intervals, and more

🔁 **Reproducible** - Use seeds for deterministic results in testing

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  asset_price_simulator: ^0.1.0
```

Or add it from a local path:

```yaml
dependencies:
  asset_price_simulator:
    path: ../packages/asset_price_simulator
```

Then run:

```bash
dart pub get
```

## Quick Start

### Simple Price Points

Perfect for line charts and basic price tracking:

```dart
import 'package:asset_price_simulator/asset_price_simulator.dart';

final config = SimulationConfig(
  initialPrice: 50000.0,
  drift: 0.0001,           // Slight upward bias
  volatility: 0.02,         // 2% volatility (crypto-like)
  dataPoints: 100,
  timeInterval: Duration(hours: 1),
  outputFormat: OutputFormat.simple,
  includeVolume: true,
  baseVolume: 1000000,      // $1M average volume
  circulatingSupply: 21000000,  // For market cap
);

final simulator = PriceSimulator(config);
final prices = simulator.generateSimple();

for (final point in prices) {
  print('${point.timestamp}: \$${point.price.toStringAsFixed(2)} '
        'MCap: \$${point.marketCap?.toStringAsFixed(0)}');
}
```

### Candlestick (OHLC) Data

Perfect for candlestick charts and technical analysis:

```dart
final config = SimulationConfig(
  initialPrice: 150.0,
  drift: -0.00005,         // Slight downward bias
  volatility: 0.01,         // 1% volatility (stock-like)
  dataPoints: 50,
  timeInterval: Duration(days: 1),
  outputFormat: OutputFormat.candlestick,
  includeVolume: true,
  baseVolume: 5000000,
);

final simulator = PriceSimulator(config);
final candles = simulator.generateCandlesticks();

for (final candle in candles) {
  print('${candle.openTime} to ${candle.closeTime}: '
        'O=${candle.open} H=${candle.high} '
        'L=${candle.low} C=${candle.close} V=${candle.volume}');
}
```

## Configuration Parameters

### Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `initialPrice` | `double` | Starting price for simulation |
| `drift` | `double` | Trend direction (positive = up, negative = down)<br>Typical: 0.0001-0.001 (crypto), 0.00001-0.0001 (stocks) |
| `volatility` | `double` | Amount of price randomness<br>Typical: 0.01-0.05 (stocks), 0.02-0.10 (crypto) |
| `dataPoints` | `int` | Number of price points to generate |
| `timeInterval` | `Duration` | Time between data points |

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `priceRange` | `PriceRange?` | `null` | Min/max price constraints |
| `outputFormat` | `OutputFormat` | `simple` | Output format (simple or candlestick) |
| `includeVolume` | `bool` | `false` | Include volume simulation |
| `baseVolume` | `double?` | `null` | Average trading volume (required if includeVolume is true) |
| `volumeVolatility` | `double` | `0.4` | Volume variation (30-60% typical) |
| `circulatingSupply` | `double?` | `null` | Initial circulating supply |
| `supplyGrowthRate` | `double?` | `null` | Supply growth per period (0.0001 = 0.01% growth) |
| `seed` | `int?` | `null` | Random seed for reproducibility |
| `initialTime` | `DateTime?` | `DateTime.now()` | Starting timestamp for simulation |

## Real-Time Simulation (New!)

Perfect for game economies and live market simulations. Choose between **tick-based** control or **reactive Streams**:

### Option 1: Tick-Based (Manual Control)

Best for game loops where you control the update timing:

```dart
import 'dart:async';

final config = SimulationConfig(
  initialPrice: 100.0,
  drift: 0.0001,
  volatility: 0.02,
  dataPoints: 100,
  timeInterval: Duration(hours: 1),
  outputFormat: OutputFormat.candlestick,
  includeVolume: true,
  baseVolume: 1000000,
  initialTime: DateTime(2024, 1, 1, 9, 0), // Optional: set start time
);

final simulator = RealtimeSimulator(config);

// Update every second with tick-based progression
Timer.periodic(Duration(seconds: 1), (timer) {
  final candle = simulator.nextCandlestick();
  
  if (candle == null) {
    timer.cancel();
    return;
  }
  
  // Update your game UI
  updatePrice(candle.close);
  print('Progress: ${(simulator.progress * 100).toStringAsFixed(0)}%');
});

// Peek ahead without consuming data
final upcoming = simulator.peekCandlestick(0);
print('Next price will be: ${upcoming?.close}');

// Full control: skip, seek, reset
simulator.skip(10);      // Skip 10 points
simulator.seekTo(50);    // Jump to point 50
simulator.reset();       // Start over
```

### Option 2: Stream-Based (Reactive)

Best for Flutter apps and reactive patterns:

```dart
final simulator = RealtimeSimulator(config);

// Get a stream of candlesticks
await for (final candle in simulator.candlestickStream(
  interval: Duration(seconds: 1),
)) {
  updateUI(candle);
  print('${candle.openTime}: \$${candle.close}');
}

// Or use listen for more control
simulator.candlestickStream(
  interval: Duration(milliseconds: 500),
).listen(
  (candle) => updateChart(candle),
  onDone: () => print('Market closed'),
  onError: (error) => handleError(error),
);

// Broadcast for multiple subscribers
final broadcast = simulator.candlestickStream(
  interval: Duration(seconds: 1),
).asBroadcastStream();

broadcast.listen((c) => updatePriceDisplay(c.close));
broadcast.listen((c) => updateVolumeDisplay(c.volume));
broadcast.listen((c) => updateChart(c));
```

**Features:**
- ✅ Tick-based progression (one point at a time)
- ✅ Stream-based reactive API
- ✅ Peek ahead without consuming data
- ✅ Full navigation (skip, seek, reset)
- ✅ Progress tracking
- ✅ Perfect for game loops and reactive UIs

## Examples

### Volatile Crypto Asset

```dart
final config = SimulationConfig(
  initialPrice: 2.50,
  drift: 0.0002,
  volatility: 0.05,  // 5% volatility - very volatile!
  dataPoints: 200,
  timeInterval: Duration(minutes: 15),
  priceRange: PriceRange(min: 1.0, max: 5.0),
  outputFormat: OutputFormat.simple,
  includeVolume: true,
  baseVolume: 500000,
);
```

### Stable Stock

```dart
final config = SimulationConfig(
  initialPrice: 175.0,
  drift: 0.00003,
  volatility: 0.008,  // 0.8% volatility - stable
  dataPoints: 365,
  timeInterval: Duration(days: 1),
  outputFormat: OutputFormat.candlestick,
  includeVolume: true,
  baseVolume: 10000000,
);
```

### Inflationary Crypto

```dart
final config = SimulationConfig(
  initialPrice: 1.0,
  drift: 0.0,
  volatility: 0.02,
  dataPoints: 100,
  timeInterval: Duration(days: 1),
  outputFormat: OutputFormat.simple,
  circulatingSupply: 1000000000,
  supplyGrowthRate: 0.0001,  // 0.01% daily inflation
);
```

### Sideways Market

```dart
final config = SimulationConfig(
  initialPrice: 100.0,
  drift: 0.0,  // No trend
  volatility: 0.015,
  dataPoints: 100,
  timeInterval: Duration(hours: 4),
  priceRange: PriceRange(min: 95, max: 105),  // Tight range
  outputFormat: OutputFormat.simple,
);
```

## Persistence (Save/Load for Games)

All data models support JSON serialization for game persistence:

### Save Configuration

```dart
final config = SimulationConfig(
  initialPrice: 100.0,
  drift: 0.0001,
  volatility: 0.02,
  dataPoints: 100,
  timeInterval: Duration(hours: 1),
);

// Serialize to JSON
final json = config.toJson();
await saveToFile('config.json', jsonEncode(json));

// Load back
final loadedJson = jsonDecode(await readFromFile('config.json'));
final loadedConfig = SimulationConfig.fromJson(loadedJson);
```

### Save Price History

```dart
final prices = simulator.generateSimple();

// Save all price points
final json = prices.map((p) => p.toJson()).toList();
await saveToFile('history.json', jsonEncode(json));

// Load back
final loadedJson = jsonDecode(await readFromFile('history.json'));
final loadedPrices = loadedJson
    .map((j) => SimplePricePoint.fromJson(j))
    .toList();
```

### Save Simulation State

```dart
// Create a snapshot of current simulation state
final state = SimulationState(
  currentPrice: lastPrice,
  currentTime: DateTime.now(),
  pointsGenerated: 50,
  currentSupply: currentSupply,
  randomSeed: 42,
);

// Save state
final json = state.toJson();
await saveToFile('state.json', jsonEncode(json));

// Load and resume
final loadedState = SimulationState.fromJson(jsonDecode(stateJson));
final resumeConfig = SimulationConfig(
  initialPrice: loadedState.currentPrice, // Continue from saved price
  // ... other params
);
```

> **Note**: You implement your own file I/O (SharedPreferences, SQLite, files, etc.). The package provides JSON serialization only.

## How It Works

This package uses **Geometric Brownian Motion (GBM)**, the standard mathematical model for simulating stock and crypto prices:

```
dS = μS dt + σS dW
```

Where:
- `S` = current price
- `μ` (mu) = drift rate
- `σ` (sigma) = volatility
- `dW` = Wiener process (random walk)

This produces realistic price movements with:
- Natural trending behavior
- Realistic volatility patterns
- Prices that stay positive
- Statistically valid distributions

Volume is simulated using a **log-normal distribution**, ensuring positive values with realistic skew.

## API Reference

### Main Classes

- **`PriceSimulator`** - Main simulator class
  - `generateSimple()` → `List<SimplePricePoint>`
  - `generateCandlesticks()` → `List<CandlestickPoint>`
  - `generate()` → `List<Object>` (uses config.outputFormat)

- **`RealtimeSimulator`** - Tick-based real-time simulator
  - `tick()` → Next data point
  - `nextCandlestick()` / `nextPrice()` → Type-safe accessors
  - `candlestickStream(interval)` → Stream of candlesticks
  - `priceStream(interval)` → Stream of prices
  - `peek(offset)` → Preview without consuming
  - `skip(count)`, `seekTo(index)`, `reset()` → Navigation
  - Properties: `hasMore`, `isComplete`, `progress`, `remaining`

- **`SimplePricePoint`** - Basic price data
  - `timestamp`: `DateTime`
  - `price`: `double`
  - `volume`: `double?`
  - `circulatingSupply`: `double?`
  - `marketCap`: `double?` (auto-calculated)

- **`CandlestickPoint`** - OHLC candlestick data
  - `timestamp`: `DateTime` (open time)
  - `openTime`: `DateTime` (getter, same as timestamp)
  - `closeTime`: `DateTime` (end of candlestick period)
  - `open`, `high`, `low`, `close`: `double`
  - `volume`: `double`
  - `circulatingSupply`: `double?`
  - `marketCap`: `double?` (auto-calculated)

- **`SimulationConfig`** - Configuration parameters
- **`PriceRange`** - Price constraints (min/max)
- **`OutputFormat`** - Enum: `simple` or `candlestick`
- **`SimulationState`** - Simulation snapshot for persistence
  - `currentPrice`: `double`
  - `currentTime`: `DateTime`
  - `pointsGenerated`: `int`
  - `currentSupply`: `double?`
  - `randomSeed`: `int?`

## Running the Examples

```bash
cd packages/asset_price_simulator

# Basic usage examples
dart run example/basic_usage.dart

# Real-time simulation examples (both tick and stream)
dart run example/realtime_example.dart

# Stream-based simulation examples
dart run example/stream_example.dart

# Persistence examples
dart run example/persistence_example.dart
```

## Running Tests

```bash
cd packages/asset_price_simulator
dart test
```

## Use Cases

- 🎮 **Game Economies** - Real-time market simulation for trading games
- 📱 **Demo Applications** - Showcase trading apps without live data
- 🧪 **Testing** - Test charting and trading logic with controlled data
- 📊 **Backtesting** - Generate historical-looking price patterns
- ⏱️ **Live Simulations** - Controlled real-time price updates for demos
- 🎓 **Education** - Teach financial concepts with realistic simulations
- 🎨 **Prototyping** - Design UIs and visualizations before connecting real APIs

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
