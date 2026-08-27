# Gym Companion - Authentication & Database Architecture

## Database Architecture

### Single Database, Multi-Tenant Design
- **One PostgreSQL database** for all gyms
- **Multi-tenant isolation** via `gymId` on all tables
- No need for multiple databases - simplifies maintenance and scaling

### Table Structure with Gym Isolation
All data tables include `gymId` for tenant isolation:

- `Gym` - Gym profiles (name, logo, subscription tier)
- `GymStaff` - Gym staff accounts (email, role, authProviderId)
- `GymRoster` - Member roster (email, phone, memberName, status)
- `User` - Gym members (gymId, email, phone, displayName, authProviderId)
- `WorkoutSession` - Workout sessions (userId, gymId, startedAt, endedAt)
- `WorkoutSet` - Individual sets (sessionId, exerciseId, reps, weightKg)
- `Exercise` - Exercise library (name, category, isCustom)
- `Food` - Food database (name, calories, macros)
- `FoodLog` - Food entries (userId, foodId, loggedAt, quantityG)

### Data Isolation
- All queries filter by `gymId` to ensure data separation
- Authorization checks prevent cross-gym data access
- Gym staff only see their gym's members and data
- Members only see their own data within their gym

## Login Flows

### 1. OTP Authentication (Current Implementation)
**Flow:**
1. Member downloads app
2. Selects their gym from list
3. Enters email or phone number
4. Backend checks gym roster:
   - **Matched**: Send OTP via email/SMS
   - **Unmatched**: Create pending approval request
   - **Already registered**: Prompt to login
5. Member enters OTP
6. Backend verifies with Supabase Auth
7. User created/updated in database
8. JWT token returned and stored
9. Member logged in

**Benefits:**
- No password management
- Secure one-time verification
- Works with existing gym roster
- Pending approval for new members

### 2. OAuth Authentication (Future Enhancement)
**Flow:**
1. Member downloads app
2. Selects their gym
3. Taps "Sign in with Google/Apple/Facebook"
4. OAuth provider authenticates user
5. Backend receives OAuth token
6. User created/linked to gym roster
7. JWT token returned
8. Member logged in

**Benefits:**
- One-click login
- No password required
- Familiar user experience
- Reduced friction

### 3. Staff Login (Admin Portal)
**Flow:**
1. Gym staff opens admin portal (Next.js web app)
2. Enters email and password
3. Backend authenticates via Supabase Auth
4. Staff role verified (admin/trainer)
5. JWT token returned
6. Staff logged in to admin dashboard

**Benefits:**
- Password-based for staff
- Role-based access control
- Separate from member flow
- Secure admin operations

## Gym ID System

### Purpose
- **Multi-tenancy**: Single database serves multiple gyms
- **Data isolation**: Each gym's data is separated
- **Scalability**: Easy to add new gyms without infrastructure changes

### Implementation
- Every gym has a unique UUID (`gymId`)
- All user-generated data includes `gymId`
- All API queries filter by `gymId`
- Authorization checks verify user belongs to correct gym

### Example Query
```sql
-- Get all workout sessions for a specific gym
SELECT * FROM workout_sessions 
WHERE gym_id = 'gym-uuid-here'
ORDER BY started_at DESC;
```

## Admin Portal (Next.js)

### Purpose
- Gym staff management interface
- Roster management (import CSV, approve members)
- Member activity monitoring
- Workout data analysis
- Food tracking oversight

### Features
- **Roster Management**: Import member CSV, approve pending requests
- **Member Dashboard**: View member activity, workout history
- **Analytics**: Gym-wide statistics, engagement metrics
- **Settings**: Gym profile, branding, subscription management

### Architecture
- **Frontend**: Next.js with React
- **Backend**: Same NestJS API as mobile app
- **Database**: Shared PostgreSQL database
- **Authentication**: Staff email/password login
- **Authorization**: Role-based access (admin/trainer)

### Data Sharing
- Admin portal uses same API endpoints as mobile app
- Staff see all data for their gym
- Members see only their own data
- No data duplication needed

## Security Considerations

### JWT Token Management
- Access tokens stored in memory (mobile app)
- Tokens attached to all API requests via interceptor
- Token refresh handled automatically
- Logout clears token from memory

### Authorization
- All API endpoints check user permissions
- Gym staff can only access their gym's data
- Members can only access their own data
- Cross-gym access prevented at API level

### Data Privacy
- Each gym's data is logically isolated
- No cross-gym data sharing
- GDPR compliant data handling
- Secure password/OTP handling via Supabase

## Future Enhancements

### OAuth Providers
- Google Sign-In
- Apple Sign-In
- Facebook Login
- Microsoft Account

### Additional Authentication
- Biometric login (fingerprint/face)
- Magic links (email-based login)
- SMS-based verification
- QR code gym check-in

### Admin Features
- Multi-gym management (for gym chains)
- Staff scheduling
- Payment processing
- Member communication tools
