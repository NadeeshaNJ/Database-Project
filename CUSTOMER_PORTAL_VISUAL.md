# 🎨 Customer Portal - Visual Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          LOGIN PAGE                                  │
│                    http://localhost:3000/login                       │
│                                                                      │
│    Username: [__________]                                           │
│    Password: [__________]                                           │
│                 [Login Button]                                       │
│                                                                      │
│  Demo Accounts:                                                     │
│  • admin / password123                                              │
│  • manager_colombo / password123                                    │
│  • recept_colombo / password123                                     │
│  • accountant_colombo / password123                                 │
│  • nuwan.peiris7 / password123 (Customer)                          │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 │ Login Success
                                 ▼
                    ┌────────────────────────┐
                    │   Check User Role      │
                    └────────────────────────┘
                                 │
                ┌────────────────┴────────────────┐
                │                                 │
                ▼                                 ▼
┌───────────────────────────┐       ┌────────────────────────────┐
│      CUSTOMER ROLE        │       │   ADMIN/STAFF ROLES        │
│      (Customer)           │       │ (Admin, Manager, etc.)     │
└───────────────────────────┘       └────────────────────────────┘
                │                                 │
                ▼                                 ▼
┌───────────────────────────────────────────────────────────────────┐
│                    CUSTOMER PORTAL                                 │
│                 /customer (CustomerRoute)                          │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  ┌─────────────────────────────────────────────────────┐   │ │
│  │  │         CustomerNavbar                              │   │ │
│  │  │  SkyNest Hotels              [User ▼] [Logout]    │   │ │
│  │  └─────────────────────────────────────────────────────┘   │ │
│  │                                                             │ │
│  │  ╔═══════════════════════════════════════════════════════╗ │ │
│  │  ║  Welcome to SkyNest Hotels, Nuwan!                   ║ │ │
│  │  ║  Book your perfect stay with us                      ║ │ │
│  │  ╚═══════════════════════════════════════════════════════╝ │ │
│  │                                                             │ │
│  │  ┌───────────────────────────────────────────────────┐   │ │
│  │  │         📅 Book Your Stay                         │   │ │
│  │  │                                                    │   │ │
│  │  │  Branch: [▼ Choose location...]                   │   │ │
│  │  │  Room Type: [▼ Choose room type...]               │   │ │
│  │  │  Check-in: [📅 2025-10-25]                        │   │ │
│  │  │  Check-out: [📅 2025-10-28]                       │   │ │
│  │  │  Adults: [2 ▲▼]  Children: [1 ▲▼]                │   │ │
│  │  │  Special Requests: [________________]              │   │ │
│  │  │                                                    │   │ │
│  │  │         [Submit Pre-Booking Request]               │   │ │
│  │  └───────────────────────────────────────────────────┘   │ │
│  │                                                             │ │
│  │  ✅ Easy Booking   🛏️ Luxury Rooms   📍 Prime Locations  │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  ❌ CANNOT ACCESS:                                                │
│     • Dashboard                                                   │
│     • Bookings                                                    │
│     • Rooms                                                       │
│     • All admin features                                         │
└───────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────┐
│                    ADMIN DASHBOARD                                 │
│                    / (AdminRoute)                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  ┌─────────────────────────────────────────────────────┐   │ │
│  │  │         Navbar                                      │   │ │
│  │  │  SkyNest  [Branch▼]  [Admin▼] [Logout]            │   │ │
│  │  └─────────────────────────────────────────────────────┘   │ │
│  │  ┌────────┐ ┌──────────────────────────────────────────┐  │ │
│  │  │ Side   │ │  📊 Dashboard                            │  │ │
│  │  │ bar    │ │  ┌────┐ ┌────┐ ┌────┐ ┌────┐           │  │ │
│  │  │        │ │  │ 45 │ │ 12 │ │ 23 │ │ 89 │           │  │ │
│  │  │ 📊 Dash│ │  │Gst │ │In  │ │Rm  │ │Out │           │  │ │
│  │  │ 📅 Book│ │  └────┘ └────┘ └────┘ └────┘           │  │ │
│  │  │ 👥 Gst │ │                                          │  │ │
│  │  │ 🏠 Rm  │ │  Quick Actions:                          │  │ │
│  │  │ 🏨 Hot │ │  [Add Guest] [New Reservation]           │  │ │
│  │  │ 💼 Serv│ │  [Room Status] [Service Request]         │  │ │
│  │  │ 💳 Bill│ │                                          │  │ │
│  │  │ 📈 Rpt │ │  Recent Bookings:                        │  │ │
│  │  │ ⚙️ Set │ │  [Table with all booking data...]        │  │ │
│  │  └────────┘ └──────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  ✅ FULL ACCESS:                                                  │
│     • Dashboard with statistics                                   │
│     • All bookings management                                     │
│     • Room management                                             │
│     • Guest management (role-based)                              │
│     • Billing & Reports (role-based)                             │
│     • All admin features                                          │
│                                                                    │
│  ❌ CANNOT ACCESS:                                                │
│     • Customer Portal                                             │
└───────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Route Protection Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  URL Navigation Attempt                          │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              Is User Authenticated?                              │
└─────────────────────────────────────────────────────────────────┘
                │                              │
                │ NO                           │ YES
                ▼                              ▼
         ┌──────────┐              ┌──────────────────────┐
         │ Redirect │              │   Check Route Type   │
         │ to Login │              └──────────────────────┘
         └──────────┘                         │
                                              │
                        ┌─────────────────────┴─────────────────────┐
                        │                                           │
                        ▼                                           ▼
            ┌────────────────────────┐              ┌────────────────────────┐
            │  Accessing /customer/* │              │  Accessing /dashboard  │
            │   (CustomerRoute)      │              │     (AdminRoute)       │
            └────────────────────────┘              └────────────────────────┘
                        │                                           │
                        ▼                                           ▼
            ┌────────────────────────┐              ┌────────────────────────┐
            │  Is Role = Customer?   │              │  Is Role = Customer?   │
            └────────────────────────┘              └────────────────────────┘
                │              │                         │              │
                │ YES          │ NO                      │ YES          │ NO
                ▼              ▼                         ▼              ▼
            ┌──────┐    ┌──────────┐              ┌──────────┐    ┌──────┐
            │ ALLOW│    │ Redirect │              │ Redirect │    │ ALLOW│
            │ ACCESS│   │ to /dash │              │ to /cust │    │ ACCESS│
            └──────┘    └──────────┘              └──────────┘    └──────┘
```

---

## 📊 User Role Comparison

```
╔════════════════════════════════════════════════════════════════════╗
║                         FEATURE ACCESS MATRIX                       ║
╠════════════════════════╦═══════════╦═══════════╦═══════════════════╣
║ Feature                ║ Customer  ║ Staff     ║ Admin             ║
╠════════════════════════╬═══════════╬═══════════╬═══════════════════╣
║ Login                  ║     ✅    ║     ✅    ║       ✅          ║
║ Customer Portal        ║     ✅    ║     ❌    ║       ❌          ║
║ Pre-Booking Request    ║     ✅    ║     ❌    ║       ❌          ║
║ Dashboard              ║     ❌    ║     ✅    ║       ✅          ║
║ View All Bookings      ║     ❌    ║     ✅    ║       ✅          ║
║ Manage Rooms           ║     ❌    ║     ✅    ║       ✅          ║
║ Add Guests             ║     ❌    ║     ✅    ║       ✅          ║
║ View Billing           ║     ❌    ║  Role-dep ║       ✅          ║
║ Generate Reports       ║     ❌    ║  Role-dep ║       ✅          ║
║ System Settings        ║     ❌    ║     ❌    ║       ✅          ║
╚════════════════════════╩═══════════╩═══════════╩═══════════════════╝
```

---

## 🎨 Color Scheme

### Customer Portal
```
┌─────────────────────────────────────────┐
│  Primary Gradient                       │
│  #667eea (Blue-Purple) → #764ba2 (Prpl)│
│  ████████████████████████████████████  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Background                             │
│  White cards on gradient background     │
│  ██████████  ←  Card                   │
│              ←  Gradient BG            │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Buttons                                │
│  Gradient with shadow, rounded          │
│  [  Submit Pre-Booking Request  ]      │
└─────────────────────────────────────────┘
```

### Admin Dashboard
```
┌─────────────────────────────────────────┐
│  Primary Colors                         │
│  #48547C (Dark Blue) → #749DD0 (Blue)  │
│  ████████████████████████████████████  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Sidebar                                │
│  Dark background (#2c3e50)              │
│  █████  ← Sidebar                      │
│         ← White content area           │
└─────────────────────────────────────────┘
```

---

## 🔗 API Flow

```
Customer Portal                Backend                   Database
─────────────────────────────────────────────────────────────────

[Submit Form]
     │
     │ POST /api/bookings/pre-booking
     ├──────────────────────►  Validate JWT Token
     │                               │
     │                               ▼
     │                         Check Role (Customer?)
     │                               │
     │                               ▼
     │                         Validate Form Data
     │                               │
     │                               ▼
     │                         INSERT INTO
     │                         pre_booking ───────► [pre_booking]
     │                               │                table
     │                               ▼                  │
     │                         Return pre_booking_id    │
     │◄────────────────────────      │                  │
     │                                                   │
     ▼                                                   │
[Show Success]                                          │
                                                        ▼
                                              Status: 'Pending'
                                              Awaiting staff review
```

---

## 📱 Responsive Design

```
Desktop (> 768px)               Mobile (< 768px)
─────────────────               ────────────────

┌─────────────────┐            ┌──────────┐
│  [Logo]   [User]│            │  [Logo]  │
└─────────────────┘            │    ☰     │
┌─────────────────┐            └──────────┘
│                 │            ┌──────────┐
│  Welcome Text   │            │ Welcome  │
│                 │            └──────────┘
└─────────────────┘            ┌──────────┐
┌─────────────────┐            │  Form    │
│  Branch | Room  │            │  Fields  │
│  Date   | Date  │            │  (Stack) │
│  Form Fields... │            │          │
│  [Submit Btn]   │            │ [Submit] │
└─────────────────┘            └──────────┘
```

---

**Visual Guide Complete!** 🎨
