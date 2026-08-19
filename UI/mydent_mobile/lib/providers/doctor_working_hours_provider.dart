import '../models/doctor_working_hours.dart';
import 'base_provider.dart';

class DoctorWorkingHoursProvider extends BaseProvider<DoctorWorkingHours> {
  DoctorWorkingHoursProvider() : super("DoctorWorkingHours");

  @override
  DoctorWorkingHours fromJson(data) =>
      DoctorWorkingHours.fromJson(data as Map<String, dynamic>);
}
