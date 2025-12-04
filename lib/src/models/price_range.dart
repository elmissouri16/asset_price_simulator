/// Defines the minimum and maximum price constraints for simulation.
class PriceRange {
  /// The minimum allowed price.
  final double min;

  /// The maximum allowed price.
  final double max;

  /// Creates a price range with min and max constraints.
  const PriceRange({
    required this.min,
    required this.max,
  }) : assert(min < max, 'Minimum price must be less than maximum price');

  /// Clamps a price value to be within this range.
  double clamp(double price) {
    if (price < min) return min;
    if (price > max) return max;
    return price;
  }

  @override
  String toString() => 'PriceRange(min: $min, max: $max)';
}
