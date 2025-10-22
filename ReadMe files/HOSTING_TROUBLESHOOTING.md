# 🔍 Hosting Troubleshooting Guide

## Issue: Frontend Not Loading

### What Was Fixed (October 22, 2025)

1. **Added missing `REACT_APP_API_URL` to `.env.production`**
   - The frontend was trying to connect to `localhost:5000` in production
   - Now correctly points to: `https://skynest-backend-api.onrender.com/api`

2. **Rebuilt and redeployed the application**
   - Clean build with production environment variables
   - Deployed to GitHub Pages at: https://nadeeshanj.github.io/Database-Project

---

## How to Test Your Website

### 1. Open the Website
Visit: **https://nadeeshanj.github.io/Database-Project**

### 2. Check Browser Console (IMPORTANT!)
Press `F12` or right-click → "Inspect" → Go to "Console" tab

**What to look for:**
- ✅ **GOOD**: No errors, or only minor warnings
- ❌ **BAD**: Red errors mentioning "localhost", "CORS", "Network Error"

### 3. Test Login
Try logging in with test credentials:
- **Username**: `admin`
- **Password**: `password123`

**Expected behavior:**
- Should redirect to dashboard
- Should show hotel statistics

### 4. Check Network Tab
In browser dev tools (F12), go to "Network" tab:
- Look for API calls going to `skynest-backend-api.onrender.com`
- ✅ **GOOD**: Status 200 (or 201)
- ⚠️ **WARNING**: Status 504 (Gateway Timeout - backend is waking up)
- ❌ **BAD**: Status 0 (CORS issue) or calls to `localhost`

---

## Common Issues & Solutions

### Issue 1: "Site Not Loading / White Screen"

**Possible Causes:**
1. Browser cache showing old version
2. GitHub Pages hasn't updated yet (takes 1-2 minutes)

**Solutions:**
```bash
# Hard refresh in browser
Windows: Ctrl + Shift + R
Mac: Cmd + Shift + R

# Or clear browser cache:
Windows: Ctrl + Shift + Delete
Mac: Cmd + Shift + Delete
```

### Issue 2: "API Calls Failing"

**Check this in Console (F12):**
```
If you see: "localhost:5000" in any error
→ Build wasn't done with production env variables

If you see: "CORS policy blocked"
→ Backend CORS settings need updating
```

**Solution:**
```bash
# In Database-Project folder
cd "c:\Users\nadee\Documents\Database-Project"

# Clean and rebuild
Remove-Item -Recurse -Force build
npm run build
npm run deploy
```

### Issue 3: "Backend Taking Too Long (504 Error)"

**This is NORMAL for Render free tier!**
- Backend spins down after 15 minutes of inactivity
- First request can take 30-60 seconds to wake up
- Just wait and try again

**What you'll see:**
1. First API call: 504 Gateway Timeout
2. Wait 30 seconds
3. Try again: Should work

### Issue 4: "Cannot Login / Authentication Failed"

**Check:**
1. Are you using correct credentials? (see test credentials below)
2. Is backend actually running?
3. Check browser console for error details

**Test Backend:**
```bash
# In PowerShell
curl https://skynest-backend-api.onrender.com/api/health
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Hotel Management API is running",
  "timestamp": "2025-10-22T...",
  "environment": "production"
}
```

---

## Test Credentials

### Admin Account
- **Username**: `admin`
- **Password**: `password123`
- **Access**: Full system access

### Branch Managers
- `manager_colombo` / `password123` (Colombo Branch)
- `manager_kandy` / `password123` (Kandy Branch)
- `manager_galle` / `password123` (Galle Branch)

### Receptionists
- `recept_colombo` / `password123`
- `recept_kandy` / `password123`
- `recept_galle` / `password123`

### Accountants
- `accountant_colombo` / `password123`
- `accountant_kandy` / `password123`
- `accountant_galle` / `password123`

---

## Verification Checklist

Use this checklist to verify everything is working:

### Frontend (GitHub Pages)
- [ ] Website loads at https://nadeeshanj.github.io/Database-Project
- [ ] Landing page displays correctly
- [ ] Login button is visible and clickable
- [ ] No console errors related to "localhost"
- [ ] Browser console shows API calls to `skynest-backend-api.onrender.com`

### Backend (Render)
- [ ] Health check works: https://skynest-backend-api.onrender.com/api/health
- [ ] Returns JSON response with `"success": true`
- [ ] Status code is 200

### Full Integration
- [ ] Can login with admin credentials
- [ ] Dashboard loads with statistics
- [ ] Can view guests, rooms, bookings pages
- [ ] Data is loading from backend (not empty)
- [ ] No CORS errors in console

---

## How to Redeploy (If Needed)

### Frontend Only
```powershell
cd "c:\Users\nadee\Documents\Database-Project"
npm run deploy
```

### Backend (Render Auto-Deploys)
Just push to GitHub main branch:
```bash
cd "c:\Users\nadee\Documents\Database-Back"
git add .
git commit -m "Your message"
git push origin main
```

Render will automatically detect the push and redeploy (takes 3-5 minutes).

---

## Environment Files Reference

### Frontend `.env.production` (CRITICAL!)
```env
REACT_APP_API_BASE=https://skynest-backend-api.onrender.com
REACT_APP_API_URL=https://skynest-backend-api.onrender.com/api
REACT_APP_APP_NAME=Hotel Management System
REACT_APP_VERSION=1.0.0
REACT_APP_ENV=production
REACT_APP_DEBUG=false
```

### Backend `.env` (On Render Dashboard)
```env
NODE_ENV=production
PORT=10000
DATABASE_URL=<your-render-database-url>
JWT_SECRET=<your-secret>
JWT_EXPIRES_IN=24h
FRONTEND_URL=https://nadeeshanj.github.io
DB_SSL=true
```

---

## Still Not Working?

### Step 1: Check Current Status
```powershell
# Test frontend
curl https://nadeeshanj.github.io/Database-Project/

# Test backend
curl https://skynest-backend-api.onrender.com/api/health
```

### Step 2: Review Deployment
```powershell
cd "c:\Users\nadee\Documents\Database-Project"

# Check if .env.production has REACT_APP_API_URL
Get-Content .env.production | Select-String "API_URL"

# Check last deployment
git log origin/gh-pages --oneline -1
```

### Step 3: Force Fresh Deployment
```powershell
# Clean everything
Remove-Item -Recurse -Force build
Remove-Item -Recurse -Force node_modules/.cache -ErrorAction SilentlyContinue

# Fresh build and deploy
npm run build
npm run deploy
```

### Step 4: Clear Browser Cache
- Chrome/Edge: `Ctrl + Shift + Delete` → Clear browsing data
- Select "Cached images and files"
- Time range: "All time"
- Click "Clear data"

### Step 5: Wait for Propagation
- GitHub Pages can take 1-2 minutes to update
- Try in incognito/private mode
- Try on different device or network

---

## Contact Information

If problems persist:
1. Check GitHub Actions for deployment status
2. Review Render dashboard for backend logs
3. Check browser console for specific error messages
4. Verify environment variables are set correctly

---

## Last Successful Deployment

- **Date**: October 22, 2025
- **Frontend**: https://nadeeshanj.github.io/Database-Project ✅
- **Backend**: https://skynest-backend-api.onrender.com ✅
- **Status**: Both services operational

---

*Document created: October 22, 2025*
*Last updated: October 22, 2025*
