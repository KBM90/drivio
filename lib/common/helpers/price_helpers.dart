class PriceHelpers {
  double calculateSuggestedPrice({
    required double distance,
    required double priceMultiplier,
  }) {
    // Get current time
    final now = DateTime.now();

    // Night time is between 22:00 and 06:00
    bool isNight = now.hour >= 22 || now.hour < 6;

    // Set base rates
    const double baseDayPricePerKm = 1.0;
    const double baseNightPricePerKm = 2.5;

    double ratePerKm = isNight ? baseNightPricePerKm : baseDayPricePerKm;
    double baseFar = isNight ? 10 : 5;

    // Final price calculation
    return distance * ratePerKm * priceMultiplier + baseFar;
  }
}
