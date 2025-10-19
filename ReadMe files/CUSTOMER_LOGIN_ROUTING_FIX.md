# 🔧 Customer Login Routing Fix

## 🐛 **Issue**
Customers logging in were being redirected to the admin/manager portal instead of the customer portal.

## ✅ **Root Cause**
**Case sensitivity issue** with role checking. The backend might return:
- `"Customer"` (capital C)
- `"customer"` (lowercase c)
- `"CUSTOMER"` (all caps)

But the code was checking for exact match: `user.role === 'Customer'`

---

## 🔧 **Fix Applied**

### **1. Login.js - Case-Insensitive Redirect**

**Before:**
```javascript
if (loggedInUser?.role === 'Customer') {
  navigate('/customer');
} else {
  navigate('/dashboard');
}
```

**After:**
```javascript
const userRole = loggedInUser?.role?.toLowerCase();

if (userRole === 'customer') {
  console.log('✅ Redirecting to customer portal');
  navigate('/customer');
} else {
  console.log('✅ Redirecting to admin dashboard');
  navigate('/dashboard');
}
```

---

### **2. CustomerRoute.js - Case-Insensitive Check**

**Before:**
```javascript
if (user?.role !== 'Customer') {
  return <Navigate to="/dashboard" replace />;
}
```

**After:**
```javascript
const userRole = user?.role?.toLowerCase();

if (userRole !== 'customer') {
  console.log('⚠️ Not a customer, redirecting to dashboard');
  return <Navigate to="/dashboard" replace />;
}

console.log('✅ Customer access granted');
```

---

### **3. AdminRoute.js - Case-Insensitive Check**

**Before:**
```javascript
if (user?.role === 'Customer') {
  return <Navigate to="/customer" replace />;
}
```

**After:**
```javascript
const userRole = user?.role?.toLowerCase();

if (userRole === 'customer') {
  console.log('⚠️ Customer trying to access admin, redirecting to /customer');
  return <Navigate to="/customer" replace />;
}

console.log('✅ Admin/Staff access granted');
```

---

## 🧪 **Testing Instructions**

### **Step 1: Clear Browser Cache**
```
1. Open browser DevTools (F12)
2. Go to Application tab
3. Clear all storage:
   - localStorage
   - sessionStorage
   - Cookies
4. Hard refresh: Ctrl + Shift + R
```

### **Step 2: Test Customer Login**

1. **Open the online version** of your app
2. **Login as a customer:**
   - Username: (your customer username)
   - Password: (your customer password)
3. **Open browser console** (F12)
4. **Check console logs:**

**Expected output:**
```
🔍 Login successful - User: {...}
🔍 User role: Customer
🔍 Role type: string
✅ Redirecting to customer portal

🔍 CustomerRoute - User role: Customer
🔍 CustomerRoute - Checking access for: {...}
✅ Customer access granted
```

5. **Verify:**
   - ✅ URL changes to `/customer`
   - ✅ Customer portal loads (not admin dashboard)
   - ✅ Customer navbar shows (not admin navbar)

---

### **Step 3: Test Manager/Admin Login**

1. **Logout**
2. **Login as manager:**
   - Username: `manager_colombo`
   - Password: `password123`
3. **Check console logs:**

**Expected output:**
```
🔍 Login successful - User: {...}
🔍 User role: Manager
✅ Redirecting to admin dashboard

🔍 AdminRoute - User role: Manager
✅ Admin/Staff access granted
```

4. **Verify:**
   - ✅ URL changes to `/dashboard`
   - ✅ Admin dashboard loads
   - ✅ Admin navbar and sidebar show

---

## 🔍 **Debugging**

### **If Customer Still Goes to Admin Portal:**

**Check 1: What role is being returned?**

Open browser console and type:
```javascript
const user = JSON.parse(localStorage.getItem('skyNestUser'));
console.log('Stored role:', user.role);
console.log('Role lowercase:', user.role?.toLowerCase());
```

