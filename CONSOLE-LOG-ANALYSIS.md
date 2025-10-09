# Console Log Analysis - MacroTrackr

**Date:** October 8, 2025  
**Status:** Analyzing runtime errors from Xcode console

---

## 🔍 Error Categories Found

### ✅ **SAFE TO IGNORE** (iOS Simulator Issues - Not Your App's Fault)

#### 1. Network Socket Errors
```
nw_socket_set_connection_idle [C1.1.1.1:3] setsockopt SO_CONNECTION_IDLE failed [42: Protocol not available]
```
**Severity:** Low (Simulator bug)  
**Cause:** iOS Simulator networking stack limitation  
**Impact:** None - App still connects to internet fine  
**Action:** ✅ Ignore - This is a known simulator issue

---

#### 2. Haptic Feedback Errors
```
CHHapticPattern.mm:487 Failed to read pattern library data
Error: "hapticpatternlibrary.plist" couldn't be opened
```
**Severity:** Low (Simulator limitation)  
**Cause:** Simulator doesn't support haptic feedback  
**Impact:** None - Only affects button vibrations  
**Action:** ✅ Ignore - Expected on simulator

---

#### 3. Auto Layout Constraint Warnings
```
Unable to simultaneously satisfy constraints
NSLayoutConstraint:0x6000021571b0 'accessoryView.bottom'
```
**Severity:** Low (iOS keyboard bug)  
**Cause:** iOS keyboard internal constraint conflicts  
**Impact:** None - Keyboard still works fine  
**Action:** ✅ Ignore - System UI issue, not your code

---

#### 4. Keyboard Input Warnings
```
-[RTIInputSystemClient remoteTextInputSessionWithID:performInputOperation:] 
perform input operation requires a valid sessionID
```
**Severity:** Low (iOS keyboard system)  
**Cause:** Keyboard system initialization timing  
**Impact:** None - Input still works  
**Action:** ✅ Ignore - iOS internal warning

---

#### 5. Misc Simulator Warnings
```
Error acquiring assertion: RBSAssertionErrorDomain Code=2
IOSurfaceClientSetSurfaceNotify failed e00002c7
Gesture: System gesture gate timed out
```
**Severity:** Low (Simulator quirks)  
**Cause:** Simulator environment limitations  
**Impact:** None - UI gestures work fine  
**Action:** ✅ Ignore - Simulator artifacts

---

### 🔥 **REAL ERROR - NEEDS FIXING** (Your App's Issue)

#### ⚠️ Critical Error Found:
```
Error handling user action: PostgrestError(
  detail: nil,
  hint: nil, 
  code: Optional("23505"),
  message: "duplicate key value violates unique constraint 
           \"friend_requests_from_user_id_to_user_id_key\""
)
```

**Severity:** 🔥 HIGH - This is a real application error  
**Cause:** Trying to send duplicate friend request  
**Database Constraint:** `friend_requests_from_user_id_to_user_id_key`  
**What Happened:** User tried to send friend request to someone they already requested  

---

## 🎯 Issue Analysis: Duplicate Friend Request

### What the Error Means:
- User clicked "Add Friend" button
- Database already has a pending request from this user to target user
- Unique constraint prevents duplicate requests
- Error message shown to user was generic

### Current Behavior:
❌ User sees generic error message  
❌ No validation before sending request

### Expected Behavior:
✅ Check if request already exists before sending  
✅ Show specific message: "Friend request already sent"  
✅ Disable button if request pending

---

## 🔧 Fix Required

### Location: ProfileView.swift - sendFriendRequest flow

**Problem:** No pre-check for existing friend requests

**Solution:** Add validation before sending request

---

## 📊 Summary of All Logs

| Error Type | Count | Severity | Action |
|------------|-------|----------|--------|
| Network socket errors | ~50+ | Low | ✅ Ignore (simulator) |
| Haptic feedback errors | ~20+ | Low | ✅ Ignore (simulator) |
| Auto layout warnings | ~10 | Low | ✅ Ignore (iOS keyboard) |
| Keyboard warnings | ~5 | Low | ✅ Ignore (system) |
| **Duplicate friend request** | **1** | **HIGH** | **🔧 FIX NOW** |

---

## ✅ Good News

**95% of the console output is simulator noise!**

Only **1 real application error** found:
- Duplicate friend request handling

Everything else is just iOS simulator limitations and internal warnings that don't affect functionality.

---

## 🎯 Next Steps

1. ✅ Fix duplicate friend request validation
2. ✅ Add user-friendly error message
3. ✅ Test again
4. ✅ Verify error is handled gracefully

---

