# Aasaan Kisaan - Development Progress Report
## Complete Project Documentation for Future Development

**Project Name:** Aasaan Kisaan  
**Version:** 1.1.0 (Post-Onboarding Enhancement)  
**Technology Stack:** Flutter 3.9+, Firebase, Dart, GetX  
**Documentation Date:** February 12, 2026  
**Status:** Phase 1 Completed + Onboarding Flow Enhanced  

---

## 📋 Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Work Completed Till Date](#2-work-completed-till-date)
3. [New Onboarding Flow Implementation](#3-new-onboarding-flow-implementation)
4. [Updated Data Models](#4-updated-data-models)
5. [Complete Module Status](#5-complete-module-status)
6. [Deficiencies in Done Work](#6-deficiencies-in-done-work)
7. [Modules Yet to Be Developed](#7-modules-yet-to-be-developed)
8. [Architecture Overview](#8-architecture-overview)
9. [Firebase Collections Schema](#9-firebase-collections-schema)
10. [Testing Status](#10-testing-status)
11. [Known Issues](#11-known-issues)
12. [Recommendations for Future Development](#12-recommendations-for-future-development)
13. [File Structure Reference](#13-file-structure-reference)

---

## 1. Executive Summary

**Aasaan Kisaan** is a comprehensive mobile application designed to assist farmers with modern agricultural practices. The app supports three user types (Farmer, Expert, Company/Seller) plus Guest access with role-specific features.

### ✅ Key Achievements:
- Complete authentication system with Firebase
- **NEW:** Role-based onboarding flow (Farmer, Expert, Company)
- **NEW:** Dynamic profile completion based on user role
- **NEW:** Guest access support
- AI-powered chatbot (AgriBot) with agriculture-focused responses
- Weather module with agriculture recommendations
- Community module with posts, comments, and bookmarks
- Profile management with Cloudinary image upload
- Multi-platform support (Android, iOS, Web, Desktop)
- GetX state management architecture

### ❌ Pending Development:
- Marketplace module (0% complete)
- Crop Tracker module (0% complete)
- Appointments module (0% complete)
- Push notifications
- Offline mode support

---

## 2. Work Completed Till Date

### 2.1 Authentication Module (100% Complete)

| Feature | Status | File Location |
|---------|--------|---------------|
| Email/Password Login | ✅ Done | `modules/auth/views/login_view.dart` |
| Email/Password Signup | ✅ Done | `modules/auth/views/signup_view.dart` |
| Forgot Password | ✅ Done | `modules/auth/views/forgot_password_view.dart` |
| Role Selection | ✅ **NEW** | `modules/auth/views/role_selection_view.dart` |
| Profile Completion | ✅ **NEW** | `modules/auth/views/profile_completion_view.dart` |
| Guest Access | ✅ Done | `app/data/providers/auth_provider.dart` |
| Auto-login | ✅ Done | `app/data/providers/auth_provider.dart` |

### 2.2 Home Module (100% Complete)

| Feature | Status | File Location |
|---------|--------|---------------|
| Dashboard UI | ✅ Done | `modules/home/views/home_view.dart` |
| Navigation Drawer | ✅ Done | `modules/home/views/home_view.dart` |
| Bottom Navigation | ✅ Done | `modules/home/views/widgets/bottom_nav_bar.dart` |
| Quick Actions Grid | ✅ Done | `modules/home/views/widgets/quick_actions_section.dart` |
| Weather Summary Card | ✅ Done | `modules/home/views/widgets/weather_summary_card.dart` |
| User Info Card | ✅ Done | `modules/home/views/widgets/user_info_card.dart` |

### 2.3 Weather Module (100% Complete)

| Feature | Status | File Location |
|---------|--------|---------------|
| Current Weather Display | ✅ Done | `modules/weather/views/weather_view.dart` |
| 5-day Forecast | ✅ Done | `modules/weather/views/weather_view.dart` |
| Agriculture Recommendations | ✅ Done | `app/data/services/weather_service.dart` |
| Location-based Weather | ✅ Done | `app/data/services/weather_service.dart` |
| Temperature Unit Toggle | ✅ Done | `modules/weather/controllers/weather_controller.dart` |
| Language Toggle (EN/UR) | ✅ Done | `modules/weather/controllers/weather_controller.dart` |

### 2.4 Chatbot Module (100% Complete)

| Feature | Status | File Location |
|---------|--------|---------------|
| Text Chat | ✅ Done | `modules/chatbot/views/chatbot_view.dart` |
| AI Response (Gemini) | ✅ Done | `app/services/gemini_service.dart` |
| Chat History | ✅ Done | `modules/chatbot/controllers/chatbot_controller.dart` |
| Bilingual Support | ✅ Done | `app/services/gemini_service.dart` |
| Agriculture Focus Filter | ✅ Done | `app/services/gemini_service.dart` |

### 2.5 Community Module (95% Complete)

| Feature | Status | File Location |
|---------|--------|---------------|
| Posts Feed | ✅ Done | `modules/community/views/community_view.dart` |
| Create Post | ✅ Done | `modules/community/views/create_post_view.dart` |
| Post Detail | ✅ Done | `modules/community/views/post_detail_view.dart` |
| Comments | ✅ Done | `modules/community/controllers/comment_controller.dart` |
| Bookmarks | ✅ Done | `modules/community/views/bookmarks_view.dart` |
| Category Filter | ✅ Done | `modules/community/views/widgets/category_filter_bar.dart` |
| Post Editing | ❌ Missing | - |
| Comment Replies | ❌ Missing | - |

### 2.6 Profile Module (95% Complete)

| Feature | Status | File Location |
|---------|--------|---------------|
| Profile Display | ✅ Done | `modules/profile/views/profile_view.dart` |
| Edit Profile | ✅ Done | `modules/profile/controllers/profile_controller.dart` |
| Image Upload | ✅ Done | `app/data/services/cloudinary_service.dart` |
| Role-specific Fields | ✅ Done | `modules/profile/views/profile_view.dart` |
| Account Deletion | ⚠️ UI Only | `modules/profile/controllers/profile_controller.dart` |

---

## 3. New Onboarding Flow Implementation

### 3.1 Flow Overview

```
┌─────────────┐     ┌───────────────────┐     ┌────────────────────┐     ┌──────────┐
│   Signup    │ ──▶ │  Role Selection   │ ──▶ │ Profile Completion │ ──▶ │   Home   │
│   Screen    │     │     Screen        │     │      Screen        │     │  Screen  │
└─────────────┘     └───────────────────┘     └────────────────────┘     └──────────┘
                           │
                           │ (Guest Option)
                           ▼
                    ┌──────────┐
                    │   Home   │
                    │ (Limited)│
                    └──────────┘
```

### 3.2 Role Selection Screen

**File:** `lib/modules/auth/views/role_selection_view.dart`

**Features:**
- Three large selectable cards: Farmer, Expert, Company (Seller)
- "Continue as Guest" option at bottom
- Clean, farmer-friendly UI
- Large readable text
- Green theme throughout

**Role Cards:**
| Role | Icon | Description |
|------|------|-------------|
| Farmer | 🌱 (grass) | "I grow crops and manage a farm" |
| Expert | 🎓 (school) | "I provide agricultural advice" |
| Company | 🏪 (store) | "I sell agricultural products" |

### 3.3 Profile Completion Screen

**File:** `lib/modules/auth/views/profile_completion_view.dart`

**Dynamic Fields by Role:**

#### Farmer Profile (Simplest)
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Full Name | Text | ✅ | Min 3 characters |
| Phone Number | Phone | ❌ | Optional |
| Farm Location | Text | ✅ | Required |
| Farm Size | Number | ❌ | In acres |
| Crops Grown | Multi-select | ✅ | Min 1 crop |

**Available Crops:**
- Wheat
- Rice
- Potatoes
- Maize
- Cotton
- Sugarcane
- Canola

#### Expert Profile (Extended)
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Full Name | Text | ✅ | Min 3 characters |
| Phone Number | Phone | ❌ | Optional |
| Location | Text | ❌ | Optional |
| Specialization | Dropdown | ✅ | From predefined list |
| Years of Experience | Number | ✅ | Must be valid number |
| Certifications | Text | ❌ | Optional |
| Short Bio | Text | ❌ | Max 200 characters |
| Available for Appointments | Toggle | ❌ | Default: Yes |

**Specialization Options:**
- Crop Management
- Pest & Disease Control
- Soil Science
- Irrigation Systems
- Livestock Management
- Agricultural Machinery
- Agri Business & Marketing
- Organic Farming
- Fertilizer & Nutrient Management

#### Company/Seller Profile
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Company Name | Text | ✅ | Required |
| Owner Name | Text | ❌ | Optional |
| Phone Number | Phone | ❌ | Optional |
| Business Location | Text | ❌ | Optional |
| Business Type | Dropdown | ✅ | From predefined list |
| Years in Business | Number | ❌ | Optional |
| License Number | Text | ❌ | Optional |
| Business Description | Text | ❌ | Max 200 characters |

**Business Type Options:**
- Seeds Supplier
- Fertilizer Dealer
- Pesticide Dealer
- Agricultural Equipment
- Crop Buyer
- Livestock Trader
- General Agri Store

### 3.4 Controller Logic

**File:** `lib/modules/auth/controllers/onboarding_controller.dart`

**Key Methods:**
```dart
// Role Selection
void selectRole(String role)          // Select role and navigate to profile completion
void continueAsGuest()                // Skip to home with guest mode

// Crop Selection (Farmer)
void toggleCropSelection(String crop) // Add/remove crop from selection
bool isCropSelected(String crop)      // Check if crop is selected

// Validation
bool _validateFarmerProfile()         // Validate farmer-specific fields
bool _validateExpertProfile()         // Validate expert-specific fields
bool _validateCompanyProfile()        // Validate company-specific fields
bool validateProfile()                // Main validation based on role

// Profile Save
Future<void> saveProfile()            // Save completed profile to Firestore
```

### 3.5 Navigation Flow

**Routes Added:**
```dart
static const ROLE_SELECTION = '/role-selection';
static const PROFILE_COMPLETION = '/profile-completion';
```

**Binding:**
```dart
// lib/app/bindings/onboarding_binding.dart
class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => OnboardingController());
  }
}
```

---

## 4. Updated Data Models

### 4.1 UserModel (Updated)

**File:** `lib/app/data/models/user_model.dart`

```dart
class UserModel {
  // ========== EXISTING FIELDS ==========
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String userType;           // 'farmer', 'expert', 'company', 'guest'
  final String? location;
  final String? farmSize;
  final String? specialization;
  final String? companyName;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // ========== NEW FARMER FIELDS ==========
  final List<String>? cropsGrown;  // Multi-select crops
  
  // ========== NEW EXPERT FIELDS ==========
  final int? yearsOfExperience;
  final String? certifications;
  final String? bio;               // Max 200 chars
  final bool? isAvailableForConsultation;
  
  // ========== NEW COMPANY FIELDS ==========
  final String? businessType;
  final int? yearsInBusiness;
  final String? licenseNumber;
  final String? businessDescription;  // Max 200 chars
  
  // ========== PROFILE STATUS ==========
  final bool isProfileComplete;    // Track onboarding completion
}
```

### 4.2 Firestore Schema Update

**Collection: `users`**
```json
{
  // Common fields
  "uid": "string",
  "name": "string",
  "email": "string",
  "phone": "string",
  "userType": "farmer|expert|company|guest",
  "location": "string|null",
  "profileImage": "string|null",
  "createdAt": "timestamp",
  "updatedAt": "timestamp|null",
  "isProfileComplete": "boolean",
  
  // Farmer-specific
  "farmSize": "string|null",
  "cropsGrown": ["string"]|null,
  
  // Expert-specific
  "specialization": "string|null",
  "yearsOfExperience": "number|null",
  "certifications": "string|null",
  "bio": "string|null",
  "isAvailableForConsultation": "boolean|null",
  
  // Company-specific
  "companyName": "string|null",
  "businessType": "string|null",
  "yearsInBusiness": "number|null",
  "licenseNumber": "string|null",
  "businessDescription": "string|null"
}
```

---

## 5. Complete Module Status

| Module | Completion | Status | Priority |
|--------|------------|--------|----------|
| **Authentication** | 100% | ✅ Complete | - |
| **Onboarding** | 100% | ✅ **NEW** | - |
| **Home** | 100% | ✅ Complete | - |
| **Profile** | 95% | ⚠️ Minor gaps | - |
| **Weather** | 100% | ✅ Complete | - |
| **Chatbot** | 100% | ✅ Complete | - |
| **Community** | 95% | ⚠️ Minor gaps | - |
| **Marketplace** | 0% | ❌ Not started | 🔴 HIGH |
| **Crop Tracker** | 0% | ❌ Not started | 🔴 HIGH |
| **Appointments** | 0% | ❌ Not started | 🟡 MEDIUM |

---

## 6. Deficiencies in Done Work

### 6.1 Critical Issues

| Issue | Module | Impact | Priority |
|-------|--------|--------|----------|
| Cloudinary credentials hardcoded | CloudinaryService | Security vulnerability | 🔴 HIGH |
| No Firebase Security Rules | All modules | Security risk | 🔴 HIGH |
| Account deletion not implemented | Profile | GDPR compliance issue | 🟡 MEDIUM |
| Post editing not available | Community | UX limitation | 🟡 MEDIUM |

### 6.2 Code Quality Issues

| Issue | Location | Description |
|-------|----------|-------------|
| Duplicate constants files | `core/constants/` and `core/values/` | Same constants in two places |
| Mixed naming conventions | Throughout codebase | `camelCase` vs `SCREAMING_CASE` |
| Empty module files | Marketplace, Crop Tracker, Appointments | Scaffolded but empty |
| Inconsistent error handling | Various controllers | Some use try-catch, others don't |
| Limited unit test coverage | `test/` directory | Only basic tests exist |

### 6.3 Missing Features in Completed Modules

| Module | Missing Feature | Impact |
|--------|-----------------|--------|
| Auth | Social login (Google/Facebook) | User convenience |
| Profile | Email change | User flexibility |
| Community | Post editing | Content management |
| Community | Comment replies | Discussion depth |
| Community | Search functionality | Content discovery |
| Community | Content moderation | Quality control |
| Chatbot | Image sending | Enhanced interaction |
| Weather | Saved locations | User preference |

### 6.4 UI/UX Issues

| Issue | Location | Recommendation |
|-------|----------|----------------|
| No offline indicators | App-wide | Add network status banner |
| Limited error messages | Various | Use more descriptive errors |
| No loading skeletons | Lists | Add shimmer effects |
| No pull-to-refresh on all screens | Various | Add where applicable |

---

## 7. Modules Yet to Be Developed

### 7.1 Marketplace Module (🔴 HIGH PRIORITY)

**Purpose:** Buy/sell agricultural products

**Suggested Features:**
- Product listing with images
- Category filtering (seeds, fertilizers, equipment, etc.)
- Price management
- Contact seller feature
- Product search
- Favorite products
- Product views counter

**Suggested Data Model:**
```dart
class ProductModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;
  final double price;
  final String unit;           // kg, piece, bag
  final String category;
  final List<String> images;
  final String location;
  final DateTime createdAt;
  final bool isAvailable;
  final int views;
  final String? contactPhone;
}
```

**Estimated Effort:** 3-4 weeks

### 7.2 Crop Tracker Module (🔴 HIGH PRIORITY)

**Purpose:** Track crop growth and expenses

**Suggested Features:**
- Crop registration
- Growth stage tracking
- Activity logging (watering, fertilizing, spraying)
- Expense tracking
- Harvest recording
- Yield analysis
- Photo documentation

**Suggested Data Models:**
```dart
class CropModel {
  final String id;
  final String userId;
  final String cropName;
  final String variety;
  final double areaSize;
  final String areaUnit;
  final DateTime plantingDate;
  final DateTime? harvestDate;
  final String status;         // growing, harvested, failed
  final double? yieldAmount;
}

class ActivityModel {
  final String id;
  final String cropId;
  final String type;           // watering, fertilizing, spraying
  final String notes;
  final DateTime date;
  final List<String>? images;
}

class ExpenseModel {
  final String id;
  final String cropId;
  final String category;       // seeds, fertilizer, labor
  final double amount;
  final String description;
  final DateTime date;
}
```

**Estimated Effort:** 4-5 weeks

### 7.3 Appointments Module (🟡 MEDIUM PRIORITY)

**Purpose:** Book consultations with agricultural experts

**Suggested Features:**
- Expert listing and search
- Availability calendar
- Appointment booking
- Reschedule/Cancel
- Video call integration
- Rating and reviews
- Appointment history

**Suggested Data Model:**
```dart
class AppointmentModel {
  final String id;
  final String farmerId;
  final String expertId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status;         // pending, confirmed, completed, cancelled
  final String topic;
  final String? notes;
  final String? meetingLink;
  final DateTime createdAt;
}
```

**Estimated Effort:** 3-4 weeks

### 7.4 Additional Modules to Consider

| Module | Description | Priority | Effort |
|--------|-------------|----------|--------|
| **Notifications** | Push notifications system | 🟡 MEDIUM | 1-2 weeks |
| **Settings** | App preferences | 🟢 LOW | 1 week |
| **Offline Mode** | Local data caching | 🟡 MEDIUM | 2-3 weeks |
| **Disease Detection** | AI image analysis | 🟢 LOW | 3-4 weeks |
| **Market Prices** | Real-time commodity prices | 🟢 LOW | 2 weeks |
| **Analytics** | Usage analytics | 🟢 LOW | 1 week |

---

## 8. Architecture Overview

### 8.1 Design Pattern

The project follows **Clean Architecture** with **GetX MVC** pattern:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────┐ │
│  │  Views  │  │Widgets  │  │ Themes  │  │  Translations   │ │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────────┬────────┘ │
└───────┼───────────┼───────────┼────────────────┼────────────┘
        │           │           │                │
┌───────┼───────────┼───────────┼────────────────┼────────────┐
│       ▼           ▼           ▼                ▼            │
│                  BUSINESS LOGIC LAYER                        │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────────┐ │
│  │  Controllers  │  │   Bindings    │  │     Routes       │ │
│  └───────┬───────┘  └───────┬───────┘  └────────┬─────────┘ │
└──────────┼──────────────────┼───────────────────┼───────────┘
           │                  │                   │
┌──────────┼──────────────────┼───────────────────┼───────────┐
│          ▼                  ▼                   ▼           │
│                     DATA LAYER                              │
│  ┌─────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐  │
│  │ Models  │  │ Services │  │Providers │  │  Constants  │  │
│  └─────────┘  └──────────┘  └──────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────┐
│                   EXTERNAL SERVICES                          │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌─────────────┐│
│  │ Firebase │  │ Cloudinary│  │Weather API│ │  Gemini AI  ││
│  └──────────┘  └───────────┘  └──────────┘  └─────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### 8.2 Service Registration (main.dart)

```dart
// Core services initialized as permanent
Get.put(FirebaseService(), permanent: true);
Get.put(CloudinaryService(), permanent: true);
Get.put(WeatherService(), permanent: true);
Get.put(GeminiService(), permanent: true);
Get.put(AuthProvider(), permanent: true);
Get.put(CommunityService(), permanent: true);
```

### 8.3 Route Registration

```dart
// Registered Routes
'/login'              → LoginView + AuthBinding
'/forgot-password'    → ForgotPasswordView + AuthBinding
'/role-selection'     → RoleSelectionView + OnboardingBinding  // NEW
'/profile-completion' → ProfileCompletionView + OnboardingBinding  // NEW
'/home'               → HomeView + HomeBinding
'/profile'            → ProfileView + ProfileBinding
'/weather'            → WeatherView + WeatherBinding
'/chatbot'            → ChatbotView + ChatbotBinding
'/community'          → CommunityView + CommunityBinding
'/community/create'   → CreatePostView + CommunityBinding
'/community/post/:id' → PostDetailView + CommunityBinding
'/community/bookmarks'→ BookmarksView + CommunityBinding
```

---

## 9. Firebase Collections Schema

### 9.1 users Collection

```javascript
{
  // Document ID: user's Firebase Auth UID
  
  // Common fields
  "name": "string",
  "email": "string",
  "phone": "string",
  "userType": "farmer|expert|company|guest",
  "location": "string|null",
  "profileImage": "string|null",  // Cloudinary URL
  "createdAt": "timestamp",
  "updatedAt": "timestamp|null",
  "isProfileComplete": "boolean",
  
  // Farmer-specific
  "farmSize": "string|null",
  "cropsGrown": ["Wheat", "Rice", ...]|null,
  
  // Expert-specific
  "specialization": "string|null",
  "yearsOfExperience": "number|null",
  "certifications": "string|null",
  "bio": "string|null",
  "isAvailableForConsultation": "boolean|null",
  
  // Company-specific
  "companyName": "string|null",
  "businessType": "string|null",
  "yearsInBusiness": "number|null",
  "licenseNumber": "string|null",
  "businessDescription": "string|null"
}
```

### 9.2 communityPosts Collection

```javascript
{
  "userId": "string",
  "userName": "string",
  "userAvatarUrl": "string|null",
  "title": "string",
  "description": "string",
  "imageUrls": ["string"],
  "category": "crops|livestock|equipment|weather|market",
  "createdAt": "timestamp",
  "updatedAt": "timestamp|null",
  "commentsCount": "number",
  "bookmarksCount": "number",
  "bookmarkedBy": ["userId"]
}
```

### 9.3 comments Collection

```javascript
{
  "postId": "string",
  "userId": "string",
  "userName": "string",
  "userAvatarUrl": "string|null",
  "text": "string",
  "createdAt": "timestamp",
  "parentCommentId": "string|null"
}
```

### 9.4 chatMessages Subcollection (under users)

```javascript
{
  "text": "string",
  "isUser": "boolean",
  "timestamp": "timestamp",
  "language": "en|ur"
}
```

---

## 10. Testing Status

### 10.1 Current Coverage

| Test Type | Coverage | Status |
|-----------|----------|--------|
| Unit Tests | ~10% | ⚠️ Basic tests added |
| Widget Tests | ~5% | ⚠️ Minimal |
| Integration Tests | 0% | ❌ Not implemented |

### 10.2 Test Files

```
test/
├── widget_test.dart      # Basic Flutter test (default)
└── onboarding_test.dart  # NEW: Onboarding validation tests
```

### 10.3 New Tests Added (onboarding_test.dart)

**Test Groups:**
- Farmer Profile Validation (6 tests)
- Expert Profile Validation (5 tests)
- Company Profile Validation (5 tests)
- Role Selection (4 tests)
- Available Crops List (2 tests)
- Expert Specializations List (2 tests)
- Business Types List (2 tests)

**Total: 26 unit tests for onboarding validation**

**Running Tests:**
```bash
flutter test test/onboarding_test.dart
```

---

## 11. Known Issues

| ID | Issue | Module | Severity | Status |
|----|-------|--------|----------|--------|
| 1 | Cloudinary credentials hardcoded | CloudinaryService | 🔴 HIGH | Open |
| 2 | No Firebase Security Rules | All | 🔴 HIGH | Open |
| 3 | Account deletion not working | Profile | 🟡 MEDIUM | Open |
| 4 | Post editing missing | Community | 🟡 MEDIUM | Open |
| 5 | Comment replies not implemented | Community | 🟢 LOW | Open |
| 6 | Signup route not registered separately | Auth | 🟢 LOW | Open |
| 7 | Linux Firebase not configured | Core | 🟢 LOW | Open |
| 8 | No error boundary | App-wide | 🟡 MEDIUM | Open |

---

## 12. Recommendations for Future Development

### 12.1 Immediate Priorities (Next 2 Sprints)

1. **Security Fixes**
   - Move Cloudinary credentials to `.env`
   - Implement Firebase Security Rules
   - Add input sanitization

2. **Implement Marketplace Module**
   - Product listing
   - Add/Edit products
   - Category filtering
   - Contact seller

3. **Implement Crop Tracker Module**
   - Crop registration
   - Activity logging
   - Expense tracking

### 12.2 Short-term Goals (Sprints 3-4)

1. **Appointments Module**
   - Expert profiles
   - Basic booking flow
   - Appointment calendar

2. **Enhanced Features**
   - Post editing in Community
   - Search functionality
   - Push notifications

3. **Testing**
   - Increase unit test coverage to 50%
   - Add widget tests for critical flows
   - Add integration tests for auth flow

### 12.3 Long-term Goals

1. **AI Features**
   - Crop disease detection from images
   - Yield prediction based on data
   - Personalized recommendations

2. **Business Features**
   - Payment integration
   - Subscription plans
   - Analytics dashboard

3. **Platform Expansion**
   - SMS notifications
   - WhatsApp integration
   - Web admin panel

---

## 13. File Structure Reference

### 13.1 New Files Added

```
lib/
├── app/
│   ├── bindings/
│   │   └── onboarding_binding.dart        # NEW
│   └── routes/
│       ├── app_routes.dart                # UPDATED (new routes)
│       └── app_pages.dart                 # UPDATED (new pages)
│
├── modules/
│   └── auth/
│       ├── controllers/
│       │   ├── auth_controller.dart       # Existing
│       │   └── onboarding_controller.dart # NEW
│       └── views/
│           ├── login_view.dart            # Existing
│           ├── signup_view.dart           # Existing
│           ├── forgot_password_view.dart  # Existing
│           ├── role_selection_view.dart   # NEW
│           └── profile_completion_view.dart # NEW

test/
├── widget_test.dart                       # Existing
└── onboarding_test.dart                   # NEW
```

### 13.2 Modified Files

| File | Changes Made |
|------|--------------|
| `app/data/models/user_model.dart` | Added new fields for farmer, expert, company |
| `app/data/providers/auth_provider.dart` | Updated signup flow, profile completion check |
| `app/routes/app_routes.dart` | Added ROLE_SELECTION, PROFILE_COMPLETION routes |
| `app/routes/app_pages.dart` | Added new page registrations |

### 13.3 Complete Directory Structure

```
lib/
├── main.dart
├── firebase_options.dart
│
├── app/
│   ├── bindings/
│   │   ├── auth_binding.dart
│   │   ├── onboarding_binding.dart    # NEW
│   │   ├── home_binding.dart
│   │   ├── profile_binding.dart
│   │   ├── weather_binding.dart
│   │   └── chatbot_binding.dart
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_model.dart        # UPDATED
│   │   │   └── weather_model.dart
│   │   ├── providers/
│   │   │   ├── auth_provider.dart     # UPDATED
│   │   │   └── chatbot_provider.dart
│   │   └── services/
│   │       ├── firebase_service.dart
│   │       ├── cloudinary_service.dart
│   │       └── weather_service.dart
│   │
│   ├── routes/
│   │   ├── app_pages.dart             # UPDATED
│   │   └── app_routes.dart            # UPDATED
│   │
│   ├── services/
│   │   └── gemini_service.dart
│   │
│   ├── themes/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   │
│   ├── translations/
│   │   ├── app_translations.dart
│   │   ├── en_us.dart
│   │   └── ur_pk.dart
│   │
│   ├── utils/
│   │   ├── app_snackbar.dart
│   │   ├── constants.dart
│   │   ├── helpers.dart
│   │   └── validators.dart
│   │
│   └── widgets/
│       ├── custom_appbar.dart
│       ├── custom_button.dart
│       ├── custom_card.dart
│       ├── custom_text_field.dart
│       ├── empty_state.dart
│       ├── error_view.dart
│       ├── loading_overlay.dart
│       └── loading_widget.dart
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── errors/
│   │   └── exceptions.dart
│   ├── utils/
│   │   └── validators.dart
│   └── values/
│       ├── colors.dart
│       ├── constants.dart
│       └── strings.dart
│
└── modules/
    ├── auth/
    │   ├── controllers/
    │   │   ├── auth_controller.dart
    │   │   └── onboarding_controller.dart  # NEW
    │   └── views/
    │       ├── login_view.dart
    │       ├── signup_view.dart
    │       ├── forgot_password_view.dart
    │       ├── role_selection_view.dart    # NEW
    │       └── profile_completion_view.dart # NEW
    │
    ├── home/
    │   ├── controllers/
    │   │   └── home_controller.dart
    │   └── views/
    │       ├── home_view.dart
    │       └── widgets/
    │
    ├── profile/
    │   ├── controllers/
    │   │   └── profile_controller.dart
    │   └── views/
    │       └── profile_view.dart
    │
    ├── weather/
    │   ├── controllers/
    │   │   └── weather_controller.dart
    │   └── views/
    │       ├── weather_view.dart
    │       └── weather_detail_view.dart
    │
    ├── chatbot/
    │   ├── controllers/
    │   │   └── chatbot_controller.dart
    │   ├── models/
    │   │   └── message_model.dart
    │   ├── views/
    │   │   └── chatbot_view.dart
    │   └── widgets/
    │
    ├── community/
    │   ├── bindings/
    │   │   └── community_binding.dart
    │   ├── controllers/
    │   ├── models/
    │   ├── services/
    │   │   └── community_service.dart
    │   └── views/
    │
    ├── marketplace/        # ❌ Empty - TO BE DEVELOPED
    ├── crop_tracker/       # ❌ Empty - TO BE DEVELOPED
    └── appointments/       # ❌ Empty - TO BE DEVELOPED
```

---

## Document Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Jan 24, 2026 | Abdul Qadir | Initial documentation |
| 1.1 | Feb 12, 2026 | System | Added onboarding flow documentation |

---

**End of Documentation**

*This document should be updated with each major release or when significant changes are made to the codebase.*

