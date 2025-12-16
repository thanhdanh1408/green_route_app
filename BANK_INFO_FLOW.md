# Bank Information Management Flow

## Overview
Bank account information is now managed through user profiles, not pre-set in the authentication service. This allows users to add/edit their bank details at any time.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     User Creates Account                        │
│                  (registerNewUser in AuthService)               │
│                                                                 │
│  - No bank info set initially (empty strings only)            │
│  - User gets basic profile with role selection                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│            User Selects Role (Driver/Shipper)                  │
│                 (updateRole in AuthService)                    │
│                                                                 │
│  - Role saved to SharedPreferences                            │
│  - User redirected to Edit Profile screen                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Edit Profile Screen                          │
│            (edit_profile_screen.dart for driver/shipper)       │
│                                                                 │
│  On Load:                                                       │
│  - Loads user_name_$userId                                     │
│  - Loads address_$userId                                       │
│  - Loads bank_name_$userId                                     │
│  - Loads account_number_$userId                                │
│  - Loads account_holder_$userId                                │
│                                                                 │
│  On Save:                                                       │
│  ✅ Saves to user-specific keys (bank_name_$userId, etc)       │
│  ✅ Also saves to global keys for backward compatibility       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Bank Info Persisted & Available                   │
│                                                                 │
│  - Displayed in Wallet withdrawal screens                      │
│  - Accessible to Admin for processing withdrawals              │
│  - Preserved across app sessions (SharedPreferences)           │
│  - Preserved during logout (not cleared)                       │
│  - User can edit anytime in Edit Profile                       │
└─────────────────────────────────────────────────────────────────┘
```

## Key Features

### ✅ Create Account Flow
- **No bank info** pre-set in `fakeUsers` (except for Admin system info)
- User must fill in bank details in Edit Profile screen
- Bank info saved to SharedPreferences with user-specific keys

### ✅ Verified Users
- Existing verified users (idStatus: 'approved') can still:
  - View their bank information
  - Edit their bank information anytime
  - Bank info is preserved across sessions

### ✅ Data Persistence
**SharedPreferences Keys (User-Specific):**
- `bank_name_$userId` - Bank name (e.g., "Vietcombank")
- `account_number_$userId` - Account number (e.g., "1234567890")
- `account_holder_$userId` - Account holder name (e.g., "Nguyễn Văn A")

**SharedPreferences Keys (Global - Fallback):**
- `bank_name` - For compatibility
- `account_number` - For compatibility
- `account_holder` - For compatibility

### ✅ Logout Behavior
Bank information is **NOT** cleared during logout:
```dart
// In logout(), bank info is PRESERVED
if (bankNameUser != null) userSpecificStringKeys['bank_name_$currentUserId'] = bankNameUser;
if (accountNumberUser != null) userSpecificStringKeys['account_number_$currentUserId'] = accountNumberUser;
if (accountHolderUser != null) userSpecificStringKeys['account_holder_$currentUserId'] = accountHolderUser;
```

This ensures:
- Admin can query user bank info after logout
- Bank info persists for next login
- Historical data is maintained

## Implementation Details

### Driver Edit Profile (`lib/features/driver/screens/edit_profile_screen.dart`)
```dart
// Initialize controllers
late TextEditingController bankNameController;
late TextEditingController accountNumberController;
late TextEditingController accountHolderController;

// Load bank info in _loadData()
var bankName = _userId.isNotEmpty ? (prefs.getString('bank_name_$_userId') ?? '') : '';
var accountNumber = _userId.isNotEmpty ? (prefs.getString('account_number_$_userId') ?? '') : '';
var accountHolder = _userId.isNotEmpty ? (prefs.getString('account_holder_$_userId') ?? '') : '';

// Save to both user-specific and global keys
await prefs.setString('bank_name_$userId', bankNameController.text.trim());
await prefs.setString('account_number_$userId', accountNumberController.text.trim());
await prefs.setString('account_holder_$userId', accountHolderController.text.trim());
```

### Shipper Edit Profile (`lib/features/shipper/screens/edit_profile_screen.dart`)
Same implementation as Driver profile.

### Auth Service Changes (`lib/features/auth/services/auth_service.dart`)
```dart
// Removed bank info from fakeUsers (except Admin)
// Before:
'0987654321': {
  'password': '12345678',
  'role': 'driver',
  'name': 'Nguyễn Văn Nam',
  'bank': 'Techcombank',              // ❌ REMOVED
  'accountNumber': '190378291234',    // ❌ REMOVED
  'accountName': 'NGUYEN VAN NAM',    // ❌ REMOVED
}

// After:
'0987654321': {
  'password': '12345678',
  'role': 'driver',
  'name': 'Nguyễn Văn Nam',
  // Bank info must be added in Edit Profile
}

// Added bank keys to logout preservation:
final bankNameUser = prefs.getString('bank_name_$currentUserId');
final accountNumberUser = prefs.getString('account_number_$currentUserId');
final accountHolderUser = prefs.getString('account_holder_$currentUserId');
```

## Admin Requirements
Admin can retrieve user bank information for processing withdrawals:
```dart
// Query user's bank info
final bankName = prefs.getString('bank_name_$userId');
final accountNumber = prefs.getString('account_number_$userId');
final accountHolder = prefs.getString('account_holder_$userId');
```

## Testing Checklist
- ✅ New user creates account → bank info empty
- ✅ User edits profile → bank info persists
- ✅ User logs out → bank info preserved
- ✅ User logs in again → bank info still there
- ✅ User can edit bank info anytime
- ✅ Verified users (idStatus: 'approved') can view/edit bank info
- ✅ No compile errors
- ✅ Bank info displayed in withdrawal workflows

## Files Modified
1. `lib/features/auth/services/auth_service.dart` - Removed bank info from fakeUsers
2. `lib/features/driver/screens/edit_profile_screen.dart` - Already complete
3. `lib/features/shipper/screens/edit_profile_screen.dart` - Already complete
