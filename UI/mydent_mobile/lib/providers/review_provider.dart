import '../models/review.dart';
import 'base_provider.dart';

class ReviewProvider extends BaseProvider<Review> {
  ReviewProvider() : super("Reviews");

  @override
  Review fromJson(data) => Review.fromJson(data as Map<String, dynamic>);
}
