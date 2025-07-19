# Migration Guide: Profile Setup Implementation

## Overview
This guide explains how to migrate existing user data to the new profile setup system.

## Data Migration

### Existing Users
For users who already have basic user records in Firestore under the old `UserModel` structure, the system will:

1. **Auto-detect** existing basic user data
2. **Create** an initial `UserProfileModel` with default values
3. **Prompt** user to complete their profile on next sign-in

### Migration Process
```dart
// When an existing user signs in:
1. Check if UserProfileModel exists
2. If not, create from existing UserModel data
3. Set isProfileComplete = false
4. Redirect to ProfileSetupScreen
```

### Data Mapping
```dart
// Old UserModel → New UserProfileModel
UserModel {          UserProfileModel {
  uid               →  uid
  name              →  name
  email             →  email
  photoUrl          →  photoUrl
  createdAt         →  createdAt
  lastSignIn        →  lastSignIn
                    +  gender: Gender.preferNotToSay (default)
                    +  activeHours: "9 AM - 6 PM" (default)
                    +  bio: null
                    +  religion: null
                    +  relationshipStatus: null
                    +  dateOfBirth: null
                    +  isProfileComplete: false
}
```

## Database Schema Changes

### Firestore Collection: `users/{uid}`
```javascript
// Before (UserModel)
{
  uid: "user123",
  name: "John Doe",
  email: "john@example.com",
  photoUrl: "https://...",
  createdAt: timestamp,
  lastSignIn: timestamp
}

// After (UserProfileModel)
{
  uid: "user123",
  name: "John Doe",
  email: "john@example.com",
  photoUrl: "https://...",
  createdAt: timestamp,
  lastSignIn: timestamp,
  gender: "preferNotToSay",
  activeHours: "9 AM - 6 PM",
  bio: null,
  religion: null,
  relationshipStatus: null,
  dateOfBirth: null,
  isProfileComplete: false
}
```

### Backward Compatibility
- ✅ Existing fields remain unchanged
- ✅ New fields are optional with defaults
- ✅ Old data can be read by new code
- ✅ Graceful fallback for missing fields

## Code Changes Impact

### Repository Layer
- `UserRepository` remains for basic operations
- `UserProfileRepository` added for enhanced profile operations
- Both can coexist during transition period

### Service Layer
- `ServiceLocator` updated to include `UserProfileRepository`
- Existing services unchanged

### Presentation Layer
- `AuthWrapper` enhanced to handle profile flow
- `SignInScreen` updated to check profile completion
- `HomeScreen` updated to display profile data
- New `ProfileSetupScreen` added

## Deployment Strategy

### Phase 1: Deploy with Backward Compatibility
1. Deploy new code with profile system
2. Existing users continue normal flow
3. New users get profile setup experience

### Phase 2: Gradual Migration
1. Existing users prompted to complete profile on sign-in
2. Old and new data structures coexist
3. Monitor completion rates

### Phase 3: Full Migration (Optional)
1. Run batch job to migrate all old records
2. Remove old UserModel dependencies
3. Cleanup unused code

## Testing Migration

### Local Testing
```dart
// Test migration path
1. Create old-format user document in Firestore
2. Sign in with that user
3. Verify profile setup screen appears
4. Complete profile setup
5. Verify data is properly migrated
```

### Production Testing
1. Deploy to staging environment
2. Test with sample of existing user data
3. Verify no data loss occurs
4. Test edge cases (missing fields, etc.)

## Rollback Plan

### If Issues Arise
1. **Immediate**: Revert to previous version
2. **Data**: No data loss - new fields are additive
3. **Users**: Fall back to old flow temporarily

### Rollback Steps
```bash
# Revert deployment
git revert <commit-hash>
flutter build
# Deploy previous version

# Optional: Remove new fields from Firestore
# (only if absolutely necessary)
```

## Monitoring

### Key Metrics
- Profile completion rate
- User drop-off during setup
- Error rates in profile save operations
- Performance impact on sign-in flow

### Alerts
- Monitor Firestore write errors
- Track navigation failures
- Watch for authentication issues

## Support

### Common Issues
1. **Profile not loading**: Check Firestore permissions
2. **Required fields error**: Verify form validation
3. **Photo upload issues**: Check storage permissions
4. **Date picker problems**: Verify locale settings

### Troubleshooting
```dart
// Enable debug logging
flutter run --debug
// Check Firebase console for errors
// Verify Firestore security rules
```

## Timeline

### Recommended Schedule
- **Week 1**: Deploy to staging, internal testing
- **Week 2**: Beta testing with select users
- **Week 3**: Gradual rollout (10% users)
- **Week 4**: Full deployment
- **Week 5**: Monitor and optimize

## Conclusion
This migration maintains full backward compatibility while introducing enhanced profile functionality. Existing users experience a smooth transition, and new users get the full profile setup experience from day one.