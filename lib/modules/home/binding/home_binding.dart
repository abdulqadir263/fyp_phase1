import 'package:get/get.dart';
import '../../marketplace/view_model/marketplace_controller.dart';
import '../../weather/view_model/weather_controller.dart';
import '../view_model/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Get.lazyPut(() => MarketplaceController(), fenix: true);
    // Get.lazyPut(() => WeatherController(), fenix: true);
    Get.lazyPut(() => HomeController());

  }
}
