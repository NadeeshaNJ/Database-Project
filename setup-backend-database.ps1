# Backend Database Configuration Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Backend Database Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$backendPath = "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"

# Check if PostgreSQL is running
Write-Host "Checking PostgreSQL service..." -ForegroundColor Yellow
$pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue

if ($pgService) {
    if ($pgService.Status -eq "Running") {
        Write-Host "✓ PostgreSQL is running" -ForegroundColor Green
    } else {
        Write-Host "✗ PostgreSQL is not running" -ForegroundColor Red
        Write-Host "Please start PostgreSQL service first" -ForegroundColor Yellow
        exit
    }
} else {
    Write-Host "⚠ PostgreSQL service not found" -ForegroundColor Yellow
    Write-Host "Make sure PostgreSQL is installed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Database Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get database details
$dbName = Read-Host "Enter database name (e.g., hotel_management)"
$dbUser = Read-Host "Enter database user (default: postgres)"
if ([string]::IsNullOrWhiteSpace($dbUser)) { $dbUser = "postgres" }

$dbPassword = Read-Host "Enter database password" -AsSecureString
$dbPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPassword)
)

$dbHost = Read-Host "Enter database host (default: localhost)"
if ([string]::IsNullOrWhiteSpace($dbHost)) { $dbHost = "localhost" }

$dbPort = Read-Host "Enter database port (default: 5432)"
if ([string]::IsNullOrWhiteSpace($dbPort)) { $dbPort = "5432" }

Write-Host ""
Write-Host "Generating JWT secret..." -ForegroundColor Yellow
$jwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})

# Create .env file
Write-Host ""
Write-Host "Creating .env file..." -ForegroundColor Yellow

# Backup existing .env if it exists
$envPath = Join-Path $backendPath ".env"
if (Test-Path $envPath) {
    $backupPath = Join-Path $backendPath ".env.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $envPath $backupPath
    Write-Host "✓ Backed up existing .env to .env.backup" -ForegroundColor Green
}

# Create new .env file
$envContent = @"
# Server Configuration
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000

# Database Configuration
DB_HOST=$dbHost
DB_PORT=$dbPort
DB_NAME=$dbName
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
Write-Host "✓ .env file created successfully" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Database Connection" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test database connection
Write-Host "Testing connection to PostgreSQL..." -ForegroundColor Yellow

try {
    $env:PGPASSWORD = $dbPasswordPlain
    
    # Check if database exists
    $dbExists = psql -U $dbUser -h $dbHost -p $dbPort -lqt | Select-String -Pattern "^\s*$dbName\s*\|"
    
    if ($dbExists) {
        Write-Host "✓ Database '$dbName' exists" -ForegroundColor Green
    } else {
        Write-Host "⚠ Database '$dbName' does not exist" -ForegroundColor Yellow
        $createDb = Read-Host "Do you want to create it? (y/n)"
        
        if ($createDb -eq 'y' -or $createDb -eq 'Y') {
            psql -U $dbUser -h $dbHost -p $dbPort -c "CREATE DATABASE $dbName;"
            Write-Host "✓ Database created successfully" -ForegroundColor Green
        }
    }
    
    # Test connection
    $result = psql -U $dbUser -h $dbHost -p $dbPort -d $dbName -c "SELECT version();" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Database connection successful!" -ForegroundColor Green
    } else {
        Write-Host "✗ Database connection failed" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Error testing database connection: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration Summary:" -ForegroundColor Cyan
Write-Host "  Database: $dbName" -ForegroundColor White
Write-Host "  Host: $dbHost" -ForegroundColor White
Write-Host "  Port: $dbPort" -ForegroundColor White
Write-Host "  User: $dbUser" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Start backend: cd `"$backendPath`" && npm start" -ForegroundColor White
Write-Host "2. Check for any errors in the console" -ForegroundColor White
Write-Host "3. Start frontend: cd `"c:\Users\nadee\Documents\Database-Project`" && npm start" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
