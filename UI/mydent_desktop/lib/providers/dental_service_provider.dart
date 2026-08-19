import '../models/dental_service.dart';
import 'base_provider.dart';

class DentalServiceProvider extends BaseProvider<DentalService> {
  DentalServiceProvider() : super("DentalServices");

  @override
  DentalService fromJson(data) =>
      DentalService.fromJson(data as Map<String, dynamic>);
}
