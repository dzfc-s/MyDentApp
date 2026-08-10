import 'package:MyDent_mobile/models/category.dart';
import 'package:MyDent_mobile/providers/base_provider.dart';

class CategoryProvider extends BaseProvider<Category> {
  CategoryProvider() : super("Categories");

  @override
  Category fromJson(data) {
    return Category.fromJson(data);
  }
}
