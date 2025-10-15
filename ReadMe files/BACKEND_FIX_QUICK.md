# 🗄️ Quick Fix: Backend Database Setup

## ❌ Problem Found
Your backend won't start because the `.env` file has **wrong configuration** (React frontend variables instead of backend database settings).

---

## ✅ Solution: 3 Easy Options

### 🎯 Option 1: Use the Setup Script (EASIEST)

```powershell
cd "c:\Users\nadee\Documents\Database-Project"
.\setup-backend-database.ps1
```

The script will:
- ✅ Check if PostgreSQL is running
- ✅ Ask for your database credentials
- ✅ Create the .env file automatically
- ✅ Test the database connection
- ✅ Create the database if it doesn't exist

---

### 🎯 Option 2: Manual Setup (QUICK)

1. **Open the backend .env file:**
   ```powershell
   notepad "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend\.env"
   ```

2. **Replace ALL contents with this:**
   ```env
   PORT=5000
   NODE_ENV=development
   FRONTEND_URL=http://localhost:3000

   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=hotel_management
   DB_USER=postgres
   DB_PASSWORD=YOUR_POSTGRES_PASSWORD
   DB_SSL=false

   JWT_SECRET=myHotelSecret2025!ChangeThis
   JWT_EXPIRES_IN=24h

   FORCE_SYNC=false
   ```

3. **Change these values:**
   - `DB_PASSWORD` = Your PostgreSQL password
   - `DB_NAME` = Your database name (or keep `hotel_management`)

4. **Save and close**

---

### 🎯 Option 3: Use PowerShell Command (FASTEST)

```powershell
# Replace YOUR_PASSWORD with your actual PostgreSQL password
@"
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000

DB_HOST=localhost
DB_PORT=5432
DB_NAME=hotel_management
DB_USER=postgres
DB_PASSWORD=YOUR_PASSWORD
DB_SSL=false

JWT_SECRET=myHotelSecret2025!ChangeThis
JWT_EXPIRES_IN=24h

FORCE_SYNC=false
"@ | Out-File -FilePath "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend\.env" -Encoding UTF8
```

---

## 📋 What You Need

### PostgreSQL Credentials

1. **Database Name** - Where to store data
   - Default suggestion: `hotel_management`
   - Or use existing database name

2. **Username** - PostgreSQL user
   - Usually: `postgres`

3. **Password** - PostgreSQL password
   - The password you set during PostgreSQL installation

4. **Host** - Where PostgreSQL is running
   - For local: `localhost`

5. **Port** - PostgreSQL port
   - Default: `5432`

---

## 🔍 Find Your PostgreSQL Info

### Check if PostgreSQL is Running
```powershell
Get-Service postgresql*
```
Should show: **Status: Running**

### Find PostgreSQL Password
- You set this when you installed PostgreSQL
- Try opening pgAdmin 4 - it might have saved credentials
- Common test passwords: `postgres`, `admin`, `password`

---

## 🗄️ Create Database (if needed)

### Using pgAdmin:
1. Open pgAdmin 4
2. Connect to server (enter password)
3. Right-click "Databases" → Create → Database
4. Name it: `hotel_management`
5. Click Save

### Using Command Line:
```powershell
# Replace YOUR_PASSWORD
$env:PGPASSWORD="YOUR_PASSWORD"
psql -U postgres -c "CREATE DATABASE hotel_management;"
```

---

## 🚀 Test Backend

After configuring the .env file:

```powershell
cd "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"
npm start
```

### ✅ Success Looks Like:
```
📊 Database Connection Details:
   Host: localhost
   Port: 5432
   Database: hotel_management
   User: postgres

PostgreSQL Version: PostgreSQL 15.x ...

🚀 Hotel Management System Backend is running!
📍 Port: 5000
🌍 Environment: development
```

### ❌ If You See Errors:

**"password authentication failed"**
→ Wrong password in .env file

**"database does not exist"**
→ Create the database first (see above)

**"connection refused"**
→ PostgreSQL not running - start it:
```powershell
Start-Service postgresql*
```

---

## 📚 More Help

For detailed instructions:
```powershell
# Open the complete guide
notepad "c:\Users\nadee\Documents\Database-Project\BACKEND_DATABASE_SETUP.md"
```

---

## ⚡ Quick Checklist

- [ ] PostgreSQL installed and running
- [ ] Know your PostgreSQL password
- [ ] Database created (or will be created)
- [ ] Backend .env file updated
- [ ] Backend starts without errors

---

## 🎯 Next Steps After Backend Works

1. **Backend running** on http://localhost:5000
2. **Start frontend:**
   ```powershell
   cd "c:\Users\nadee\Documents\Database-Project"
   npm start
   ```
3. **Test integration** at http://localhost:3000

---

**Need more help?** Read: `BACKEND_DATABASE_SETUP.md`
