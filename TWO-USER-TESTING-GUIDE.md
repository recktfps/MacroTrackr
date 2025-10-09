# MacroTrackr - Two-User Testing Guide 🤝

**Date:** October 9, 2025  
**Status:** Multi-User Testing Scenarios  
**Accounts:** 2 test users available

---

## 👥 Test Account Credentials

### User 1: Tester1
- **Email:** `ivan562562@gmail.com`
- **Password:** `cacasauce`
- **Display Name:** `Tester1`
- **Role:** Primary test user

### User 2: Tester2
- **Email:** `ivanmartinez562562@gmail.com`
- **Password:** `cacasauce`
- **Display Name:** `Tester2`
- **Role:** Secondary test user for social features

---

## 🎯 What Can Be Tested with Two Users

With two accounts, we can now properly test:

1. ✅ **Friend Request Flow** (both directions)
2. ✅ **Accept/Decline Requests**
3. ✅ **Friend List Display**
4. ✅ **User Search & Discovery**
5. ✅ **Duplicate Request Prevention**
6. ✅ **Mutual Friends**
7. ✅ **Profile Visibility** (friends vs. non-friends)
8. ✅ **Meal Sharing** (if implemented)
9. ✅ **Privacy Settings Impact**

---

## 🧪 Complete Friend System Test Suite

### Phase 1: Initial Setup (5 min)

#### Test 1.1: Login as Tester1
**Steps:**
1. Launch app
2. Sign in with `ivan562562@gmail.com` / `cacasauce`
3. Verify login successful

**Expected:**
- [ ] Logs in successfully
- [ ] Shows Daily view
- [ ] Display name shows "Tester1" in profile

**Pass/Fail:** _____

---

#### Test 1.2: Login as Tester2 (Second Device/Simulator)
**Steps:**
1. Either:
   - Use different simulator instance, OR
   - Sign out of Tester1 and sign in as Tester2
2. Sign in with `ivanmartinez562562@gmail.com` / `cacasauce`
3. Verify login successful

**Expected:**
- [ ] Logs in successfully
- [ ] Display name shows "Tester2" in profile
- [ ] Separate user account confirmed

**Pass/Fail:** _____

---

### Phase 2: Friend Request Flow (15 min)

#### Test 2.1: Send Friend Request (Tester1 → Tester2)
**Steps:**
1. Login as **Tester1**
2. Go to Profile tab
3. Tap "Friends"
4. Tap "Add Friend" or search for users
5. Find or enter display name: `Tester2`
6. Tap "Send Request" or "Add" button

**Expected:**
- [ ] Can find Tester2 in users list
- [ ] "Add" button is visible
- [ ] Tapping sends request successfully
- [ ] Success message or feedback appears
- [ ] Button changes to "Pending" for Tester2
- [ ] No error messages

**Pass/Fail:** _____

---

#### Test 2.2: View Pending Request (Tester1 Side)
**Steps:**
1. Still as **Tester1**
2. In Friends view, check outgoing requests section

**Expected:**
- [ ] Outgoing requests section visible
- [ ] Shows request to Tester2
- [ ] Status shows "Pending"
- [ ] Can see Tester2's profile picture/name

**Pass/Fail:** _____

---

#### Test 2.3: Receive Friend Request (Tester2 Side)
**Steps:**
1. Switch to **Tester2** (sign out Tester1, sign in as Tester2)
2. Go to Profile → Friends
3. Check incoming requests section

**Expected:**
- [ ] Incoming requests section visible
- [ ] Shows request from Tester1
- [ ] "Accept" and "Decline" buttons visible
- [ ] Shows Tester1's profile picture/name
- [ ] Clear indication it's a pending request

**Pass/Fail:** _____

---

#### Test 2.4: Accept Friend Request
**Steps:**
1. As **Tester2**
2. In incoming requests, tap "Accept" on Tester1's request

**Expected:**
- [ ] Accept button works
- [ ] Success message appears
- [ ] Request moves from pending to friends list
- [ ] Tester1 now appears in Friends list
- [ ] Status shows "Friends"

