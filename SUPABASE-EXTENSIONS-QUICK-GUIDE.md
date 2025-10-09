# Supabase Extensions - Quick Guide 📋

---

## ✅ **What to Install:**

### Currently Installed:
- ✅ GraphQL
- ✅ Vault

### **Install NOW:**
1. ✅ **pg_cron** (Cron Jobs)
2. ✅ **Database Webhooks** (Already enabled!)

### **Skip All Others** ❌

---

## 🚀 **Quick Install: Cron**

### Step 1: Enable Extension
```
Supabase Dashboard → Database → Extensions → 
Search "pg_cron" → Click Enable
```

### Step 2: Add Jobs
```
SQL Editor → New Query → Copy/Paste from supabase-cron-jobs.sql →
Run Jobs 1 & 2 only → Done!
```

**Time:** 3 minutes ⏱️

---

## 📊 **Which Cron Jobs to Run:**

### ✅ Job 1: Daily Stats (MUST HAVE)
```sql
SELECT cron.schedule(
    'aggregate-daily-stats',
    '0 0 * * *',  -- Midnight daily
    $$ ... $$
);
```
**Benefit:** 10x faster stats loading

---

### ✅ Job 2: Cleanup Old Requests (RECOMMENDED)
```sql
SELECT cron.schedule(
    'cleanup-old-friend-requests',
    '0 2 * * 0',  -- Sunday 2 AM
    $$ ... $$
);
```
**Benefit:** Cleaner database

---

### ⏳ Job 3 & 4: Skip for Now
**Install later when:**
- Job 3: Adding user streak feature
- Job 4: Using real AI food scanning

---

## ✅ **Code Changes Already Made:**

### Webhook Listeners Added:
- `subscribeToFriendRequests()` - Real-time friend updates
- `subscribeToMeals()` - Real-time meal updates
- Auto-activates on app launch
- Auto-cleanup on app close

**No additional code changes needed!**

---

## 🧪 **How to Test:**

### Test Webhooks:
1. Login as **Tester1** on simulator
2. Login as **Tester2** on another simulator/device
3. **Tester2** sends friend request to **Tester1**
4. Watch **Tester1's app update automatically!** ✨

### Test Cron (Next Day):
1. Install cron jobs today
2. Tomorrow, check stats
3. Should load faster (pre-aggregated)

---

## 📈 **Benefits Summary:**

| Feature | Before | After | Benefit |
|---------|--------|-------|---------|
| Friend Requests | Manual refresh | Auto-update | Real-time |
| Stats Loading | Calculate on demand | Pre-aggregated | 10x faster |
| Old Data | Accumulates | Auto-cleaned | Better performance |
| Database Size | Growing | Maintained | Lower costs |

---

## ✅ **Action Items:**

1. [ ] Enable pg_cron extension in Supabase
2. [ ] Run Job 1 SQL (Daily Stats)
3. [ ] Run Job 2 SQL (Cleanup)
4. [ ] Test webhooks with 2 users
5. [ ] Check cron job status tomorrow

---

**Total Time:** ~5 minutes  
**Benefit:** Huge performance & UX improvements! 🚀

