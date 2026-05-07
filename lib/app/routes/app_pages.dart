import 'package:get/get.dart';

import '../modules/login/login_controller.dart';
import '../modules/login/login_view.dart';
import '../modules/mo_detail/mo_detail_controller.dart';
import '../modules/mo_detail/mo_detail_view.dart';
import '../modules/mo_list/mo_list_controller.dart';
import '../modules/mo_list/mo_list_view.dart';
import '../modules/splash/splash_controller.dart';
import '../modules/splash/splash_view.dart';
import '../modules/workcenter_picker/workcenter_picker_controller.dart';
import '../modules/workcenter_picker/workcenter_picker_view.dart';
import 'app_routes.dart';

abstract class AppPages {
  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      // Eager Get.put because SplashView body never reads `controller` —
      // lazyPut would skip onInit/onReady. (See odoo_attendance gotcha 2.)
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => LoginController());
      }),
    ),
    GetPage(
      name: AppRoutes.workcenterPicker,
      page: () => const WorkcenterPickerView(),
      binding: BindingsBuilder(() {
        Get.put(WorkcenterPickerController());
      }),
    ),
    GetPage(
      name: AppRoutes.moList,
      page: () => const MoListView(),
      binding: BindingsBuilder(() {
        Get.put(MoListController());
      }),
    ),
    GetPage(
      name: AppRoutes.moDetail,
      page: () => const MoDetailView(),
      binding: BindingsBuilder(() {
        // moId passed via Get.parameters['id'] on navigation.
        final id = int.parse(Get.parameters['id']!);
        Get.put(MoDetailController(moId: id));
      }),
    ),
  ];
}
