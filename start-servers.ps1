# Hotel Management System - Quick Start Script
# This script helps you start both backend and frontend servers

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Hotel Management System Launcher" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Node.js is installed
Write-Host "Checking Node.js installation..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js version: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js is not installed!" -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Select an option:" -ForegroundColor Cyan
Write-Host "1. Start Backend Only (Port 5000)" -ForegroundColor White
Write-Host "2. Start Frontend Only (Port 3000)" -ForegroundColor White
Write-Host "3. Start Both Backend and Frontend" -ForegroundColor White
Write-Host "4. Install Dependencies (Backend + Frontend)" -ForegroundColor White
Write-Host "5. Exit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice (1-5)"

$backendPath = "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"
$frontendPath = "c:\Users\nadee\Documents\Database-Project"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "Starting Backend Server..." -ForegroundColor Yellow
        Write-Host "Backend will run on http://localhost:5000" -ForegroundColor Cyan
        Write-Host ""
        Set-Location $backendPath
        npm start
    }
    "2" {
        Write-Host ""
        Write-Host "Starting Frontend Server..." -ForegroundColor Yellow
        Write-Host "Frontend will run on http://localhost:3000" -ForegroundColor Cyan
        Write-Host ""
        Set-Location $frontendPath
        npm start
    }
    "3" {
        Write-Host ""
        Write-Host "Starting Both Servers..." -ForegroundColor Yellow
        Write-Host "Backend: http://localhost:5000" -ForegroundColor Cyan
        Write-Host "Frontend: http://localhost:3000" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Opening Backend in new window..." -ForegroundColor Green
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; Write-Host 'Backend Server Starting...' -ForegroundColor Green; npm start"
        
        Start-Sleep -Seconds 3
        
        Write-Host "Opening Frontend in new window..." -ForegroundColor Green
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$frontendPath'; Write-Host 'Frontend Server Starting...' -ForegroundColor Green; npm start"
        
        Write-Host ""
        Write-Host "✓ Both servers are starting in separate windows!" -ForegroundColor Green
        Write-Host "Press any key to close this launcher..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    "4" {
        Write-Host ""
        Write-Host "Installing Dependencies..." -ForegroundColor Yellow
        Write-Host ""
        
        Write-Host "Installing Backend Dependencies..." -ForegroundColor Cyan
        Set-Location $backendPath
        npm install
        
        Write-Host ""
        Write-Host "Installing Frontend Dependencies..." -ForegroundColor Cyan
        Set-Location $frontendPath
        npm install
        
        Write-Host ""
        Write-Host "✓ All dependencies installed!" -ForegroundColor Green
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    "5" {
        Write-Host "Exiting..." -ForegroundColor Yellow
        exit
    }
    default {
        Write-Host "Invalid choice. Exiting..." -ForegroundColor Red
        exit
    }
}
