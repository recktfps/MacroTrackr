# Quick Test Reference Card 📋

**Fast reference for testing MacroTrackr with 2 users**

---

## 👥 Credentials

```
USER 1 (Tester1)
Email:    ivan562562@gmail.com
Password: cacasauce
Display:  Tester1

USER 2 (Tester2)
Email:    ivanmartinez562562@gmail.com
Password: cacasauce
Display:  Tester2
```

---

## ⚡ 5-Minute Quick Test

### 1. Login as Tester1
```bash
Email: ivan562562@gmail.com
Pass: cacasauce
```

### 2. Send Friend Request
```
Profile → Friends → Add Friend → "Tester2" → Send
Expected: ✅ "Pending" status
```

### 3. Login as Tester2
```bash
Email: ivanmartinez562562@gmail.com
Pass: cacasauce
```

### 4. Accept Request
```
Profile → Friends → Incoming → Accept
Expected: ✅ "Friends" status
```

### 5. Verify Both Sides
```
Both users should see each other in Friends list
Expected: ✅ Friendship confirmed
```

---

## 🔥 Critical Tests

### Test the FIXED Error:
```
1. Tester1 → Send request to Tester2
2. Tester1 → Try sending AGAIN
Expected: ✅ Alert: "Friend request already sent to this user"
NOT: ❌ Silent failure or console error only
```

---

## 🎯 Database Operations Test

### With Each User:

```
CREATE:  Add meal → Should save
READ:    View meals → Should load
UPDATE:  Edit meal → Should update
DELETE:  Delete meal → Should remove
SEARCH:  Search meals → Should find
```

**Expected:** All operations work for both users independently

---

## ✅ Pass Criteria

- [ ] Both users can login
- [ ] Can send friend requests
- [ ] Can accept requests
- [ ] Friendship established
- [ ] Duplicate request shows ALERT (not just console)
- [ ] Data isolated per user
- [ ] No crashes

---

## 📊 Quick Status Check

Current status:
- ✅ Build: SUCCESS
- ✅ Database: 6/6
- ✅ Tests: 46/46
- ✅ Errors: Fixed

**Ready to test!** 🚀

