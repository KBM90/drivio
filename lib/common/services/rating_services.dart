import 'package:drivio_app/common/models/rating.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RatingService {
  static Future<Map<String, dynamic>?> getRating(int ratedUserId) async {
    try {
      final response = await Supabase.instance.client
          .from('ratings')
          .select('*, rated_by_user:users!rated_by(*)')
          .eq('rated_user', ratedUserId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      final ratings = data.map((e) => Rating.fromJson(e)).toList();

      if (ratings.isEmpty) {
        return {'averageRating': 0.0, 'ratings': [], 'totalRatings': 0};
      }

      final totalRating = ratings.fold(0, (sum, item) => sum + item.rating);
      final averageRating = totalRating / ratings.length;

      return {
        'averageRating': averageRating,
        'ratings':
            data, // Keeping original JSON list as per previous implementation's return structure expectation if needed, or we can return List<Rating>
        'totalRatings': ratings.length,
      };
    } catch (e) {
      debugPrint('Error fetching rating: $e');
      return null;
    }
  }
}
