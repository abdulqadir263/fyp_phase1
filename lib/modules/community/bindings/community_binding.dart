import 'package:get/get.dart';
import '../controllers/post_controller.dart';
import '../controllers/comment_controller.dart';
import '../controllers/create_post_controller.dart';

/// Binding for community module
/// Registers all community-related controllers
class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    // CommunityService is initialized in main.dart as permanent

    // Register PostController - main controller for posts, bookmarks, filters
    // Use lazyPut with fenix: true to automatically recreate if disposed
    if (!Get.isRegistered<PostController>()) {
      Get.lazyPut<PostController>(() => PostController(), fenix: true);
    }

    // Register CommentController - handles comment operations
    if (!Get.isRegistered<CommentController>()) {
      Get.lazyPut<CommentController>(() => CommentController(), fenix: true);
    }

    // Register CreatePostController - handles post creation
    if (!Get.isRegistered<CreatePostController>()) {
      Get.lazyPut<CreatePostController>(
        () => CreatePostController(),
        fenix: true,
      );
    }
  }
}
