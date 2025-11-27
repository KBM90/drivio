// lib/passenger/ui/passenger_profile_screen.dart
import 'package:drivio_app/common/services/rating_services.dart';
import 'package:drivio_app/common/widgets/report_dialog.dart';
import 'package:drivio_app/driver/providers/driver_passenger_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PassengerProfileScreen extends StatefulWidget {
  final int passengerId;
  const PassengerProfileScreen({super.key, required this.passengerId});

  @override
  State<PassengerProfileScreen> createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch passenger data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final passengerProvider = Provider.of<DriverPassengerProvider>(
        context,
        listen: false,
      );
      if (passengerProvider.currentPassenger == null ||
          passengerProvider.currentPassenger!.userId != widget.passengerId) {
        passengerProvider.getPassenger(widget.passengerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final passengerProvider = Provider.of<DriverPassengerProvider>(
      context,
      listen: true,
    );

    // Show loading indicator while passenger data is being fetched
    if (passengerProvider.currentPassenger == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Passenger Profile'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final passenger = passengerProvider.currentPassenger!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passenger Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Report Passenger',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => ReportDialog(
                      reportedUserId: passenger.userId,
                      reportedUserName: passenger.name,
                      isDriver: true,
                    ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  // Profile Picture Placeholder
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        passenger.profileImage != null
                            ? NetworkImage(passenger.profileImage!)
                            : null,
                    child:
                        passenger.profileImage == null
                            ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            )
                            : null,
                  ),
                  const SizedBox(height: 16),
                  // Passenger Name
                  Text(
                    passenger.name ?? "",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating (Fetched Dynamically)
                  FutureBuilder<Map<String, dynamic>?>(
                    future: RatingService.getRating(passenger.userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      } else if (snapshot.hasError || snapshot.data == null) {
                        return const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 24),
                            SizedBox(width: 4),
                            Text(
                              'N/A',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      } else {
                        final totalRatings =
                            snapshot.data!['totalRatings'] as int;
                        final averageRating =
                            snapshot.data!['averageRating'] as double;

                        // Check if passenger has never been rated
                        if (totalRatings == 0) {
                          return const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_outline,
                                color: Colors.grey,
                                size: 24,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Not rated yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 24,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${averageRating.toStringAsFixed(1)} ($totalRatings)",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Driving Distance Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Distance Traveled',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${passenger.drivingDistance?.toStringAsFixed(1) ?? '0.0'} km',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Preferences Section Header
            const Text(
              'Preferences',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Languages Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.blue, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Languages',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getLanguages(passenger.preferences),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Music Preferences Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.music_note,
                      color: Colors.purple,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Music Preference',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getMusicPreference(passenger.preferences),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Smoking Status Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isSmoker(passenger.preferences)
                          ? Icons.smoking_rooms
                          : Icons.smoke_free,
                      color:
                          _isSmoker(passenger.preferences)
                              ? Colors.orange
                              : Colors.green,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Smoking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isSmoker(passenger.preferences)
                                ? 'Smoker'
                                : 'Non-smoker',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  _isSmoker(passenger.preferences)
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods to extract preferences
  String _getLanguages(Map<String, dynamic>? preferences) {
    if (preferences == null || !preferences.containsKey('speaking')) {
      return 'Not specified';
    }

    final speaking = preferences['speaking'];
    if (speaking is List && speaking.isNotEmpty) {
      // Capitalize each language
      final capitalizedLanguages =
          speaking.map((lang) {
            if (lang is String && lang.isNotEmpty) {
              return lang[0].toUpperCase() + lang.substring(1);
            }
            return lang.toString();
          }).toList();
      return capitalizedLanguages.join(', ');
    } else if (speaking is String && speaking.isNotEmpty) {
      return speaking[0].toUpperCase() + speaking.substring(1);
    }

    return 'Not specified';
  }

  String _getMusicPreference(Map<String, dynamic>? preferences) {
    if (preferences == null || !preferences.containsKey('music')) {
      return 'Not specified';
    }

    final music = preferences['music'];
    if (music is List && music.isNotEmpty) {
      // Capitalize each genre
      final capitalizedGenres =
          music.map((genre) {
            if (genre is String && genre.isNotEmpty) {
              return genre[0].toUpperCase() + genre.substring(1);
            }
            return genre.toString();
          }).toList();
      return capitalizedGenres.join(', ');
    } else if (music is String && music.isNotEmpty) {
      return music[0].toUpperCase() + music.substring(1);
    }

    return 'Not specified';
  }

  bool _isSmoker(Map<String, dynamic>? preferences) {
    if (preferences == null || !preferences.containsKey('smoking')) {
      return false; // Default to non-smoker
    }

    final smoking = preferences['smoking'];
    if (smoking is bool) {
      return smoking;
    } else if (smoking is String) {
      return smoking.toLowerCase() == 'yes' || smoking.toLowerCase() == 'true';
    }

    return false;
  }
}
