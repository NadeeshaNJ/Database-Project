# 🗄️ Backend Database Setup Guide

## Problem Identified
Your backend `.env` file has React frontend variables instead of backend database configuration. This is why the backend won't start.

## ✅ Solution

### Step 1: Update Backend .env File

You need to replace the contents of your backend `.env` file with the proper database configuration.

**File Location:** `c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend\.env`

**Required Contents:**
```env
# Server Configuration
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000

# Database Configuration - EDIT THESE VALUES
DB_HOST=localhost
DB_PORT=5432
DB_NAME=your_database_name
DB_USER=your_database_user
DB_PASSWORD=your_database_password
DB_SSL=false

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=24h

# Email Configuration (Optional - for notifications)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-email-password
EMAIL_FROM=Hotel Management <noreply@hotelmanagement.com>

# Force sync database (Only for development)
FORCE_SYNC=false
```

### Step 2: Configure Your Database Values

Replace these values with your actual PostgreSQL database credentials:

#### 📝 What You Need to Know:

1. **DB_NAME** - Your database name
   - Example: `hotel_management`, `skynest`, `hoteldb`
   - This is the database where your tables will be stored

2. **DB_USER** - Your PostgreSQL username
   - Default is usually: `postgres`
   - Or your custom PostgreSQL user

3. **DB_PASSWORD** - Your PostgreSQL password
   - The password you set when installing PostgreSQL
   - Or the password for your database user

4. **DB_HOST** - Database server location
   - For local: `localhost`
   - For remote: IP address or domain name

5. **DB_PORT** - PostgreSQL port
   - Default: `5432`

6. **JWT_SECRET** - Secret key for JWT tokens
   - Generate a random secure string
   - Example: `myH0telSecr3tK3y2025!@#`

---

## 🎯 Quick Setup Options

### Option 1: Use the Template Below (Recommended)

Copy this and save it as your backend `.env` file:

```env
# Server Configuration
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000

# Database Configuration - UPDATE THESE!
DB_HOST=localhost
DB_PORT=5432
DB_NAME=hotel_management
DB_USER=postgres
DB_PASSWORD=YOUR_PASSWORD_HERE
DB_SSL=false

# JWT Configuration
JWT_SECRET=myHotelSecretKey2025!ChangeThis
JWT_EXPIRES_IN=24h

# Email Configuration (Optional)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=
EMAIL_PASSWORD=
EMAIL_FROM=Hotel Management <noreply@hotelmanagement.com>

# Development
FORCE_SYNC=false
```

### Option 2: Create Database First

If you haven't created a database yet:

```sql
-- Open PostgreSQL command line (psql) or pgAdmin and run:
CREATE DATABASE hotel_management;

-- Or use a different name like:
CREATE DATABASE skynest;
```

---

## 📋 Step-by-Step Instructions

### 1. Find Your PostgreSQL Credentials

**Windows:**
- Open pgAdmin 4
- Your username is usually `postgres`
- Password is what you set during PostgreSQL installation

**Check PostgreSQL is Running:**
```powershell
# Check if PostgreSQL service is running
Get-Service -Name postgresql*
```

### 2. Create/Update the .env File

**Option A: Manual Edit**
```powershell
# Open the file in Notepad
notepad "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend\.env"
```

**Option B: Use PowerShell**
```powershell
# Backup existing .env
Copy-Item "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend\.env" "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend\.env.backup"

# Create new .env (replace YOUR_PASSWORD with actual password)
@"
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000

DB_HOST=localhost
DB_PORT=5432
DB_NAME=hotel_management
DB_USER=postgres
DB_PASSWORD=YOUR_PASSWORD_HERE
DB_SSL=false

JWT_SECRET=myHotelSecretKey2025!ChangeThis
JWT_EXPIRES_IN=24h

FORCE_SYNC=false
"@ | Out-File -FilePath "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend\.env" -Encoding UTF8
```

### 3. Create the Database

**Using pgAdmin:**
1. Open pgAdmin 4
2. Right-click on "Databases"
3. Select "Create" → "Database"
4. Enter name: `hotel_management`
5. Click "Save"

**Using psql command line:**
```sql
psql -U postgres
CREATE DATABASE hotel_management;
\q
```

**Using PowerShell:**
```powershell
# Connect to PostgreSQL and create database
$env:PGPASSWORD="YOUR_PASSWORD"
psql -U postgres -c "CREATE DATABASE hotel_management;"
```

