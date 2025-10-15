cd "c:\Users\nadee\Documents\Database-Project"
.\complete-setup.ps1# 🎯 ONE COMMAND SETUP - All You Need!

## ✨ Your SQL file is already in the right place!

**Location:** `c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend\skynest_schema.sql`

---

## 🚀 Run This ONE Command:

```powershell
cd "c:\Users\nadee\Documents\Database-Project"
.\complete-setup.ps1
```

---

## 📋 What This Script Does (Automatically):

1. ✅ Checks if PostgreSQL is running
2. ✅ Asks for your PostgreSQL password (one time only)
3. ✅ Creates the backend `.env` file with correct settings
4. ✅ Imports your `skynest_schema.sql` database
5. ✅ Installs backend dependencies
6. ✅ Verifies everything works
7. ✅ Offers to start the backend immediately

---

## 🔑 What You Need:

**Just ONE thing:** Your PostgreSQL password
- This is the password you set when you installed PostgreSQL
- Usually the username is: `postgres`

---

## ⚡ Quick Start:

### Step 1: Open PowerShell
- Press `Windows + X`
- Select "Windows PowerShell" or "Terminal"

### Step 2: Run the Setup Script
```powershell
cd "c:\Users\nadee\Documents\Database-Project"
.\complete-setup.ps1
```

### Step 3: Follow the Prompts
- Enter your PostgreSQL username (press Enter for `postgres`)
- Enter your PostgreSQL password
- Wait for the magic to happen! ✨

### Step 4: Start Coding!
The script will ask if you want to start the backend immediately.
- Type `y` to start now
- Or start later with: `npm start`

---

## 🎊 That's It!

Your database will be:
- ✅ Created from your SQL file
- ✅ Connected to your backend
- ✅ Ready to use!

Then just start your frontend:
```powershell
# In a new terminal
cd "c:\Users\nadee\Documents\Database-Project"
npm start
```

---

## 📊 What Happens:

```
Your SQL File (skynest_schema.sql)
           ↓
     [Setup Script]
           ↓
    Creates Database "skynest"
           ↓
    Configures Backend .env
           ↓
  Backend Can Connect to Database!
           ↓
         SUCCESS! 🎉
```

---

## 🐛 If Something Goes Wrong:

### "psql is not recognized"
PostgreSQL is not in your PATH. Use full path:
```powershell
& "C:\Program Files\PostgreSQL\15\bin\psql.exe" --version
```
Or add PostgreSQL to your PATH.

### "password authentication failed"
Wrong password. Run the script again with correct password.

### "permission denied"
Run PowerShell as Administrator:
- Right-click PowerShell → "Run as administrator"

---

## 🎯 After Setup:

### Start Backend:
```powershell
cd "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"
npm start
```

Expected output:
```
📊 Database Connection Details:
   Host: localhost
   Port: 5432
   Database: skynest
   User: postgres

PostgreSQL Version: PostgreSQL 17.x ...

🚀 Hotel Management System Backend is running!
📍 Port: 5000
```

### Start Frontend:
```powershell
cd "c:\Users\nadee\Documents\Database-Project"
npm start
```

### Open Browser:
```
http://localhost:3000
```

---

## 🎉 You're Done!

**One script. One command. Everything set up!**

```powershell
cd "c:\Users\nadee\Documents\Database-Project"
.\complete-setup.ps1
```

---

## 📞 Need Help?

If the script fails, you can manually:

1. **Import Database:**
   ```powershell
   cd "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"
   $env:PGPASSWORD="your_password"
   psql -U postgres -f skynest_schema.sql
   ```

2. **Create .env file:**
   ```powershell
   notepad "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend\.env"
   ```
   Paste:
   ```env
   PORT=5000
   NODE_ENV=development
   FRONTEND_URL=http://localhost:3000
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=skynest
   DB_USER=postgres
   DB_PASSWORD=your_password_here
   DB_SSL=false
   JWT_SECRET=mySecretKey123!@#
   JWT_EXPIRES_IN=24h
   FORCE_SYNC=false
   ```

3. **Start Backend:**
   ```powershell
   cd "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"
   npm start
   ```

---

**That's all! Your SQL file is in the right place. Just run the setup script! 🚀**
