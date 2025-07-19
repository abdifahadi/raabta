# Raabta - Firebase সেটআপ নির্দেশিকা

## ১. প্রয়োজনীয় ফাইল ডাউনলোড করা

### Android এর জন্য:
- Firebase Console থেকে `google-services.json` ফাইল ডাউনলোড করুন
- এই ফাইলটি `android/app/` ফোল্ডারে রাখুন

### iOS এর জন্য:
- Firebase Console থেকে `GoogleService-Info.plist` ফাইল ডাউনলোড করুন
- এই ফাইলটি XCode দিয়ে iOS প্রজেক্টে যোগ করুন

## ২. ডিপেন্ডেন্সি ইনস্টল করা
নিচের কমান্ড চালান:
```
flutter pub get
```

## ৩. অ্যাপ চালানো
নিচের কমান্ড চালান:
```
flutter run
```

## ৪. প্রজেক্ট স্ট্রাকচার

### কোড স্ট্রাকচার
আমরা একটি ক্লিন আর্কিটেকচার ব্যবহার করেছি যাতে ভবিষ্যতে Firebase থেকে অন্য সার্ভিসে (যেমন Supabase বা Appwrite) সহজে পরিবর্তন করা যায়।

- `lib/core/config/`: কনফিগারেশন ফাইল (Firebase options)
- `lib/core/services/`: সার্ভিস ক্লাস (Firebase, Auth)

### সার্ভিস লেয়ার
- `BackendService`: বেকএন্ড সার্ভিসের অ্যাবস্ট্রাক্ট ক্লাস
- `FirebaseService`: Firebase ইমপ্লিমেন্টেশন
- `AuthProvider`: অথেনটিকেশন সার্ভিসের অ্যাবস্ট্রাক্ট ক্লাস
- `FirebaseAuthService`: Firebase অথেনটিকেশন ইমপ্লিমেন্টেশন
- `ServiceLocator`: ডিপেন্ডেন্সি ইনজেকশনের জন্য সার্ভিস লোকেটর

## ৫. সাপোর্টেড প্ল্যাটফর্ম
- Android
- iOS
- Web

## ৬. অথেনটিকেশন মেথড
- ইমেইল/পাসওয়ার্ড
- Google সাইন-ইন 