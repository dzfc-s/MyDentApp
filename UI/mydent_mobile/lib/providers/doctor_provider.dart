import '../models/doctor.dart';
import 'base_provider.dart';

class DoctorProvider extends BaseProvider<Doctor> {
  DoctorProvider() : super("Doctors");

  @override
  Doctor fromJson(data) => Doctor.fromJson(data as Map<String, dynamic>);
}
