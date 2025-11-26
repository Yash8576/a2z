# Creating Consumer and Seller Accounts in Hub Flux

## Overview
Hub Flux supports two distinct account types with different features and UI:
- **Consumer Account** (Normal User)
- **Seller Account** (Brand/Store)

## 🎯 Key Differences

### Consumer Account Features:
- Can follow other users
- Create posts (photos/videos) and reels
- Browse and purchase products
- View completed orders
- Profile shows: Posts, Followers, **Following**, Orders

### Seller Account Features:
- **Cannot follow** other users (no following count)
- Create posts (photos/videos) and reels
- **Add products for sale**
- Profile shows: Posts, Followers, **Products** (no following)
- Access to product management

## 📱 UI Differences

### Profile Page Plus Button:
- **Consumer Account**: Shows 2 options
  - Create Post
  - Create Reel
  
- **Seller Account**: Shows 3 options
  - Create Post
  - Create Reel
  - **Add Product** ✨ (seller-exclusive)

### Profile Stats:
- **Consumer**: Posts | Followers | Following | Orders
- **Seller**: Posts | Followers | Products (no following)

### Profile Tabs:
- **Consumer**: Photos | Videos | Orders
- **Seller**: Photos | Videos | Products

## 🔧 Creating Accounts in Firebase

### Step 1: Sign Up
1. Open the app
2. Go to Sign Up screen
3. Enter email and password
4. Create account

### Step 2: Set Account Type in Firestore

#### For Consumer Account:
Navigate to Firebase Console → Firestore → `users` collection → your user document

```javascript
{
  "uid": "generated-user-id",
  "email": "consumer@example.com",
  "displayName": "John Doe",
  "accountType": "consumer",  // or omit this field (defaults to consumer)
  "bio": "Love shopping and connecting!",
  "followers": 0,
  "following": 0,
  "createdAt": Timestamp
}
```

#### For Seller Account:
Navigate to Firebase Console → Firestore → `users` collection → your user document

```javascript
{
  "uid": "generated-user-id",
  "email": "seller@example.com",
  "displayName": "My Awesome Store",
  "accountType": "seller",  // IMPORTANT: Must be exactly "seller"
  "bio": "Premium products, fast shipping!",
  "followers": 0,
  // Note: NO "following" field for sellers
  "createdAt": Timestamp
}
```

## 🎨 Testing Account Differences

### Test Consumer Account:
1. Sign in with consumer account
2. Go to Profile tab
3. Click the ➕ button → Should see only "Create Post" and "Create Reel"
4. Check stats → Should show Following count
5. Click Orders tab → Should show order list

### Test Seller Account:
1. Sign in with seller account
2. Go to Profile tab
3. Click the ➕ button → Should see "Add Product" option ✨
4. Check stats → Should NOT show Following (only shows Products count)
5. Click Products tab → Should show product grid

## 🔄 Switching Account Types

To switch an existing account:
1. Go to Firebase Console
2. Find user document in `users` collection
3. Change `accountType` field:
   - Set to `"seller"` for seller account
   - Set to `"consumer"` or delete field for consumer account
4. Restart app to see changes

## 📊 Required Firestore Structure

### Users Collection
```
users/
  {userId}/
    uid: string
    email: string
    displayName: string
    accountType: "consumer" | "seller"
    bio: string
    followers: number
    following: number (only for consumers)
    createdAt: timestamp
```

### Products Collection (for sellers)
```
products/
  {productId}/
    sellerId: string (matches user uid)
    title: string
    description: string
    price: number
    category: string
    imageUrl: string
    createdAt: timestamp
```

### Orders Collection (for consumers)
```
orders/
  {orderId}/
    userId: string (consumer's uid)
    productId: string
    sellerId: string
    status: "pending" | "shipped" | "delivered" | "completed"
    total: number
    createdAt: timestamp
```

## 🎯 Quick Setup Script (Optional)

You can add this to Firebase Functions or run in Firebase Console:

```javascript
// Create consumer account
db.collection('users').doc('consumer-uid').set({
  uid: 'consumer-uid',
  email: 'consumer@example.com',
  displayName: 'John Consumer',
  accountType: 'consumer',
  bio: 'I love shopping!',
  followers: 0,
  following: 0,
  createdAt: firebase.firestore.FieldValue.serverTimestamp()
});

// Create seller account
db.collection('users').doc('seller-uid').set({
  uid: 'seller-uid',
  email: 'seller@example.com',
  displayName: 'Premium Store',
  accountType: 'seller',
  bio: 'Best products in town!',
  followers: 0,
  createdAt: firebase.firestore.FieldValue.serverTimestamp()
});
```

## ✅ Verification Checklist

After creating accounts, verify:

### Consumer Account:
- [ ] Can see Following count in profile stats
- [ ] Orders tab visible in profile
- [ ] Plus button shows only Post and Reel options
- [ ] Can browse products
- [ ] Can add items to cart

### Seller Account:
- [ ] NO Following count in profile stats
- [ ] Products tab visible in profile (not Orders)
- [ ] Plus button shows Post, Reel, AND Product options
- [ ] Products stat shows product count
- [ ] Can create products

## 💡 Pro Tips

1. **Testing Both Types**: Create two accounts with different emails to test side-by-side
2. **Product Visibility**: Seller's products will appear in the Products tab and main Products screen
3. **Followers Work for Both**: Both account types can have followers
4. **Content Creation**: Both can create posts and reels
5. **Switch Easily**: Change `accountType` in Firestore to instantly switch account behavior

## 🚀 Next Steps

After setting up accounts:
1. Test profile FAB (plus button) for both account types
2. Add sample products for seller account
3. Create sample orders for consumer account
4. Test the real-time updates
5. Verify stats calculations

---

**Need Help?** Check that your Firestore `accountType` field is exactly `"seller"` (case-sensitive) for seller accounts!

