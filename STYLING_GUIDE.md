# 🎨 SkyNest Hotels - Styling & Color Customization Guide

## ⚡ CURRENT THEME: Sapphire Stream Whisper

### Active Color Palette:
- **#48547C** - Sapphire Dark (Navy) - Sidebar/Navbar gradient start
- **#AAA59F** - Sapphire Gray (Warm Gray) - Borders, secondary elements
- **#CFE7F8** - Sapphire Light (Sky Blue) - Page background
- **#33343B** - Sapphire Charcoal (Very Dark) - Shadows
- **#749DD0** - Sapphire Medium (Ocean Blue) - Primary color
- **#92AAD1** - Sapphire Soft (Powder Blue) - Accent color

> **Note**: This palette has been applied throughout your entire website!  
> See `SAPPHIRE_STREAM_WHISPER_THEME.md` for complete details.

---

## Overview
This guide shows you exactly where to change background colors, gradients, and decorations in your SkyNest Hotels application.

---

## 📍 Main Color Scheme Locations

### Current Primary Colors:
- **Purple Gradient**: `#667eea` (light purple) to `#764ba2` (dark purple)
- **Background**: `#f8f9fa` (light gray)
- **Accent**: Bootstrap blue, success, danger, etc.

---

## 1️⃣ **Main CSS Files**

### 📄 **src/index.css** (Global Styles)

```css
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background-color: #f8f9fa;  /* ⬅️ CHANGE: Main page background */
}

/* SIDEBAR - Purple Gradient Background */
.sidebar {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);  /* ⬅️ CHANGE: Sidebar gradient */
  color: white;  /* ⬅️ CHANGE: Sidebar text color */
  min-height: 100vh;
  padding: 20px;
  box-shadow: 2px 0 10px rgba(0,0,0,0.1);  /* ⬅️ CHANGE: Shadow color/size */
}

/* NAVBAR - Purple Gradient Background */
.navbar-custom {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);  /* ⬅️ CHANGE: Navbar gradient */
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);  /* ⬅️ CHANGE: Shadow */
}

/* CARDS - Hover Effect */
.card-custom {
  border: none;
  border-radius: 10px;  /* ⬅️ CHANGE: Card corner roundness */
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);  /* ⬅️ CHANGE: Card shadow */
  transition: transform 0.3s ease;  /* ⬅️ CHANGE: Animation speed */
}

.card-custom:hover {
  transform: translateY(-5px);  /* ⬅️ CHANGE: Hover lift amount */
}

/* PRIMARY BUTTON - Purple Gradient */
.btn-primary-custom {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);  /* ⬅️ CHANGE: Button gradient */
  border: none;
  border-radius: 25px;  /* ⬅️ CHANGE: Button roundness */
  padding: 10px 30px;
  transition: all 0.3s ease;
}

.btn-primary-custom:hover {
  transform: translateY(-2px);  /* ⬅️ CHANGE: Button lift on hover */
  box-shadow: 0 5px 15px rgba(0,0,0,0.2);  /* ⬅️ CHANGE: Button shadow */
}

/* TABLE CONTAINER */
.table-container {
  background: white;  /* ⬅️ CHANGE: Table background */
  border-radius: 10px;  /* ⬅️ CHANGE: Corner roundness */
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);  /* ⬅️ CHANGE: Shadow */
  overflow: hidden;
}

/* SEARCH BOX */
.search-box {
  border-radius: 25px;  /* ⬅️ CHANGE: Input roundness */
  border: 2px solid #e9ecef;  /* ⬅️ CHANGE: Border color */
  padding: 10px 20px;
  transition: border-color 0.3s ease;
}

.search-box:focus {
  border-color: #667eea;  /* ⬅️ CHANGE: Focus border color */
  box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);  /* ⬅️ CHANGE: Focus glow */
}
```

---

### 📄 **src/App.css** (Component-Specific Styles)

```css
.App {
  text-align: center;
}

/* SIDEBAR STYLES */
.sidebar {
  width: 250px;  /* ⬅️ CHANGE: Sidebar width */
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);  /* ⬅️ CHANGE: Gradient */
  color: white;  /* ⬅️ CHANGE: Text color */
  min-height: calc(100vh - 56px);
  padding: 20px;
  box-shadow: 2px 0 10px rgba(0,0,0,0.1);  /* ⬅️ CHANGE: Shadow */
}

/* MAIN CONTENT AREA */
.content-wrapper {
  padding: 20px;
  background-color: #f8f9fa;  /* ⬅️ CHANGE: Content background */
  min-height: calc(100vh - 56px);
}

/* NAVBAR BRAND */
.navbar-brand {
  font-weight: bold;
  font-size: 1.5rem;  /* ⬅️ CHANGE: Logo text size */
}

/* SIDEBAR NAVIGATION LINKS */
.nav-link-sidebar {
  color: white !important;  /* ⬅️ CHANGE: Link text color */
  padding: 12px 15px;
  margin: 5px 0;
  border-radius: 8px;  /* ⬅️ CHANGE: Link corner roundness */
  text-decoration: none;
  display: flex;
  align-items: center;
  transition: all 0.3s ease;  /* ⬅️ CHANGE: Animation speed */
}

.nav-link-sidebar:hover {
  background-color: rgba(255, 255, 255, 0.1);  /* ⬅️ CHANGE: Hover background */
  transform: translateX(5px);  /* ⬅️ CHANGE: Hover slide distance */
}

.nav-link-sidebar.active {
  background-color: rgba(255, 255, 255, 0.2);  /* ⬅️ CHANGE: Active link background */
}

.nav-link-sidebar i {
  margin-right: 10px;
  width: 20px;
}
```

---

## 2️⃣ **Login Page Inline Styles**

### 📄 **src/pages/Login.js**

