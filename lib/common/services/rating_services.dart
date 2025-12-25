import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RatingService {
  static Future<Map<String, dynamic>?> getRating(int ratedUserId) async {
    try {
      final response = await Supabase.instance.client
          .from('ratings')
          .select('rating')
          .eq('rated_user', ratedUserId);

      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) {
        debugPrint('No ratings found for user: $ratedUserId');
        return {'averageRating': 0.0, 'ratings': [], 'totalRatings': 0};
      }

      // Calculate average from raw data
      int totalRating = 0;
      int validRatings = 0;

      for (var item in data) {
        if (item['rating'] != null) {
          totalRating += item['rating'] as int;
          validRatings++;
        }
      }

      if (validRatings == 0) {
        return {'averageRating': 0.0, 'ratings': [], 'totalRatings': 0};
      }

      final averageRating = totalRating / validRatings;

      return {
        'averageRating': averageRating,
        'ratings': data,
        'totalRatings': validRatings,
      };
    } catch (e, stackTrace) {
      debugPrint('Error fetching rating: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
