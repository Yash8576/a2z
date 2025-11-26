# Testing Guide - Consumer vs Seller Accounts

## 🎯 Quick Test Steps

### Part 1: Setup Test Accounts in Firestore

#### Create Consumer Account
1. Sign up in the app with email: `consumer@test.com`
2. Go to Firebase Console → Firestore → `users` collection
3. Find the document for this user
4. Add/update these fields:
```json
{
  "accountType": "consumer",
  "displayName": "Test Consumer",
  "bio": "I love shopping!",
  "followers": 0,
  "following": 5
}
```

#### Create Seller Account
1. Sign up in the app with email: `seller@test.com`
2. Go to Firebase Console → Firestore → `users` collection
3. Find the document for this user
4. Add/update these fields:
```json
{
  "accountType": "seller",
  "displayName": "Test Store",
  "bio": "Best products ever!",
  "followers": 10
}
```
**IMPORTANT**: Do NOT add a "following" field for sellers!

---

## 📱 Part 2: Test Consumer Account

### Sign in as Consumer
Email: `consumer@test.com`

### ✅ Test Checklist:

#### 1. Navigation Test
- [ ] Bottom nav has 5 tabs: Home | Reels | Products | Cart | Profile
- [ ] All tabs are accessible
- [ ] No crashes when switching tabs

#### 2. Home Screen Test
- [ ] Home shows feed (or empty state)
- [ ] App bar has: Search icon | Messages icon
- [ ] App bar does NOT have Settings icon ✅
- [ ] NO floating action button on Home ✅

#### 3. Products Screen Test
- [ ] Products screen shows grid or empty state
- [ ] Search bar is visible
- [ ] Category filters are clickable
- [ ] NO floating action button on Products ✅

#### 4. Reels Screen Test
- [ ] Reels screen loads
- [ ] Shows empty state or reels
- [ ] NO floating action button on Reels ✅

#### 5. Profile Screen Test (IMPORTANT)
- [ ] Settings icon visible in app bar (top right) ✅
- [ ] Profile shows correct display name: "Test Consumer"
- [ ] Stats show: Posts | Followers | **Following** | Orders
- [ ] Following count is visible (should show 5) ✅
- [ ] Tabs show: Photos | Videos | **Orders** ✅
- [ ] **Floating action button (➕) is visible** ✅

#### 6. Profile FAB Test (CRITICAL)
- [ ] Click the ➕ button on Profile
- [ ] Bottom sheet opens with options
- [ ] Options shown:
  - [ ] ✅ Create Post
  - [ ] ✅ Create Reel
  - [ ] ❌ Add Product (should NOT appear for consumers)
- [ ] Only 2 options total ✅

---

## 🏪 Part 3: Test Seller Account

### Sign Out & Sign in as Seller
Email: `seller@test.com`

### ✅ Test Checklist:

#### 1. Profile Screen Test (IMPORTANT)
- [ ] Settings icon visible in app bar (top right) ✅
- [ ] Profile shows correct display name: "Test Store"
- [ ] Stats show: Posts | Followers | **Products** (NOT Following)
- [ ] Following count is NOT visible ✅
- [ ] Tabs show: Photos | Videos | **Products** ✅
- [ ] **Floating action button (➕) is visible** ✅

#### 2. Profile FAB Test (CRITICAL)
- [ ] Click the ➕ button on Profile
- [ ] Bottom sheet opens with options
- [ ] Options shown:
  - [ ] ✅ Create Post
  - [ ] ✅ Create Reel
  - [ ] ✅ **Add Product** (should appear for sellers) 🎉
- [ ] 3 options total ✅
- [ ] "Add Product" has green icon ✅

#### 3. Navigation Test
- [ ] Bottom nav still has 5 tabs
- [ ] Home/Reels/Products/Cart work same as consumer
- [ ] NO FAB on Home, Products, or Reels ✅

---

## 🔍 Visual Differences Summary

### Consumer Profile:
```
┌─────────────────────────┐
│  Profile    [Settings]  │
├─────────────────────────┤
│      Test Consumer      │
│   consumer@test.com     │
├─────────────────────────┤
│ Posts | Followers |     │
│ Following ✅ | Orders ✅ │
├─────────────────────────┤
│ Photos | Videos | Orders│
├─────────────────────────┤
│      [Content Grid]     │
│                         │
│            [➕]          │ ← FAB with 2 options
└─────────────────────────┘
```

### Seller Profile:
```
┌─────────────────────────┐
│  Profile    [Settings]  │
├─────────────────────────┤
│      Test Store         │
│    seller@test.com      │
├─────────────────────────┤
│   Posts | Followers |   │
│   Products ✅ (no Following) │
├─────────────────────────┤
│Photos | Videos | Products│
├─────────────────────────┤
│      [Product Grid]     │
│                         │
│            [➕]          │ ← FAB with 3 options
└─────────────────────────┘
```

---

## 🐛 Troubleshooting

### Issue: FAB not showing different options
**Solution**: 
- Check Firestore: `accountType` must be exactly `"seller"` (case-sensitive)
- Restart the app after changing Firestore
- Make sure you're on the Profile tab, not Home tab

### Issue: Following count showing for seller
**Problem**: Firestore has "following" field for seller account
**Solution**: Delete the "following" field from seller's user document

### Issue: "Add Product" not showing for seller
**Check**:
1. Firestore `accountType` = `"seller"` (exactly)
2. You're clicking FAB on Profile screen (not Home)
3. Bottom sheet shows 3 options (not 2)

### Issue: Settings icon not showing
**Check**: You're on the Profile tab (settings only appears on Profile app bar)

### Issue: FAB showing on Home/Products/Reels
**This is wrong**: FAB should ONLY be on Profile screen
**Solution**: Pull latest code changes

---

## ✅ Success Criteria

### Consumer Account Success:
✓ Profile shows "Following" stat
✓ Profile has "Orders" tab
✓ Profile FAB shows 2 options (Post, Reel)
✓ NO "Add Product" option

### Seller Account Success:
✓ Profile does NOT show "Following" stat
✓ Profile shows "Products" stat
✓ Profile has "Products" tab (not Orders)
✓ Profile FAB shows 3 options (Post, Reel, **Add Product**)
✓ "Add Product" is green and seller-specific

### General Success:
✓ Settings only in Profile app bar
✓ NO FAB on Home, Products, or Reels screens
✓ FAB only on Profile screen
✓ No crashes or errors
✓ Smooth navigation between tabs

---

## 📸 Screenshot Checklist

Take screenshots to verify:
1. Consumer profile stats (with Following)
2. Consumer profile FAB menu (2 options)
3. Seller profile stats (with Products, no Following)
4. Seller profile FAB menu (3 options with Add Product)
5. Home screen (no FAB, no Settings)
6. Products screen (no FAB)

---

## 🎊 Final Verification

Run these commands:
```bash
# Check for errors
flutter analyze

# Run the app
flutter run
```

**Expected Results:**
- 0 errors
- 2 info warnings (harmless, in settings_screen.dart)
- App runs smoothly
- All tests pass

---

**Need help?** Check the ACCOUNT_TYPES_GUIDE.md for detailed Firestore setup instructions.