**Check 2: Verify backend response**

In the Network tab of DevTools:
1. Login as customer
2. Find the `/api/auth/login` request
3. Click on it → Response tab
4. Check the `role` field:

```json
{
  "success": true,
  "data": {
    "user": {
      "role": "Customer"  ← Should be here
    },
    "token": "..."
  }
}
```

**Check 3: Database role value**

Run this SQL query:
```sql
SELECT u.username, u.role, g.full_name
FROM user_account u
LEFT JOIN guest g ON u.guest_id = g.guest_id
WHERE u.role ILIKE '%customer%';
```

Expected result:
```
username      | role     | full_name
--------------|----------|----------
nuwan.peiris7 | Customer | Nuwan Peiris
```

⚠️ **If role is not exactly "Customer"**, update it:
```sql
UPDATE user_account 
SET role = 'Customer' 
WHERE role ILIKE '%customer%';
```

---

## 📊 **Role Routing Matrix**

After the fix, this is how routing works:

| User Role | Login Redirects To | Can Access | Cannot Access |
|-----------|-------------------|------------|---------------|
| **Customer** | `/customer` | Customer Portal | Admin Dashboard |
| **Admin** | `/dashboard` | All Admin Pages | Customer Portal |
| **Manager** | `/dashboard` | All Admin Pages (own branch) | Customer Portal |
| **Receptionist** | `/dashboard` | All Admin Pages (own branch) | Customer Portal |
| **Accountant** | `/dashboard` | All Admin Pages (own branch) | Customer Portal |

---

## 🎯 **URL Access Rules**

### **Customer trying to access admin routes:**
```
Customer visits: /dashboard
↓
AdminRoute checks: user.role === 'customer'
↓
Redirects to: /customer
```

### **Admin trying to access customer portal:**
```
Admin visits: /customer
↓
CustomerRoute checks: user.role !== 'customer'
↓
Redirects to: /dashboard
```

---

## ✅ **Verification Checklist**

After deploying the fix to your online version:

- [ ] Clear browser cache
- [ ] Login as customer
- [ ] Verify redirects to `/customer`
- [ ] Verify customer portal loads
- [ ] Check console for `✅ Customer access granted`
- [ ] Logout
- [ ] Login as manager
- [ ] Verify redirects to `/dashboard`
- [ ] Check console for `✅ Admin/Staff access granted`
- [ ] Try visiting `/dashboard` as customer (should redirect to `/customer`)
- [ ] Try visiting `/customer` as manager (should redirect to `/dashboard`)

---

## 🚀 **Deploy to Production**

After testing locally:

```bash
# Commit changes
git add .
git commit -m "Fix: Customer login routing with case-insensitive role check"
git push origin main

# Deploy to Render/Vercel/etc.
# Your deployment platform will automatically rebuild
```

**Wait for deployment to complete, then test online!**

---

## 🐛 **Common Issues**

### **Issue 1: Still redirecting wrong after deploy**

**Solution:**
- Clear browser cache completely
- Try incognito/private window
- Check if old service worker is cached
- Force refresh: Ctrl + Shift + R

### **Issue 2: Console logs not showing**

**Solution:**
- Make sure you're checking browser console, not terminal
- Open DevTools (F12) → Console tab
- Refresh the page after login

### **Issue 3: Role is NULL or undefined**

**Solution:**
- Check backend login response
- Verify user record has role in database
- Check AuthContext is properly merging user data

---

## 📝 **Summary**

**What was changed:**
1. ✅ Added case-insensitive role checking using `.toLowerCase()`
2. ✅ Added console logging for debugging
3. ✅ Applied fix to Login.js, CustomerRoute.js, and AdminRoute.js

**Why it works:**
- Handles any case variation: "Customer", "customer", "CUSTOMER"
- Provides clear debug logs to identify issues
- Prevents case sensitivity bugs

**Test it now on your online version!** 🎉
