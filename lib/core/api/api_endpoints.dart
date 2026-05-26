class ApiEndpoints {

  /*
  -------------------------
  BASE URL
  -------------------------
  */

  static const String baseUrl =
      "https://api.aktuhub.in/api";

  /*
  -------------------------
  IMAGE URLS
  -------------------------
  */

  static const String courseThumbnail =
      "$baseUrl/uploads/course_thumbnails/";

  static const String profileImage =
      "$baseUrl/uploads/profile_images/";

  static const String certificate =
      "$baseUrl/uploads/certificates/";

  static const String commonImages =
      "$baseUrl/uploads/images/";

  /*
  -------------------------
  AUTH
  -------------------------
  */

  static const String login =
      "$baseUrl/auth/login";

  static const String register =
      "$baseUrl/auth/register";

  static const String verifyOtp =
      "$baseUrl/auth/verify-otp";

  static const String forgotPassword =
      "$baseUrl/auth/forgot-password";

  static const String verifyResetOtp =
      "$baseUrl/auth/verify-reset-otp";

  static const String resetPassword =
      "$baseUrl/auth/reset-password";

  /*
  -------------------------
  COURSES
  -------------------------
  */

  static const String courses =
      "$baseUrl/courses";

  static const String courseDetail =
      "$baseUrl/course-detail";

  /*
  -------------------------
  LESSONS
  -------------------------
  */

  static const String lessonVideo =
      "$baseUrl/lesson-video";

  /*
  -------------------------
  STUDENT
  -------------------------
  */

  static const String dashboard =
      "$baseUrl/student-dashboard";

  static const String progress =
      "$baseUrl/progress";

  /*
  -------------------------
  REVIEWS
  -------------------------
  */

  static const String reviews =
      "$baseUrl/reviews";

  /*
  -------------------------
  NOTIFICATIONS
  -------------------------
  */

  static const String notifications =
      "$baseUrl/notifications";

  /*
  -------------------------
  LIVE CLASSES
  -------------------------
  */

  static const String live =
      "$baseUrl/live";
}