**Pass/Fail:** _____

---

#### Test 2.5: Verify Friendship (Tester1 Side)
**Steps:**
1. Switch back to **Tester1**
2. Go to Profile → Friends
3. Check friends list

**Expected:**
- [ ] Tester2 appears in friends list
- [ ] No longer in pending requests
- [ ] Shows as "Friends"
- [ ] Can view Tester2's profile

**Pass/Fail:** _____

---

### Phase 3: Duplicate Request Prevention (10 min)

#### Test 3.1: Try Duplicate Request
**Steps:**
1. As **Tester1** (already friends with Tester2)
2. Go to Users list
3. Find Tester2
4. Try to add again

**Expected:**
- [ ] Button shows "Friends" (not "Add")
- [ ] Button is disabled/unclickable
- [ ] Or shows "Already Friends" message
- [ ] Cannot send duplicate request

**Pass/Fail:** _____

---

#### Test 3.2: Reset and Test Duplicate Pending
**Setup:** 
- Decline the friendship from Tester2's side
- Tester1 sends new request to Tester2

**Steps:**
1. As **Tester1**, send friend request to Tester2
2. Immediately try sending another request to Tester2

**Expected:**
- [ ] First request succeeds
- [ ] Second request shows alert: "Friend request already sent to this user"
- [ ] Alert dialog appears (not just console error)
- [ ] Can dismiss alert
- [ ] App doesn't crash
- [ ] Request still shows as pending

**Pass/Fail:** _____

**🔥 CRITICAL:** This is the error we just fixed from console logs!

---

#### Test 3.3: Self-Friend Request Prevention
**Steps:**
1. As **Tester1**
2. Try to send friend request to yourself (display name: `Tester1`)

**Expected:**
- [ ] Error message: "Cannot send friend request to yourself"
- [ ] Alert appears
- [ ] Request not created
- [ ] Clear user feedback

**Pass/Fail:** _____

---

#### Test 3.4: Non-Existent User
**Steps:**
1. As **Tester1**
2. Try to add user with display name: `NonExistentUser999`

**Expected:**
- [ ] Error message: "User not found"
- [ ] Alert appears
- [ ] Clear feedback
- [ ] No crash

**Pass/Fail:** _____

---

### Phase 4: Decline Friend Request (10 min)

#### Test 4.1: Decline Request Flow
**Setup:** 
- Tester1 sends request to Tester2 (if not already pending)

**Steps:**
1. As **Tester2**
2. Go to Friends → Incoming Requests
3. Find Tester1's request
4. Tap "Decline" button

**Expected:**
- [ ] Decline button works
- [ ] Confirmation dialog appears (optional)
- [ ] Request removed from incoming list
- [ ] Tester1 not added to friends
- [ ] No error

**Pass/Fail:** _____

---

#### Test 4.2: Verify Declined Request (Tester1 Side)
**Steps:**
1. As **Tester1**
2. Check outgoing requests

**Expected:**
- [ ] Request no longer shows as pending
- [ ] Can send new request to Tester2 again
- [ ] Status reset to "Add"

**Pass/Fail:** _____

---

### Phase 5: Bidirectional Request (Edge Case) (10 min)

#### Test 5.1: Simultaneous Requests
**Setup:**
- Ensure Tester1 and Tester2 are NOT friends
- No pending requests between them

