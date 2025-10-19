# 🚀 Automatic Deployment Guide

## Overview

The SkyNest project now uses **GitHub Actions** for automatic deployment. When you push to the `main` branch, the following happens automatically:

1. ✅ **Build** - React app is built with production settings
2. ✅ **Test** - Code quality and security checks run
3. ✅ **Deploy** - Automatically deployed to GitHub Pages
4. ✅ **Live** - Changes appear on your live site within 2-3 minutes

---

## 🎯 How It Works

### When You Push to `main`:

```bash
git add .
git commit -m "Your commit message"
git push
```

**GitHub Actions automatically:**
- Builds your React app
- Uses production environment variables
- Deploys to GitHub Pages (`gh-pages` branch)
- Makes changes live at: `https://nadeeshanj.github.io/Database-Project`

---

## 📋 What Changed

### ❌ **OLD Process (Manual)**
```bash
npm run build          # Build locally
npm run deploy         # Push to gh-pages manually
```

### ✅ **NEW Process (Automatic)**
```bash
git push               # That's it! GitHub Actions handles the rest
```

---

## 🔍 Monitoring Deployments

### Check Deployment Status:

1. **GitHub Actions Tab**  
   Go to: `https://github.com/NadeeshaNJ/Database-Project/actions`
   
2. **Watch the Workflow**  
   You'll see: "SkyNest Frontend CI/CD"
   - 🟡 Yellow = Running
   - 🟢 Green = Success
   - 🔴 Red = Failed

3. **Deployment Time**  
   Typically takes **2-3 minutes** from push to live

---

## 🌐 Live URLs

| Environment | URL | Updated By |
|-------------|-----|------------|
| **Production** | https://nadeeshanj.github.io/Database-Project | GitHub Actions (automatic on push to `main`) |
| **Backend API** | https://skynest-backend-api.onrender.com | Render (automatic on push to `Database-Back/main`) |

---

## 🛠️ Environment Variables

The GitHub Actions workflow automatically uses these production settings:

```bash
REACT_APP_API_BASE=https://skynest-backend-api.onrender.com
REACT_APP_ENV=production
REACT_APP_DEBUG=false
```

These are **hardcoded in the workflow** so you don't need to worry about `.env` files being deployed.

---

## 🚨 Troubleshooting

### Changes Not Showing Up?

1. **Check GitHub Actions**  
   - Go to Actions tab
   - Verify the workflow completed successfully (green checkmark)
   - If failed (red X), click to see error logs

2. **Clear Browser Cache**  
   - Hard refresh: `Ctrl + Shift + F5`
   - Or use Incognito/Private mode
   - Or clear browser cache completely

3. **Wait for CDN**  
   - GitHub Pages uses a CDN
   - Changes can take 2-5 minutes to propagate
   - Be patient!

### Workflow Failed?

**Common Causes:**
- Build error (check logs in GitHub Actions)
- Missing dependencies
- Syntax errors in code

**Fix:**
1. Check the error message in GitHub Actions
2. Fix the issue locally
3. Push again - workflow will re-run automatically

---

## 📊 Workflow Details

The workflow has 5 jobs:

1. **Build** 🏗️  
   - Installs dependencies
   - Builds React app
   - Creates production bundle

2. **Quality** 📊  
   - Checks project structure
   - Scans for console.log
   - Finds TODO/FIXME comments

3. **Security** 🔒  
   - Runs npm audit
   - Checks for hardcoded secrets
   - Validates dependencies

4. **Deploy** 🚀  
   - Only runs on `main` branch
   - Pushes build to `gh-pages` branch
   - Updates live site

5. **Report** 📝  
   - Generates summary
   - Shows all job statuses
   - Provides live URL

---

## 💡 Benefits

### Before (Manual Deployment)
- ❌ Had to remember to run `npm run deploy`
- ❌ Could forget to build
- ❌ Manual process prone to errors
- ❌ Local build might differ from production

### After (Automatic Deployment)
- ✅ Just push code
- ✅ Consistent builds every time
- ✅ Automatic deployment
- ✅ Build artifacts tracked
- ✅ Full CI/CD pipeline

---

## 🔐 Backend Deployment

The **backend** (Database-Back repo) also has GitHub Actions:

- **Repository:** https://github.com/NadeeshaNJ/Database-Back
- **Workflow:** Backend CI/CD
- **Triggers:** Push to `main` or `develop`
- **Deployment:** Render (automatic)

Both frontend and backend are now fully automated! 🎉

---

## 📝 Quick Reference

| Action | Command |
|--------|---------|
| Deploy to Production | `git push` (to main) |
| Check Deployment Status | Visit GitHub Actions tab |
| View Live Site | https://nadeeshanj.github.io/Database-Project |
| Manual Build (local testing) | `npm run build` |
| Local Development | `npm start` |

---

## ⚙️ Advanced: Manual Trigger

You can also trigger deployment manually without pushing:

1. Go to: https://github.com/NadeeshaNJ/Database-Project/actions
2. Click "SkyNest Frontend CI/CD"
3. Click "Run workflow" button
4. Select `main` branch
5. Click green "Run workflow"

---

## 🎓 Summary

**What you need to know:**

1. ✅ Push to `main` = Automatic deployment
2. ✅ Check GitHub Actions tab to monitor progress
3. ✅ Wait 2-3 minutes for changes to go live
4. ✅ Hard refresh browser if changes don't appear
5. ✅ No more `npm run deploy` needed!

**Your new workflow:**

```bash
# 1. Make changes to code
vim src/pages/Dashboard.js

# 2. Commit and push
git add .
git commit -m "Update dashboard"
git push

# 3. Wait ~3 minutes
# 4. Hard refresh browser (Ctrl + Shift + F5)
# 5. See your changes live! 🎉
```

---

*Last Updated: October 19, 2025*  
*Deployment System: GitHub Actions + GitHub Pages*
