# SkyNest Hotels - ERD Integration Summary

## ✅ Completed Changes

### 1. **Data Models Created** (`src/data/mockData.js`)

Created comprehensive data structures matching your PostgreSQL ERD schema:

#### **Enums Implemented:**
- `RoomStatus`: Available, Occupied, Maintenance
- `BookingStatus`: Booked, Checked_In, Checked_Out, Cancelled
- `PaymentMethod`: Cash, Card, Online, BankTransfer
- `UserRole`: Admin, Manager, Receptionist, Accountant, Customer
- `PreBookingMethod`: Online, Phone, Walk_in
- `AdjustmentType`: refund, chargeback, manual_adjustment

#### **Tables with Sample Data:**

**Branch Table (3 branches)**
```javascript
{
  branch_id: bigserial [pk]
  branch_name: varchar(100)
  contact_number: varchar(30)
  address: text
  manager_name: varchar(100)
}
```
- SkyNest Colombo
- SkyNest Kandy
- SkyNest Galle

**Room_Type Table (3 types)**
```javascript
{
  room_type_id: bigserial [pk]
  name: varchar(50) // Single/Double/Suite
  capacity: int
  daily_rate: numeric(10,2)
  amenities: text
}
```

**Room Table (10 rooms)**
```javascript
{
  room_id: bigserial [pk]
  branch_id: bigint [ref: > branch.branch_id]
  room_type_id: bigint [ref: > room_type.room_type_id]
  room_number: varchar(20)
  status: room_status
}
```

**Guest Table (4 guests)**
```javascript
{
  guest_id: bigserial [pk]
  nic: varchar(30)
  full_name: varchar(120)
  email: varchar(150)
  phone: varchar(30)
  gender: varchar(20)
  date_of_birth: date
  address: text
  nationality: varchar(80)
}
```

**Service_Catalog Table (7 services)**
```javascript
{
  service_id: bigserial [pk]
  code: varchar(30)
  name: varchar(100)
  category: varchar(60)
  unit_price: numeric(10,2)
  tax_rate_percent: numeric(5,2)
  active: boolean
}
```
Categories: Food & Beverage, Housekeeping, Wellness, Transportation, Facilities

**Booking Table (3 bookings)**
```javascript
{
  booking_id: bigserial [pk]
  pre_booking_id: bigint
  guest_id: bigint [ref: > guest.guest_id]
  room_id: bigint [ref: > room.room_id]
  check_in_date: date
  check_out_date: date
  status: booking_status
  booked_rate: numeric(10,2)
  tax_rate_percent: numeric(5,2)
  discount_amount: numeric(10,2)
  late_fee_amount: numeric(10,2)
  advance_payment: numeric(10,2)
  preferred_payment_method: payment_method
  created_at: timestamptz
}
```

**Service_Usage Table (4 usage records)**
```javascript
{
  service_usage_id: bigserial [pk]
  booking_id: bigint [ref: > booking.booking_id]
  service_id: bigint [ref: > service_catalog.service_id]
  used_on: date
  qty: int
  unit_price_at_use: numeric(10,2)
}
```

**Payment Table (3 payments)**
```javascript
{
  payment_id: bigserial [pk]
  booking_id: bigint [ref: > booking.booking_id]
  amount: numeric(10,2)
  method: payment_method
  paid_at: timestamptz
  payment_reference: varchar(100)
}
```

#### **Helper Functions Created:**
- `getBranchById()` - Get branch by ID
- `getRoomTypeById()` - Get room type by ID
- `getRoomById()` - Get room by ID
- `getGuestById()` - Get guest by ID
- `getServiceById()` - Get service by ID
- `getRoomsByBranch()` - Filter rooms by branch
- `getBookingsByGuest()` - Filter bookings by guest
- `getServiceUsageByBooking()` - Get services for a booking
- `getPaymentsByBooking()` - Get payments for a booking
- `calculateBookingTotal()` - Calculate complete booking totals including:
  - Room charges (rate × nights)
  - Room taxes
  - Service charges
  - Service taxes
  - Discounts
  - Late fees
  - Total paid
  - Outstanding balance