### 4. Test the Connection

```powershell
cd "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"
npm start
```

Look for this output:
```
📊 Database Connection Details:
   Host: localhost
   Port: 5432
   Database: hotel_management
   User: postgres
PostgreSQL Version: PostgreSQL 15.x ...

🚀 Hotel Management System Backend is running!
📍 Port: 5000
```

---

## 🔍 Finding Your SQL Database Location

### If You Have an SQL File/Dump

If you have a `.sql` file with your database schema:

**Import it using:**

1. **pgAdmin:**
   - Create database first
   - Right-click database → "Restore"
   - Select your `.sql` file

2. **psql command:**
   ```powershell
   cd "path\to\your\sql\file"
   psql -U postgres -d hotel_management -f your_database.sql
   ```

3. **PowerShell:**
   ```powershell
   $env:PGPASSWORD="YOUR_PASSWORD"
   Get-Content "path\to\your_database.sql" | psql -U postgres -d hotel_management
   ```

### If You Have a Database Backup

```powershell
# For .backup or .dump files
pg_restore -U postgres -d hotel_management your_backup_file.backup
```

---

## ✅ Verification Checklist

- [ ] PostgreSQL is installed and running
- [ ] Database created (e.g., `hotel_management`)
- [ ] Backend `.env` file updated with correct values
- [ ] `DB_USER` matches your PostgreSQL username
- [ ] `DB_PASSWORD` matches your PostgreSQL password
- [ ] `DB_NAME` matches your database name
- [ ] `JWT_SECRET` is set to a secure value
- [ ] Backend starts without errors
- [ ] Database connection message appears in console

---

## 🐛 Common Issues

### Issue 1: "password authentication failed"
**Solution:** 
- Check `DB_PASSWORD` in `.env`
- Verify password is correct in pgAdmin

### Issue 2: "database does not exist"
**Solution:**
- Create the database first: `CREATE DATABASE hotel_management;`
- Or change `DB_NAME` to match existing database

### Issue 3: "connection refused"
**Solution:**
- Check PostgreSQL is running: `Get-Service postgresql*`
- Start PostgreSQL if stopped
- Verify `DB_PORT` is 5432

### Issue 4: "permission denied"
**Solution:**
- Check `DB_USER` has access to the database
- Grant permissions: `GRANT ALL PRIVILEGES ON DATABASE hotel_management TO postgres;`

### Issue 5: Backend starts but crashes
**Solution:**
- Check all tables exist in database
- Run database migrations/seeds if available

---

## 🚀 After Database Setup

Once your database is configured and backend starts successfully:

1. **Run database seeds (if available):**
   ```powershell
   npm run db:seed
   ```

2. **Start backend:**
   ```powershell
   npm start
   ```

3. **Start frontend:**
   ```powershell
   cd "c:\Users\nadee\Documents\Database-Project"
   npm start
   ```

4. **Test integration:**
   - Visit http://localhost:3000
   - Use the BackendIntegrationTest component

---

## 📞 Need Help?

### Quick Diagnostic Command
```powershell
cd "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"

# Check .env file
Write-Host "`n=== Current .env Configuration ===" -ForegroundColor Cyan
Get-Content .env | Select-String "DB_|PORT|JWT_SECRET"

# Check PostgreSQL service
Write-Host "`n=== PostgreSQL Service Status ===" -ForegroundColor Cyan
Get-Service postgresql*

# Try to start backend
Write-Host "`n=== Starting Backend ===" -ForegroundColor Cyan
npm start
```

### What to Share if You Need Support
1. PostgreSQL version: `psql --version`
2. Service status: `Get-Service postgresql*`
3. .env file (hide password): `Get-Content .env | Select-String "DB_NAME|DB_USER|DB_HOST"`
4. Backend error message from terminal

---

## 📝 Example Working Configuration

Here's a complete example that should work if you have PostgreSQL installed locally:

```env
# .env file for backend
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000

# Database - Local PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=hotel_management
DB_USER=postgres
DB_PASSWORD=postgres
DB_SSL=false

# JWT
JWT_SECRET=mySecretKey123!@#
JWT_EXPIRES_IN=24h

# Development
FORCE_SYNC=false
```

Save this, create the `hotel_management` database, and start your backend!

---

**Last Updated:** October 15, 2025
**Status:** Configuration Guide Ready
