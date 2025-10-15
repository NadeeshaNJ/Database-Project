# 🎯 QUICK REFERENCE CARD

## Your SQL File: ✅ Already in the Right Place!

**Location:** `Database-Project-Backend\skynest_schema.sql`

---

## 🚀 SETUP IN ONE COMMAND:

```powershell
cd "c:\Users\nadee\Documents\Database-Project"
.\complete-setup.ps1
```

**What you need:** Just your PostgreSQL password!

---

## ⚡ MANUAL SETUP (if needed):

### 1. Fix Backend .env:
```powershell
notepad "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend\.env"
```

Paste this (change PASSWORD):
```env
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=skynest
DB_USER=postgres
DB_PASSWORD=YOUR_PASSWORD
DB_SSL=false
JWT_SECRET=mySecret123!@#
JWT_EXPIRES_IN=24h
FORCE_SYNC=false
```

### 2. Import Database:
```powershell
cd "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"
$env:PGPASSWORD="YOUR_PASSWORD"
psql -U postgres -f skynest_schema.sql
```

### 3. Start Backend:
```powershell
npm start
```

### 4. Start Frontend:
```powershell
cd "c:\Users\nadee\Documents\Database-Project"
npm start
```

---

## 🎯 URLs:

- **Backend:** http://localhost:5000
- **Frontend:** http://localhost:3000
- **API Base:** http://localhost:5000/api

---

## ✅ Success Checklist:

- [ ] PostgreSQL running
- [ ] Database imported from SQL file
- [ ] Backend .env configured
- [ ] Backend starts (port 5000)
- [ ] Frontend starts (port 3000)
- [ ] Can login to application

---

## 📁 Key Files:

```
Database-Project-Backend/
├── skynest_schema.sql    ← Your SQL file (HERE!)
├── .env                  ← Fix this file
├── server.js             ← Backend entry
└── package.json

Database-Project/
├── complete-setup.ps1    ← RUN THIS!
├── ONE_COMMAND_SETUP.md  ← Read this
└── src/
    └── services/
        └── api.js        ← Already fixed ✅
```

---

## 🆘 Quick Troubleshooting:

| Problem | Solution |
|---------|----------|
| Backend won't start | Fix .env file |
| "password failed" | Wrong password in .env |
| "database not exist" | Import SQL file |
| "psql not found" | Add PostgreSQL to PATH |
| CORS error | Frontend must be port 3000 |

---

## 📞 Help Commands:

```powershell
# Check PostgreSQL status
Get-Service postgresql*

# Check if database exists
psql -U postgres -l

# Test backend .env
Get-Content "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend\.env" | Select-String "DB_"
```

---

## 🎉 SIMPLEST PATH:

```powershell
.\complete-setup.ps1
```

**That's it!** Everything else is automatic! 🚀

---

**Save this file! It has everything you need!**
