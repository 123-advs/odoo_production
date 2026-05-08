import 'package:get/get.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/update_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<StorageService>(StorageService(), permanent: true);
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<UpdateService>(UpdateService(), permanent: true);
  }
}
