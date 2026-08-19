import '../models/service_category.dart';
import 'base_provider.dart';

class ServiceCategoryProvider extends BaseProvider<ServiceCategory> {
  ServiceCategoryProvider() : super("ServiceCategories");

  @override
  ServiceCategory fromJson(data) =>
      ServiceCategory.fromJson(data as Map<String, dynamic>);
}
