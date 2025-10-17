# 🔗 Update Frontend to Use Deployed Backend

## When to Use This Guide
After you've successfully deployed your backend to Render and received your backend URL (e.g., `https://skynest-backend-api.onrender.com`).

---

## 🎯 Quick Update (2 Files)

### File 1: `src/utils/api.js`

**Current:**
```javascript
const API_BASE = process.env.REACT_APP_API_BASE || 'http://localhost:5000';
```

**Update to:**
```javascript
const API_BASE = process.env.REACT_APP_API_BASE || 'https://skynest-backend-api.onrender.com';
```

---

### File 2: `src/pages/Guests.js`

**Current:**
```javascript
const API_URL = 'http://localhost:5000/api/guests';
```

**Update to:**
```javascript
const API_URL = 'https://skynest-backend-api.onrender.com/api/guests';
```

---

## 🔐 Update Backend CORS (Important!)

Your backend needs to allow requests from your deployed frontend.

**File:** `Database-Back/server.js` or `Database-Back/app.js`

Find the CORS configuration and update:

```javascript
// Current (might look like this)
const corsOptions = {
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  // ...
};

// Should be:
const corsOptions = {
  origin: [
    'http://localhost:3000',  // Keep for local development
    'https://nadeeshanj.github.io'  // Add your GitHub Pages URL
  ],
  credentials: true,
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
```

---

## 🚀 Redeploy Frontend

After making changes:

```bash
cd C:\Users\nadee\Documents\Database-Project

# Build and deploy to GitHub Pages
npm run deploy
```

Wait 2-3 minutes, then visit:
```
https://nadeeshanj.github.io/Database-Project/
```

---

## ✅ Verification

1. **Open Browser DevTools** (F12)
2. **Go to Console tab**
3. **Visit your deployed site**
4. **Check for:**
   - ✅ No CORS errors
   - ✅ API requests going to Render URL
   - ✅ Data loading successfully
   - ❌ No "Failed to fetch" errors
   - ❌ No "Mixed Content" warnings

---

## 🔄 Environment Variables (Optional)

For better configuration management, create:

**File:** `.env.production` (in Database-Project folder)

```env
REACT_APP_API_BASE=https://skynest-backend-api.onrender.com
```

Then your code can stay as:
```javascript
const API_BASE = process.env.REACT_APP_API_BASE || 'http://localhost:5000';
```

---

## 📋 Quick Checklist

- [ ] Backend deployed and running on Render
- [ ] Backend URL copied (e.g., https://skynest-backend-api.onrender.com)
- [ ] Updated `src/utils/api.js`
- [ ] Updated `src/pages/Guests.js`
- [ ] Updated backend CORS to allow GitHub Pages
- [ ] Ran `npm run deploy`
- [ ] Verified site works in browser
- [ ] No console errors

---

## 🐛 Troubleshooting

### Still seeing localhost:5000 in Network tab?

**Solution:** Hard refresh the page
- Chrome/Edge: `Ctrl + Shift + R`
- Firefox: `Ctrl + F5`

### CORS Error: "No 'Access-Control-Allow-Origin' header"

**Solution:** Update backend CORS configuration
1. Go to Database-Back project
2. Update CORS to include GitHub Pages URL
3. Commit and push (Render auto-deploys)
4. Wait 2-3 minutes for redeploy

### Mixed Content Error

**Solution:** Ensure ALL URLs use HTTPS (not HTTP)
- ✅ `https://skynest-backend-api.onrender.com`
- ❌ `http://skynest-backend-api.onrender.com`

### 502 Bad Gateway

**Solution:** Backend might be sleeping (free tier)
- First request after 15min inactivity takes 30-60 seconds
- Refresh the page
- Wait for backend to wake up

---

## 💡 Pro Tips

1. **Keep localhost for development:**
   ```javascript
   const API_BASE = process.env.NODE_ENV === 'production' 
     ? 'https://skynest-backend-api.onrender.com'
     : 'http://localhost:5000';
   ```

2. **Use environment files:**
   - `.env.development` → localhost
   - `.env.production` → Render URL

3. **Test locally first:**
   ```bash
   # Test against deployed backend locally
   REACT_APP_API_BASE=https://skynest-backend-api.onrender.com npm start
   ```

---

That's it! Your frontend will now communicate with your deployed backend. 🎉