### 2. **Authentication System Updated**

**Updated User Roles** (matching ERD user_role enum):
- Admin (was Administrator)
- Manager (was Hotel Manager)
- Receptionist  
- **Accountant** (NEW ROLE)
- Customer

**Updated Demo Accounts:**
```javascript
1. Admin User
   - Email: admin@skynest.com
   - Password: admin123
   - Role: Admin
   - Branch: All Branches
   
2. Anura Perera
   - Email: manager.colombo@skynest.com
   - Password: manager123
   - Role: Manager
   - Branch: SkyNest Colombo
   
3. Shalini Fernando
   - Email: receptionist@skynest.com
   - Password: reception123
   - Role: Receptionist
   - Branch: SkyNest Kandy
   
4. Rajitha Silva (NEW)
   - Email: accountant@skynest.com
   - Password: accountant123
   - Role: Accountant
   - Branch: SkyNest Galle
```

**Updated User Fields** (matching user_account table):
- `user_id` (was `id`)
- `username` (new field)
- `role` (updated enum values)
- `branch_id` (new field)
- `branch_name` (was `hotel`)

### 3. **Component Updates**

**AuthContext.js:**
- ✅ Updated demo users with proper user_role enum values
- ✅ Added Accountant role
- ✅ Changed field names: `user_id`, `branch_id`, `branch_name`
- ✅ Ready for backend integration with user_account table

**Login.js:**
- ✅ Added Accountant to demo credentials
- ✅ Updated role display names

**Profile.js:**
- ✅ Updated role badge colors (added Accountant & Customer)
- ✅ Changed `hotel` field to `branch_name`
- ✅ Changed `id` field to `user_id`
- ✅ Updated all user field references

**Navbar.js:**
- ✅ Changed `user.hotel` to `user.branch_name`
- ✅ Added fallback for "All Branches"

**Settings.js:**
- ✅ Updated role references
- ✅ Uses `user.role` consistently

## 📊 Database Structure Summary

### **Tables Implemented:**
1. ✅ **branch** - 3 hotel locations
2. ✅ **room_type** - 3 room categories
3. ✅ **room** - 10 rooms across branches
4. ✅ **guest** - 4 sample guests
5. ✅ **service_catalog** - 7 services
6. ✅ **booking** - 3 active bookings
7. ✅ **service_usage** - 4 service records
8. ✅ **payment** - 3 payment records
9. ⏳ **user_account** - Demo data in AuthContext
10. ⏳ **employee** - Needs component
11. ⏳ **customer** - Needs component
12. ⏳ **pre_booking** - Needs implementation
13. ⏳ **payment_adjustment** - Needs implementation
14. ⏳ **invoice** - Needs implementation

### **Relationships Established:**
- Branch 1 —< Room (many rooms per branch)
- RoomType 1 —< Room (many rooms per type)
- Guest 1 —< Booking (many bookings per guest)
- Room 1 —< Booking (many bookings per room)
- Booking 1 —< ServiceUsage (many services per booking)
- ServiceCatalog 1 —< ServiceUsage
- Booking 1 —< Payment (instalments supported)

## 🔄 Next Steps

### **Priority 1: Update Components to Use New Data Structure**

1. **Hotels/Branches Component**
   - Update to use `branches` array from mockData
   - Display `branch_id`, `branch_name`, `contact_number`, `address`, `manager_name`
   - Show branch statistics using helper functions

2. **Rooms Component**
   - Use `rooms` and `roomTypes` arrays
   - Filter by `branch_id`
   - Display `room_status` enum values
   - Show room type details (capacity, daily_rate, amenities)

3. **Guests Component**
   - Use `guests` array
   - Display all guest fields including NIC, nationality, DOB
   - Show booking history per guest
   - Gender and address information

