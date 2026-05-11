<<<<<<< HEAD
# Mood App

تطبيق "Current Mood" هو نظام تفاعلي لتحديد حالة المزاج من صورة وجه المستخدم وتقديم توصيات صوتية ومرئية تتناسب مع الحالة.

## الهدف

التطبيق يساعد المستخدمين على معرفة مزاجهم الحالي عن طريق تحليل صور الوجه باستخدام نموذج TFLite، ويقدم توصيات فيديو وقصص وموسيقى لرفع الحالة المزاجية أو التعامل مع المشاعر السلبية.

## المميزات الرئيسية

- شاشة ترحيب وبدء سريع.
- تسجيل دخول مستخدم عبر Firebase Auth.
- دعم الضيوف "Continue as Guest".
- تحميل صورة من المعرض أو التقاط صورة بالكاميرا.
- تحليل الحالة المزاجية عبر نموذج `TFLite` من ملف `assets/model/ferplus_model_pd_best.tflite`.
- استخدام ML Kit لاكتشاف الوجه قبل التعرف على المشاعر.
- حفظ سجل المزاج محلياً عبر `SharedPreferences`.
- رفع الصورة وبيانات المزاج إلى Firebase Storage و Cloud Firestore.
- تنبيه عبر خدمة إشعارات حالة المزاج في الحالات السلبية.
- عرض توصيات: فيديو، قصص، قوائم تشغيل، أنشطة.

## بنية المشروع

- `lib/main.dart`: نقطة البداية، تهيئة Firebase، تهيئة خدمة الإشعارات.
- `lib/screens/`: يحتوي على كل الشاشات الرئيسية مثل:
  - `splash_screen.dart`
  - `login_screen.dart`
  - `signup_screen.dart`
  - `detection_screen.dart`
  - `recommendations_screen.dart`
  - `mood_history_screen.dart`
  - `live_detection_screen.dart`
  - `stories_screen.dart`
  - `videos_screen.dart`
  - `playlists_screen.dart`
  - `activities_screen.dart`
- `lib/services/`:
  - `emotion_tflite_helper.dart`: واجهة تحميل النموذج وتشغيل التنبؤات.
  - `mood_alert_notification_service.dart`: إعداد إشعارات التطبيق.
  - `mood_history_service.dart`: حفظ وتحميل سجل المزاج محلياً.
- `lib/models/mood_history_entry.dart`: نموذج بيانات سجل المزاج.
- `lib/widgets/background_widget.dart`: واجهة الخلفية العامة للشاشات.

## المتطلبات

- Flutter SDK >= 3.9.2
- Android أو iOS أو Web مدعوم.
- إعداد Firebase لمشروع Android و/أو iOS.

## إعداد المشروع

1. ثبت الحزم:

```bash
flutter pub get
```

2. تأكد من وجود ملف `firebase_options.dart` الصحيح في `lib/`.
   - هذا الملف يولد بواسطة FlutterFire CLI بعد إعداد مشروع Firebase.

3. أضف ملفات إعدادات Firebase إلى المشاريع:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

4. شغّل التطبيق:

```bash
flutter run
```

## إعداد Firebase

التطبيق يستخدم:
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`

يجب:
- تفعيل تسجيل الدخول بالبريد الإلكتروني/كلمة المرور في Firebase Authentication.
- إعداد مجموعة `users` في Firestore.
- التأكد من صلاحيات القراءة/الكتابة المناسبة في قواعد Firestore وStorage أثناء التطوير.

## كيف يعمل التعرف على المزاج

1. المستخدم يحمّل صورة أو يلتقط صورة.
2. التطبيق يستخدم `google_mlkit_face_detection` لاكتشاف الوجه.
3. يتم تمرير الصورة إلى نموذج `TFLite` (`ferplus_model_pd_best.tflite`).
4. النموذج يعيد الشعور المتوقع مع نسبة ثقة.
5. التطبيق يحفظ السجل محلياً ويُرسل تسجيل المزاج إلى Firestore.
6. التطبيق يعرض شاشة توصيات بناءً على المزاج المكتشف.

## تخزين البيانات

- يتم حفظ حالة المستخدم وتسجيل الدخول في `SharedPreferences`.
- يتم حفظ سجل المزاج محلياً باستخدام JSON داخل `SharedPreferences`.
- عند تسجيل الدخول بعد استخدام التطبيق كضيف، يتم نقل السجل المحلي من مفتاح الضيف إلى مفتاح المستخدم الحالي.

## الملاحظات والقصور الحالية

- `README.md` القديم كان افتراضي ولم يصف التطبيق.
- ملف `training/` موجود لكنه غير مذكور في الواجهة النهائية للتطبيق. يمكن استخدامه لتدريب النموذج، لكنه ليس جزءاً من واجهة التطبيق المباشرة.
- لا يوجد اختبارات مخصصة مؤكدة، فقط الاختبار الافتراضي `test/widget_test.dart`.
- يجب التأكد من إعداد `firebase_options.dart` وملفات Google config قبل التشغيل.

## الاعتمادات (dependencies)

أهم الحزم المستخدمة:
- `shared_preferences`
- `fl_chart`
- `tflite_flutter`
- `image`
- `camera`
- `http`
- `url_launcher`
- `image_picker`
- `file_picker`
- `crypto`
- `firebase_core`
- `firebase_auth`
- `firebase_storage`
- `cloud_firestore`
- `google_mlkit_face_detection`
- `flutter_local_notifications`

## ملاحظات إضافية

- إذا كنت تستخدم التطبيق لأول مرة، فتأكد من تسجيل الدخول والتحقق من البريد الإلكتروني.
- يمكن للمستخدم الاستمرار كضيف، لكن بيانات الضيف تُخزن محلياً فقط إلى أن يتم تسجيل الدخول.
- شاشة التوصيات تعتمد على المشاعر التي تم الكشف عنها وتعرض محتوى مختلفاً حسب الحالة.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
>>>>>>> ea197f17cc03b509884fd6c8629e1b1c6c547a37
