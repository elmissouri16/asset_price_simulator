import 'dart:math' as math;

/// Utility for generating random values for price simulation.
class RandomGenerator {
  final math.Random _random;

  /// Creates a random generator with an optional seed.
  RandomGenerator([int? seed]) : _random = math.Random(seed);

  /// Generates a random value from a standard normal distribution (mean=0, stddev=1).
  ///
  /// Uses the Box-Muller transform to convert uniform random values
  /// to normally distributed values.
  double nextGaussian() {
    // Box-Muller transform
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    
    final z0 = math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
    return z0;
  }

  /// Generates a random value from a normal distribution with specified mean and stddev.
  double nextNormal(double mean, double stddev) {
    return mean + stddev * nextGaussian();
  }

  /// Generates a random value from a log-normal distribution.
  ///
  /// Log-normal distribution is commonly used for modeling trading volumes
  /// as it ensures positive values and has realistic skew.
  double nextLogNormal(double mean, double stddev) {
    final normal = nextGaussian();
    return math.exp(mean + stddev * normal);
  }

  /// Generates a random uniform value between 0 and 1.
  double nextDouble() {
    return _random.nextDouble();
  }

  /// Generates a random integer in the range [min, max).
  int nextInt(int min, int max) {
    return min + _random.nextInt(max - min);
  }
}