4. **Bookings Component**
   - Use `bookings` array
   - Implement `booking_status` enum
   - Show `pre_booking_id` link
   - Display calculated totals using `calculateBookingTotal()`
   - Show advance_payment, discount_amount, late_fee_amount

5. **Services Component**
   - Use `serviceCatalog` array
   - Display service code, category, unit_price
   - Show tax_rate_percent
   - Active/inactive toggle
   - Link to service_usage

6. **Billing Component**
   - Use `payments` and `bookings` arrays
   - Show instalment support
   - Display payment_reference
   - Calculate outstanding using helper functions
   - Support for payment_adjustment (refunds)

### **Priority 2: Add Missing Components**

1. **Pre-Booking Component**
   - Implement pre_booking table
   - Support prebooking_method enum
   - Room assignment optional initially
   - Convert to confirmed booking

2. **Employee Management**
   - Link to user_account
   - Display branch assignment
   - Contact information

3. **Payment Adjustments**
   - Refunds, chargebacks, manual adjustments
   - Link to bookings
   - Reference notes

4. **Invoice Generation**
   - Create invoices from bookings
   - Include service usage
   - Show payment history

### **Priority 3: Backend Integration**

Once components are updated:
1. Create API endpoints matching ERD structure
2. Implement PostgreSQL database
3. Add validation and constraints
4. Implement daterange exclusion for booking overlaps
5. Add proper authentication with password hashing

## 📝 File Structure

```
src/
├── data/
│   └── mockData.js              ← NEW: All ERD data structures
├── context/
│   └── AuthContext.js           ← UPDATED: Uses user_role enum
├── components/
│   ├── ProtectedRoute.js
│   └── Layout/
│       └── Navbar.js            ← UPDATED: Uses branch_name
├── pages/
│   ├── Login.js                 ← UPDATED: Added Accountant role
│   ├── Profile.js               ← UPDATED: All field names
│   ├── Settings.js              ← Ready for ERD integration
│   ├── Hotels.js                ← NEEDS UPDATE: Use branches array
│   ├── Rooms.js                 ← NEEDS UPDATE: Use rooms/roomTypes
│   ├── Guests.js                ← NEEDS UPDATE: Use guests array
│   ├── Bookings.js              ← NEEDS UPDATE: Use bookings array
│   ├── Services.js              ← NEEDS UPDATE: Use serviceCatalog
│   ├── Billing.js               ← NEEDS UPDATE: Use payments array
│   └── Reports.js               ← NEEDS UPDATE: Use all tables
└── App.js

```

## ✅ Benefits of ERD Integration

1. **Data Consistency**: All components use standardized data structures
2. **Proper Relationships**: Foreign keys and relationships match database design
3. **Enum Validation**: Using proper enum values prevents invalid states
4. **Calculation Functions**: Helper functions ensure consistent calculations
5. **Backend Ready**: Data structure matches PostgreSQL schema exactly
6. **Type Safety**: Clear field names and types
7. **Scalability**: Easy to extend with new tables and relationships

## 🎯 Current Status

✅ **Phase 1 Complete:**
- ERD data models created
- Authentication system updated
- User roles aligned with ERD
- Profile and navigation updated
- No compilation errors

⏳ **Phase 2 In Progress:**
- Need to update individual page components
- Need to implement remaining tables
- Need to add employee and pre-booking components

🔄 **Next Immediate Steps:**
1. Update Hotels.js to use `branches` array
2. Update Rooms.js to use `rooms` and `roomTypes` arrays
3. Update Guests.js to use `guests` array with all fields
4. Update Bookings.js to use `bookings` array with calculations
5. Update Services.js to use `serviceCatalog` and `serviceUsage`
6. Update Billing.js to use `payments` array with instalment support

---

**All changes are backward compatible and the application compiles without errors!**

The foundation is now set for full ERD integration. Each component can be updated incrementally while the system remains functional.
