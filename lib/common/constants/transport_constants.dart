import 'package:drivio_app/common/models/transporttype.dart';

class TransportConstants {
  static List<TransportType> transports = [
    TransportType(
      id: 1,
      name: 'Standard',
      description: 'The most affordable ride with up to one co-rider at a time',
      priceMultiplier: 0.8,
    ),
    TransportType(
      id: 2,
      name: 'Green',
      description: 'Sustainable rides in electric vehicles',
      priceMultiplier: 1.2,
    ),
    TransportType(
      id: 3,
      name: 'Reserve',
      description: 'Book a ride in advance',
      priceMultiplier: 1.3,
    ),
    TransportType(
      id: 4,
      name: 'Taxi',
      description: 'Local taxi cabs at the tap of a button',
      priceMultiplier: 1.0,
    ),
  ];
}
