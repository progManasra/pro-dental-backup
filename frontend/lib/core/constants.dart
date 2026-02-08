class AppConstants {
  // داخل docker compose: frontend يتواصل مع backend عبر اسم الخدمة "backend"
  // لكن داخل المتصفح: لازم يوصل عبر جهازك (localhost:8091)
  // لذلك نخليه localhost لأن الويب يشتغل على جهازك.
  static const String apiBaseUrl = "http://localhost:8091/api/v1";
}
