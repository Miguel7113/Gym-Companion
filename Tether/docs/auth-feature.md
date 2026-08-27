# Authentication Feature

## Overview
The authentication feature handles user onboarding and login through a gym-based OTP system. Users select their gym, request an OTP via email or phone, and verify it to access the app.

## Components

### Models (`lib/features/auth/models/auth_models.dart`)
- **RequestOtpDto**: DTO for requesting OTP (gymId, email/phone, displayName)
- **VerifyOtpDto**: DTO for verifying OTP (gymId, email/phone, token, displayName)
- **OtpResponse**: Response from OTP request (status: 'otp_sent', 'pending_approval', 'already_registered')
- **AuthResponse**: Response from OTP verification (user, accessToken, refreshToken)
- **User**: User model (id, email, phone, displayName, gymId, authProviderId)
- **Gym**: Gym model (id, name, logoUrl, address, phone)

### Service (`lib/features/auth/services/auth_service.dart`)
- **requestOtp()**: Sends OTP request to backend
- **verifyOtp()**: Verifies OTP and stores access token
- **getGyms()**: Fetches available gyms
- **logout()**: Clears access token

### Screens

#### Gym Selection Screen (`gym_selection_screen.dart`)
- Fetches and displays list of available gyms
- Shows loading and error states
- Navigates to OTP request screen on gym selection

#### OTP Request Screen (`otp_request_screen.dart`)
- Allows users to enter email or phone number
- Optional display name field
- Segmented button to toggle between email/phone
- Handles pending approval and already registered states
- Navigates to OTP verification screen on success

#### OTP Verification Screen (`otp_verification_screen.dart`)
- 6-digit OTP input field
- Verifies OTP with backend
- Stores access token on success
- Navigates to main app on successful verification

## API Endpoints Used
- `GET /gyms` - Fetch available gyms
- `POST /auth/request-otp` - Request OTP
- `POST /auth/verify-otp` - Verify OTP

## Flow
1. User launches app → Gym Selection Screen
2. User selects gym → OTP Request Screen
3. User enters email/phone → Request OTP
4. User enters OTP → OTP Verification Screen
5. Verification successful → Main Navigation

## State Management
- Uses Riverpod providers for dependency injection
- ApiClient stores access token in memory
- Token automatically attached to all API requests via interceptor

## Error Handling
- Network errors displayed to user
- Invalid OTP shows error message
- Pending approval shows dialog explaining approval process
- Already registered shows dialog suggesting login
