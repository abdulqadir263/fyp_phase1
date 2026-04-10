import 'package:get/get.dart';
import '../view_model/weather_controller.dart';

class WeatherBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => WeatherController());
  }
}
