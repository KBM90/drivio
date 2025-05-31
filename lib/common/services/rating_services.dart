import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RatingService {
  static const String baseUrl = Api.baseUrl; // Replace with your actual URL

  static Future<Map<String, dynamic>?> getRating(int ratedUserId) async {
    try {
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      final uri = Uri.parse('$baseUrl/getUserRatings?rated_user=$ratedUserId');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return {
            'averageRating': (data['average_rating'] as num?)?.toDouble(),
            'ratings': data['ratings'],
            'totalRatings': data['total_ratings'] ?? 0,
          };
        } else {
          print('API Error: ${data['message']}');
          return null;
        }
      } else {
        print(
          'Failed to fetch rating: ${response.statusCode} - ${data['message'] ?? 'No message'}',
        );
        return null;
      }
    } catch (e) {
      print('Error fetching rating: $e');
      return null;
    }
  }
}
