# TODO: Add Logout Feature for Account Switching

## Completed Tasks
- [x] Add logout method to AuthService
- [x] Add logout button to shipper settings screen
- [x] Add logout button to driver settings screen
- [x] Fix null value error in ConfirmBookingScreen

## Summary
- Added logout functionality to AuthService that clears all user data from SharedPreferences
- Added logout buttons to both shipper and driver settings screens
- Fixed null value error in ConfirmBookingScreen by adding proper null checks
- Logout buttons navigate back to the login screen after clearing data
