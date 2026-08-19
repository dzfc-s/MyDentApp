import '../models/doctor_specialty.dart';
import 'base_provider.dart';

class DoctorSpecialtyProvider extends BaseProvider<DoctorSpecialty> {
  DoctorSpecialtyProvider() : super("DoctorSpecialties");

  @override
  DoctorSpecialty fromJson(data) =>
      DoctorSpecialty.fromJson(data as Map<String, dynamic>);
}