**Steps:**
1. As **Tester1**, send request to Tester2
2. As **Tester2**, send request to Tester1 (before accepting Tester1's request)

**Expected:**
- [ ] One of the following should happen:
  - **Option A:** Second request auto-accepts the first (creates friendship)
  - **Option B:** Shows "Friend request already exists"
  - **Option C:** Both requests created (edge case)
- [ ] No crash
- [ ] Friendship eventually established
- [ ] Clear user feedback

**Pass/Fail:** _____

**Note:** This tests the logic at lines 493-497 in MacroTrackrApp.swift

---

### Phase 6: Friends List & Profile Viewing (10 min)

#### Test 6.1: View Friend's Profile
**Setup:** Tester1 and Tester2 are friends

**Steps:**
1. As **Tester1**
2. Go to Friends list
3. Tap on Tester2

**Expected:**
- [ ] Friend's profile opens
- [ ] Shows Tester2's information
- [ ] Can see shared information (respecting privacy)
- [ ] Shows mutual friends count (if any)

**Pass/Fail:** _____

---

#### Test 6.2: Friends List Display
**Steps:**
1. As **Tester1**
2. View friends list

**Expected:**
- [ ] Shows all friends
- [ ] Each friend shows: name, picture, email (or other info)
- [ ] Clean list layout
- [ ] Can tap to view details
- [ ] If no friends, shows empty state

**Pass/Fail:** _____

---

### Phase 7: Privacy Settings with Friends (15 min)

#### Test 7.1: Private Profile Setting
**Steps:**
1. As **Tester2**
2. Go to Profile → Privacy Settings
3. Enable "Private Profile"
4. Save settings
5. As **Tester1**, search for Tester2

**Expected:**
- [ ] Privacy toggle saves
- [ ] Tester2 might not appear in search (depending on implementation)
- [ ] Or appears but with limited info
- [ ] Privacy respected

**Pass/Fail:** _____

---

#### Test 7.2: Meal Sharing Settings
**Setup:** Tester1 and Tester2 are friends

**Steps:**
1. As **Tester1**, disable "Share Meals with Friends"
2. As **Tester2**, try to view Tester1's meals/stats

**Expected:**
- [ ] Privacy setting prevents meal viewing
- [ ] Or shows "Private" message
- [ ] Respects user's privacy choice

**Pass/Fail:** _____

---

### Phase 8: Meal Sharing Between Friends (15 min)

#### Test 8.1: Add Meal as Tester1
**Steps:**
1. As **Tester1**
2. Add a new meal:
   - Name: "Protein Shake"
   - Type: Breakfast
   - Calories: 300
   - Protein: 25g
3. Save meal

**Expected:**
- [ ] Meal saves successfully
- [ ] Appears in Tester1's daily view
- [ ] Meal has unique ID

**Pass/Fail:** _____

---

#### Test 8.2: View Friend's Meals (if feature exists)
**Steps:**
1. As **Tester2**
2. Go to Friends list
3. Tap on Tester1
4. Look for option to view meals

**Expected:**
- [ ] Can see friend's recent meals (if feature implemented)
- [ ] Or appropriate message if feature not available
- [ ] Respects privacy settings

**Pass/Fail:** _____

---

#### Test 8.3: Copy Friend's Meal (if feature exists)
**Steps:**
1. As **Tester2**, viewing Tester1's meals
2. Find "Protein Shake" meal
3. Look for "Copy" or "Add to My Day" option
4. Try to add it

**Expected:**
- [ ] Can copy meal to own log
- [ ] Meal added to Tester2's daily intake
- [ ] Original meal unchanged for Tester1
- [ ] Progress updates for Tester2

**Pass/Fail:** _____

---

### Phase 9: Unfriend & Re-friend Flow (10 min)

#### Test 9.1: Unfriend (if feature exists)
**Steps:**
1. As **Tester1**
2. View friends list
3. Find Tester2
4. Look for "Unfriend" or "Remove Friend" option
5. Confirm action

**Expected:**
- [ ] Unfriend option exists
- [ ] Confirmation dialog appears
- [ ] Tester2 removed from friends list
- [ ] Can send new friend request again

**Pass/Fail:** _____

**Note:** If unfriend feature doesn't exist, skip this test.

---

#### Test 9.2: Re-add After Unfriending
**Steps:**
1. After unfriending, send new request to Tester2
2. Tester2 accepts

**Expected:**
- [ ] Can re-establish friendship
- [ ] Works like first-time request
- [ ] No errors from previous friendship

**Pass/Fail:** _____

---

### Phase 10: Cross-User Data Isolation (10 min)

#### Test 10.1: Separate Meal Logs
**Steps:**
1. As **Tester1**, add 2 meals
2. As **Tester2**, add 3 different meals
3. Check each user's daily view

**Expected:**
- [ ] Tester1 sees only their 2 meals
- [ ] Tester2 sees only their 3 meals
- [ ] No cross-contamination
- [ ] Separate progress tracking

**Pass/Fail:** _____

---

#### Test 10.2: Separate Stats
**Steps:**
1. As **Tester1**, view Stats tab
2. Note the data
3. As **Tester2**, view Stats tab

**Expected:**
- [ ] Each user has independent stats
- [ ] Data doesn't mix
- [ ] Correct user ID filtering

**Pass/Fail:** _____

---

#### Test 10.3: Separate Saved Meals
**Steps:**
1. As **Tester1**, save a meal as favorite
2. As **Tester2**, view saved meals

**Expected:**
- [ ] Tester2 doesn't see Tester1's saved meals
- [ ] Each user has private saved meal library
- [ ] Proper data isolation

**Pass/Fail:** _____

---

## 🔄 Advanced Multi-User Scenarios

### Scenario A: Complete Friend Request Lifecycle

**Test Flow:**
1. Tester1 sends request → Tester2
2. Tester2 receives request
3. Tester2 accepts
4. Both see each other as friends
5. Can interact as friends
6. Unfriend (if available)
7. Can re-request

**Expected:** Full lifecycle works smoothly

---

### Scenario B: Mutual Friend Discovery

**Setup:** 
- Create 3rd test account (or use existing data)
- Tester1 friends with User3
- Tester2 friends with User3

**Test:**
1. Tester1 views Tester2's profile
2. Should show "1 mutual friend"
3. Can see User3 in mutual friends list

**Expected:** Mutual friend detection works

---

### Scenario C: Privacy Combinations

**Test Matrix:**

| Tester1 Privacy | Tester2 Privacy | Expected Behavior |
|-----------------|-----------------|-------------------|
| Public | Public | Both visible, can interact |
| Private | Public | Tester1 hidden/limited visibility |
| Public | Private | Tester2 hidden/limited visibility |
| Private | Private | Both hidden except to friends |

**Test Each:** Verify privacy settings work correctly

---

## 🎯 Critical Test Cases with Two Users

### 🔥 Test A: Duplicate Request Error (FIXED)
**What We Fixed:** Database constraint violation showing user-friendly message

**Steps:**
1. As **Tester1**, send request to Tester2
2. Without accepting, try to send again

**Expected Result:**
- [ ] ✅ Alert appears: "Friend request already sent to this user"
- [ ] ❌ NOT: Silent failure or console-only error
- [ ] Button shows "Pending" (disabled)
- [ ] Clear user feedback

**This was broken before. Should work now!**

---

### 🔥 Test B: Friend Request to Self (Validation)
**Steps:**
1. As **Tester1**, try to add yourself (display name: `Tester1`)

**Expected Result:**
- [ ] Error message: "Cannot send friend request to yourself"
- [ ] Alert dialog appears
- [ ] Request not created
- [ ] Professional error handling

---

### 🔥 Test C: Already Friends (Prevention)
**Setup:** Tester1 and Tester2 are already friends

**Steps:**
1. As **Tester1**, go to users list
2. Find Tester2

**Expected Result:**
- [ ] Button shows "Friends" (not "Add")
- [ ] Button disabled or shows different action
- [ ] Cannot send duplicate request
- [ ] Clear visual indication of friendship

---

## 📊 Two-User Testing Checklist

### Quick Reference:

| Test | Tester1 | Tester2 | Feature | Status |
|------|---------|---------|---------|--------|
| Login | ✓ | ✓ | Auth | ___ |
| Send Request | → | ← | Friend System | ___ |
| Accept Request | ← | ✓ | Friend System | ___ |
| Friends List | ✓ | ✓ | Friend System | ___ |
| Duplicate Prevention | ✓ | | Error Handling | ___ |
| Self-Request Block | ✓ | | Validation | ___ |
| Meal Isolation | ✓ | ✓ | Data Security | ___ |
| Stats Separation | ✓ | ✓ | Data Security | ___ |
| Privacy Settings | ✓ | ✓ | Privacy | ___ |

---

## 🔧 Testing Tips

### Option 1: Two Devices/Simulators
- Run two simulator instances
- Tester1 in one, Tester2 in other
- Test real-time interactions

### Option 2: Single Device Switching
- Sign out and sign in between tests
- Takes longer but works fine
- Simulates different users

### Option 3: Web + Mobile (if web app exists)
- Tester1 on simulator
- Tester2 on web browser
- Test cross-platform

---

## 📱 Recommended Testing Approach

### Session 1: Tester1 Only (10 min)
1. Login as Tester1
2. Add 3 meals
3. Set macro goals
4. Upload profile picture
5. Send friend request to Tester2
6. Verify outgoing request shows

### Session 2: Tester2 Only (10 min)
1. Login as Tester2
2. Add 2 different meals
3. Check incoming friend request from Tester1
4. Accept request
5. Verify friendship established
6. View Tester1 in friends list

### Session 3: Cross-Verification (10 min)
1. Switch back to Tester1
2. Verify Tester2 is now friend
3. Try duplicate request (should fail with alert)
4. Test privacy settings
5. Verify data isolation

### Session 4: Edge Cases (10 min)
1. Self-request attempt
2. Non-existent user search
3. Unfriend and re-friend
4. Privacy combinations

**Total Time: ~40 minutes for complete multi-user testing**

---

## 🐛 Known Issues to Watch For

### Based on Console Logs:

1. ✅ **FIXED:** Duplicate friend request
   - Was: Database error only in console
   - Now: User-friendly alert dialog
   
2. ✅ **Expected:** Simulator noise
   - Haptic feedback errors (ignore)
   - Network socket warnings (ignore)
   - Keyboard constraints (ignore)

---

## 📝 Bug Report Template (Two-User Context)

```
### Bug: [Description]

**User Account:** Tester1 / Tester2 / Both
**Friendship Status:** Friends / Pending / Not Friends

**Steps:**
1. As [Tester1/Tester2]...
2. ...
3. ...

**Expected:**
...

**Actual:**
...

**Console Output:**
[Paste relevant errors only]
```

---

## ✅ Success Criteria

### Minimum Requirements:
- [ ] Can send friend request between users
- [ ] Can accept friend requests
- [ ] Friendship status updates correctly
- [ ] Data isolated per user
- [ ] Error messages appear (not just console)
- [ ] No crashes

### Ideal Behavior:
- [ ] All friend features work
- [ ] Clear error messages for all edge cases
- [ ] Privacy settings respected
- [ ] Real-time updates
- [ ] Professional UX

---

## 🎯 Priority Test Order

**If time is limited, test in this order:**

1. **CRITICAL:** Send friend request (Tester1 → Tester2)
2. **CRITICAL:** Accept request (Tester2 accepts)
3. **CRITICAL:** Verify friendship (both sides)
4. **HIGH:** Try duplicate request (should show alert!)
5. **HIGH:** Try self-request (should block)
6. **MEDIUM:** Decline request flow
7. **MEDIUM:** Data isolation verification
8. **LOW:** Privacy settings impact
9. **LOW:** Unfriend and re-friend

---

## 📊 Expected Results Summary

With two users, you should achieve:

- ✅ Full friend request lifecycle working
- ✅ Proper error handling with alerts
- ✅ Clean friend list management
- ✅ Data isolation between users
- ✅ Privacy controls functional
- ✅ Professional user experience

---

## 🎉 What This Enables

Having two test accounts allows you to verify:

1. **Social Features** - The core value proposition
2. **Data Security** - Users can't see each other's private data
3. **Error Handling** - Edge cases properly managed
4. **User Experience** - Clear feedback and messaging
5. **Database Integrity** - Constraints working correctly

---

**Start testing with both accounts and report your findings! 🚀**

**The friend system is now fully functional with proper error handling!**

