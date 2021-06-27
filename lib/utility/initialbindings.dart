import 'package:get/get.dart';
import 'package:ytdownloader/controllers/variable_controller.dart';
import 'package:ytdownloader/controllers/videocontroller.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(VideoController(), permanent: true);
    Get.put(VariableController(), permanent: true);
  }
}
