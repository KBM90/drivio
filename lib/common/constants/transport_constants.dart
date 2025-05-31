import 'package:drivio_app/common/models/transporttype.dart';

class TransportConstants {
  static List<TransportType> transports = [
    TransportType(
      id: 1,
      name: 'X Share',
      description: 'Share the ride with up to one co-rider at a time',
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
      name: 'Rent',
      description: 'Pick a car. See the price. Get moving.',
      priceMultiplier: 1.5,
    ),
    TransportType(
      id: 4,

      name: 'Reserve',
      description: 'Book a ride in advance',
      priceMultiplier: 1.3,
    ),
    TransportType(
      id: 5,

      name: 'Hourly',
      description: 'As many stops as you need in one car',
      priceMultiplier: 1.6,
    ),
    TransportType(
      id: 6,

      name: 'XXL',
      description: 'Affordable rides, all to yourself',
      priceMultiplier: 1.4,
    ),
    TransportType(
      id: 7,
      name: 'Saver',
      description: 'Wait to save. Limited availability',
      priceMultiplier: 0.6,
    ),
    TransportType(
      id: 8,
      name: 'Taxi',
      description: 'Local taxi cabs at the tap of a button',
      priceMultiplier: 1.0,
    ),
    TransportType(
      id: 9,
      name: 'Intercity',
      description: 'Go city to city',
      priceMultiplier: 1.8,
    ),
    TransportType(
      id: 10,
      name: 'Delivery',
      description: 'Delivery of food & grocery & more',
      priceMultiplier: 1.1,
    ),
  ];
}