The Login page has inline styles that need to be changed directly in the component:

**Lines to modify:**

```javascript
// Line 40 - Main page background gradient
<div className="login-page" style={{ 
  minHeight: '100vh', 
  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',  // ⬅️ CHANGE: Page gradient
  display: 'flex',
  alignItems: 'center',
  padding: '20px'
}}>

// Line 52-54 - Left branding panel
<Col md={6} className="d-none d-md-block" style={{
  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',  // ⬅️ CHANGE: Panel gradient
  color: 'white',  // ⬅️ CHANGE: Text color
  padding: '40px'
}}>

// Line 79 - Mobile icon color
<FaHotel size={50} style={{ color: '#667eea' }} />  // ⬅️ CHANGE: Icon color

// Line 129-131 - Sign-in button
<Button 
  variant="primary" 
  type="submit" 
  size="lg"
  disabled={loading}
  style={{
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',  // ⬅️ CHANGE: Button gradient
    border: 'none'
  }}
>
```

---

## 3️⃣ **Profile Page Styles**

### 📄 **src/pages/Profile.js**

Profile page has an inline style for the avatar circle:

```javascript
// Line 86-88 - Avatar circle background
<div 
  className="rounded-circle bg-primary text-white d-inline-flex align-items-center justify-content-center"
  style={{ width: '120px', height: '120px', fontSize: '48px' }}  // ⬅️ CHANGE: Avatar size
>
```

---

## 🎨 **Quick Color Change Examples**

### Example 1: Change to Blue Theme
Replace all instances of:
- `#667eea` → `#1e90ff` (dodger blue)
- `#764ba2` → `#0066cc` (darker blue)

### Example 2: Change to Green Theme
Replace all instances of:
- `#667eea` → `#00c853` (green)
- `#764ba2` → `#00875a` (dark green)

### Example 3: Change to Orange Theme
Replace all instances of:
- `#667eea` → `#ff6b35` (orange)
- `#764ba2` → `#d63031` (red-orange)

### Example 4: Change to Teal Theme
Replace all instances of:
- `#667eea` → `#26c6da` (cyan)
- `#764ba2` → `#00897b` (teal)

---

## 🔧 **Advanced Customization**

### Shadows & Effects

**Soft Shadow:**
```css
box-shadow: 0 2px 8px rgba(0,0,0,0.05);
```

**Medium Shadow:**
```css
box-shadow: 0 4px 15px rgba(0,0,0,0.1);
```

**Strong Shadow:**
```css
box-shadow: 0 8px 30px rgba(0,0,0,0.2);
```

**Colored Shadow (for your gradient):**
```css
box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);  /* Purple glow */
```

### Border Radius

**Sharp Corners:**
```css
border-radius: 0px;
```

**Slightly Rounded:**
```css
border-radius: 5px;
```

**Medium Rounded (current):**
```css
border-radius: 10px;
```

**Very Rounded:**
```css
border-radius: 20px;
```

**Pill Shape (buttons):**
```css
border-radius: 50px;
```

### Hover Animations

**Lift Effect:**
```css
.card:hover {
  transform: translateY(-5px);  /* Move up 5px */
}
```

**Grow Effect:**
```css
.card:hover {
  transform: scale(1.05);  /* Grow 5% */
}
```

**Rotate Effect:**
```css
.card:hover {
  transform: rotate(2deg);  /* Rotate 2 degrees */
}
```

---

## 📝 **Bootstrap Color Overrides**

If you want to change Bootstrap's default colors, create a custom CSS file or add to `index.css`:

```css
/* Override Bootstrap Primary Color */
.btn-primary {
  background-color: #667eea !important;
  border-color: #667eea !important;
}

.btn-primary:hover {
  background-color: #764ba2 !important;
  border-color: #764ba2 !important;
}

/* Override Badge Colors */
.badge.bg-primary {
  background-color: #667eea !important;
}

/* Override Form Focus Color */
.form-control:focus {
  border-color: #667eea;
  box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);
}
```

---

## 🌈 **Gradient Generator Tool**

Use this website to create custom gradients:
- **CSS Gradient**: https://cssgradient.io/
- **uiGradients**: https://uigradients.com/
- **Gradient Hunt**: https://gradienthunt.com/

---

## 📍 **Quick Reference: Where Each Color Is Used**

| Component | File | Line(s) | What It Colors |
|-----------|------|---------|----------------|
| Sidebar | `index.css` | 28 | Sidebar background gradient |
| Sidebar | `App.css` | 7 | Sidebar background gradient |
| Navbar | `index.css` | 36 | Top navbar gradient |
| Login Page | `Login.js` | 40, 52, 129 | Page & button gradients |
| Buttons | `index.css` | 54 | Primary button gradient |
| Cards | `index.css` | 45 | Card shadows |
| Content Area | `App.css` | 14 | Main content background |
| Links (sidebar) | `App.css` | 26 | Navigation link styles |

---

## 💡 **Tips**

1. **Use Find & Replace**: Search for `#667eea` and `#764ba2` across all files to change the theme quickly
2. **Test Changes**: Modify one file at a time to see the effect
3. **Keep Contrast**: Ensure text is readable on your chosen background colors
4. **Consistent Theme**: Use the same colors throughout for a cohesive look
5. **Dark Mode**: Consider adding a dark theme option in Settings

---

## ✅ **Files to Modify Summary**

1. ✏️ **src/index.css** - Global styles (sidebar, navbar, cards, buttons)
2. ✏️ **src/App.css** - Component styles (sidebar, content, nav links)
3. ✏️ **src/pages/Login.js** - Login page inline styles (lines 40, 52, 79, 129)
4. ✏️ **src/pages/Profile.js** - Avatar size (line 86-88)

---

**Happy Customizing! 🎨**
