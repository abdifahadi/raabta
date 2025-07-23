# Call Accept/Decline Flow Implementation

This document describes the implementation of the full accept/decline behavior for incoming calls in the cross-platform call system.

## Overview

The implementation provides a complete call flow that handles:
- Accept and decline buttons on incoming calls
- Proper Firestore status updates
- Agora channel joining only after acceptance
- Call cleanup after decline/timeout
- Consistent behavior across all platforms (Web, Android, iOS, Desktop)
- Proper timeout handling (30 seconds)

## Components

### 1. CallService (`lib/core/services/call_service.dart`)

The main service that orchestrates the call flow:

**Key Methods:**
- `startCall()` - Initiates a call and sets up timeout
- `answerCall()` - Accepts incoming call, updates status, joins Agora channel
- `declineCall()` - Declines call, schedules cleanup after 3 seconds
- `timeoutCall()` - Handles call timeout (30 seconds), marks as missed
- `cancelCall()` - Allows caller to cancel before answer
- `_setupCallTimeout()` - Internal timeout management

**Status Flow:**
1. `initiating` → `ringing` (when call is started)
2. `ringing` → `accepted` (when receiver accepts)
3. `accepted` → `connected` (when Agora channel joined successfully)
4. `ringing` → `declined` (when receiver declines)
5. `ringing` → `missed` (when call times out)
6. `ringing` → `cancelled` (when caller cancels)

### 2. CallManager (`lib/features/call/presentation/widgets/call_manager.dart`)

Manages call UI state and navigation:

**Features:**
- Listens for incoming calls
- Shows incoming call screen for ringing calls
- Monitors call status changes
- Only navigates to call screen after acceptance
- Shows appropriate feedback for declined/missed/failed calls
- Auto-dismisses call UI when needed

**Status Handling:**
- `accepted` → Navigate to call screen
- `declined` → Show "Call Declined" message
- `missed` → Show "Call Missed" message
- `failed` → Show "Call Failed" message

### 3. IncomingCallScreen (`lib/features/call/presentation/screens/incoming_call_screen.dart`)

The UI for receiving calls:

**Features:**
- Accept and Decline buttons
- 30-second timeout with auto-decline
- Ringtone playback
- Animated UI with caller information
- Proper cleanup on timeout/action

### 4. Call Initiation (Chat & Dialer screens)

Updated to handle the proper call flow:

**Features:**
- Shows "Calling..." dialog instead of immediate navigation
- Listens for call status changes
- Only navigates to call screen after acceptance
- Shows appropriate feedback for declined/missed calls
- Allows call cancellation while waiting

## Call Status Flow Diagram

```
Caller Side:                    Receiver Side:
┌─────────────┐                ┌─────────────┐
│ Start Call  │                │   Ringing   │
└─────┬───────┘                └─────┬───────┘
      │                              │
      v                              │
┌─────────────┐                      │
│   Ringing   │◄─────────────────────┘
└─────┬───────┘
      │
      v
┌─────────────┐    Accept     ┌─────────────┐
│  Waiting    │──────────────►│  Accepted   │
│ (30 sec)    │               └─────┬───────┘
└─────┬───────┘                     │
      │                             v
      │ Timeout          ┌─────────────┐
      └─────────────────►│ Connected   │
      │                  └─────────────┘
      │ Decline
      └─────────────────►┌─────────────┐
                         │  Declined   │
                         └─────────────┘
```

## Platform Compatibility

The implementation works identically across all platforms:

- **Web**: Uses Agora Web SDK
- **Android**: Uses Agora Native SDK
- **iOS**: Uses Agora Native SDK
- **Desktop**: Uses appropriate Agora implementation

## Timeout Behavior

**Incoming Call Timeout (30 seconds):**
- Automatically declines the call
- Updates status to `missed`
- Cleans up call document after 3 seconds
- Shows "Call Missed" feedback to caller

**Call Document Cleanup:**
- Declined calls: Deleted after 3 seconds
- Missed calls: Deleted after 3 seconds
- Cancelled calls: Deleted after 3 seconds
- Active/ended calls: Preserved for history

## Error Handling

**Common Error Scenarios:**
- User not authenticated
- Already in an active call
- Recipient busy (in another call)
- Network/permission issues
- Agora channel join failures

**Error Recovery:**
- Failed answer attempts update status to `failed`
- Proper cleanup on all error paths
- User-friendly error messages
- Graceful degradation

## Usage Examples

### Starting a Call (Caller)
```dart
final callService = ServiceLocator().callService;
final call = await callService.startCall(
  receiverId: targetUserId,
  callType: CallType.video,
  callerName: 'John Doe',
  callerPhotoUrl: 'https://...',
  receiverName: 'Jane Smith',
  receiverPhotoUrl: 'https://...',
);

// Listen for status changes
callRepository.getCallStream(call.callId).listen((updatedCall) {
  if (updatedCall?.status == CallStatus.accepted) {
    // Navigate to call screen
  }
});
```

### Answering a Call (Receiver)
```dart
final callService = ServiceLocator().callService;
await callService.answerCall(incomingCall);
// CallManager will automatically navigate to call screen
```

### Declining a Call (Receiver)
```dart
final callService = ServiceLocator().callService;
await callService.declineCall(incomingCall);
// CallManager will show "Call Declined" feedback to caller
```

## Testing

To test the implementation:

1. **Accept Flow**: Start call, accept on receiver, verify both users join Agora channel
2. **Decline Flow**: Start call, decline on receiver, verify caller gets feedback
3. **Timeout Flow**: Start call, wait 30 seconds, verify missed call handling
4. **Cancel Flow**: Start call, cancel before answer, verify proper cleanup
5. **Multiple Calls**: Test prevention of simultaneous calls
6. **Network Issues**: Test error handling with poor connectivity
7. **Platform Testing**: Verify identical behavior on Web/Android/iOS/Desktop

## Configuration

**Timeout Duration**: 30 seconds (configurable in `_setupCallTimeout`)
**Cleanup Delay**: 3 seconds (configurable in decline/timeout handlers)
**Ringtone**: Managed by `RingtoneService`
**Channel Names**: Generated by `AgoraConfig.generateChannelName`