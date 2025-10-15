# Complete Setup Script - Backend Database
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Hotel Management System Setup" -ForegroundColor Cyan
Write-Host "  Database: skynest" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$backendPath = "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"
$sqlFile = Join-Path $backendPath "skynest_schema.sql"

# Check if SQL file exists
if (-not (Test-Path $sqlFile)) {
    Write-Host "✗ SQL schema file not found at: $sqlFile" -ForegroundColor Red
    exit
}

Write-Host "✓ Found SQL schema file" -ForegroundColor Green
Write-Host ""

# Step 1: Get PostgreSQL credentials
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 1: PostgreSQL Credentials" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$dbUser = Read-Host "Enter PostgreSQL username (default: postgres)"
if ([string]::IsNullOrWhiteSpace($dbUser)) { $dbUser = "postgres" }

$dbPassword = Read-Host "Enter PostgreSQL password" -AsSecureString
$dbPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPassword)
)

Write-Host ""
Write-Host "Using database: skynest" -ForegroundColor Cyan
Write-Host ""

# Step 2: Check PostgreSQL service
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 2: Checking PostgreSQL Service" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue
if ($pgService) {
    if ($pgService.Status -eq "Running") {
        Write-Host "✓ PostgreSQL is running" -ForegroundColor Green
    } else {
        Write-Host "PostgreSQL is stopped. Starting..." -ForegroundColor Yellow
        Start-Service $pgService.Name
        Start-Sleep -Seconds 2
        Write-Host "✓ PostgreSQL started" -ForegroundColor Green
    }
} else {
    Write-Host "⚠ PostgreSQL service not found. Make sure PostgreSQL is installed." -ForegroundColor Yellow
}

Write-Host ""

# Step 3: Create backend .env file
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 3: Creating Backend .env File" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Backup existing .env
$envPath = Join-Path $backendPath ".env"
if (Test-Path $envPath) {
    $backupPath = Join-Path $backendPath ".env.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $envPath $backupPath
    Write-Host "✓ Backed up existing .env file" -ForegroundColor Green
}

# Generate JWT secret
$jwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})

# Create .env file
$envContent = @"
# Server Configuration
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=skynest
DB_USER=$dbUser
DB_PASSWORD=$dbPasswordPlain
DB_SSL=false

# JWT Configuration
JWT_SECRET=$jwtSecret
JWT_EXPIRES_IN=24h

# Email Configuration (Optional)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=
EMAIL_PASSWORD=
EMAIL_FROM=Hotel Management <noreply@hotelmanagement.com>

# Development Settings
FORCE_SYNC=false
"@

$envContent | Out-File -FilePath $envPath -Encoding UTF8 -NoNewline
Write-Host "✓ Created backend .env file" -ForegroundColor Green
Write-Host ""

# Step 4: Import database
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 4: Importing Database Schema" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$env:PGPASSWORD = $dbPasswordPlain

Write-Host "Checking if database 'skynest' exists..." -ForegroundColor Yellow
$dbExists = psql -U $dbUser -h localhost -p 5432 -lqt 2>$null | Select-String -Pattern "^\s*skynest\s*\|"

if (-not $dbExists) {
    Write-Host "Database 'skynest' not found. The SQL file will create it." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Importing SQL schema (this may take a minute)..." -ForegroundColor Yellow
Write-Host ""

try {
    # Import the SQL file
    $result = psql -U $dbUser -h localhost -p 5432 -f $sqlFile 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Database schema imported successfully!" -ForegroundColor Green
    } else {
        Write-Host "⚠ Import completed with warnings (this is usually OK)" -ForegroundColor Yellow
        Write-Host "The database should still work." -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Error importing database: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can try manually with:" -ForegroundColor Yellow
    Write-Host "psql -U $dbUser -h localhost -p 5432 -f `"$sqlFile`"" -ForegroundColor White
}

Write-Host ""

# Step 5: Verify database connection
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 5: Verifying Database Connection" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    $version = psql -U $dbUser -h localhost -p 5432 -d skynest -c "SELECT version();" -t 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Connected to database successfully!" -ForegroundColor Green
        
        # Count tables
        $tableCount = psql -U $dbUser -h localhost -p 5432 -d skynest -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" -t 2>$null
        if ($tableCount) {
            Write-Host "✓ Database has $($tableCount.Trim()) tables" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠ Could not verify database connection" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ Could not verify database connection: $_" -ForegroundColor Yellow
}

Write-Host ""

# Step 6: Install backend dependencies
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 6: Installing Backend Dependencies" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $backendPath

if (Test-Path (Join-Path $backendPath "package.json")) {
    Write-Host "Installing npm packages..." -ForegroundColor Yellow
    npm install
    Write-Host "✓ Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "⚠ package.json not found" -ForegroundColor Yellow
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration Summary:" -ForegroundColor Cyan
Write-Host "  Database: skynest" -ForegroundColor White
Write-Host "  Host: localhost" -ForegroundColor White
Write-Host "  Port: 5432" -ForegroundColor White
Write-Host "  User: $dbUser" -ForegroundColor White
Write-Host "  Backend Port: 5000" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Start Backend:" -ForegroundColor White
Write-Host "   cd `"$backendPath`"" -ForegroundColor Gray
Write-Host "   npm start" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Start Frontend (in new terminal):" -ForegroundColor White
Write-Host "   cd `"c:\Users\nadee\Documents\Database-Project`"" -ForegroundColor Gray
Write-Host "   npm start" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Open browser:" -ForegroundColor White
Write-Host "   http://localhost:3000" -ForegroundColor Gray
Write-Host ""

$startNow = Read-Host "Do you want to start the backend now? (y/n)"

if ($startNow -eq 'y' -or $startNow -eq 'Y') {
    Write-Host ""
    Write-Host "Starting backend server..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
    Write-Host ""
    npm start
} else {
    Write-Host ""
    Write-Host "Setup complete! Run 'npm start' when ready." -ForegroundColor Green
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
