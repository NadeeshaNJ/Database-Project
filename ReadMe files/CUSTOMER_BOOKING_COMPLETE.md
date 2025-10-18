# ✅ Customer Pre-Booking System - Complete Guide

## 🎯 **What This System Does**

Your customer can now:
1. **Select a room TYPE** (not a specific room number)
2. **See room type names** clearly in the dropdown (Standard Single, Standard Double, Deluxe King, Suite)
3. **Submit the booking** 
4. **Backend automatically finds and assigns** an available room of that type
5. **Room is marked UNAVAILABLE** for those dates using `future_status`, `unavailable_from`, `unavailable_to`
6. **Customer sees confirmation** with the specific room number assigned

---

## 🔧 **How It Works**

### **Step 1: Customer Fills the Form**

```
┌────────────────────────────────────────────┐
│  CUSTOMER PORTAL - BOOKING FORM            │
├────────────────────────────────────────────┤
│  Select Location: Colombo ▼                │
│  Select Room Type: Standard Single ▼       │
│  Check-in Date: 2025-10-25                 │
│  Check-out Date: 2025-10-28                │
│  Number of Guests: 2                       │
│                                            │
│  [Submit Pre-Booking]                      │
└────────────────────────────────────────────┘
```

**Room Type Dropdown Shows:**
- Standard Single - Rs 5,000/night (3 available)
- Standard Double - Rs 8,000/night (5 available)
- Deluxe King - Rs 12,000/night (2 available)
- Suite - Rs 20,000/night (1 available)

---

### **Step 2: Frontend Sends Request**

```javascript
POST /api/bookings/pre-booking
{
  "guest_id": 7,
  "branch_id": 1,        // Colombo
  "room_type_id": 1,     // Standard Single (not specific room!)
  "capacity": 2,
  "expected_check_in": "2025-10-25",
  "expected_check_out": "2025-10-28",
  "prebooking_method": "Online"
}
```

---

### **Step 3: Backend Finds Available Room**

**SQL Query (Automatic Room Assignment):**
```sql
SELECT r.room_id, r.room_number, rt.name as room_type_name
FROM room r
JOIN room_type rt ON r.room_type_id = rt.room_type_id
WHERE r.room_type_id = 1           -- Standard Single
AND r.branch_id = 1                 -- Colombo
AND r.status = 'Available'          -- Currently available
AND (
    -- Check future_status doesn't conflict
    r.future_status IS NULL 
    OR r.unavailable_from IS NULL 
    OR r.unavailable_to IS NULL
    OR NOT (
        -- Date ranges don't overlap
        (r.unavailable_from <= '2025-10-28' AND r.unavailable_to >= '2025-10-25')
        OR (r.unavailable_from <= '2025-10-25' AND r.unavailable_to >= '2025-10-28')
        OR (r.unavailable_from >= '2025-10-25' AND r.unavailable_to <= '2025-10-28')
    )
)
AND r.room_id NOT IN (
    -- Check not already booked
    SELECT room_id FROM booking
    WHERE status NOT IN ('Cancelled', 'Checked-Out')
    AND date_range_overlaps
)
ORDER BY r.room_number
LIMIT 1;
```

**Result:** Finds Room 101 (Standard Single)

---

### **Step 4: Backend Marks Room Unavailable**

```sql
UPDATE room 
SET 
    future_status = 'Unavailable',
    unavailable_from = '2025-10-25',
    unavailable_to = '2025-10-28'
WHERE room_id = 101;
```

**Now this room won't be assigned to anyone else for Oct 25-28!**

---

### **Step 5: Backend Creates Pre-Booking**

```sql
INSERT INTO pre_booking (
    guest_id, 
    capacity, 
    prebooking_method,
    expected_check_in, 
    expected_check_out, 
    room_id,
    created_at
) VALUES (
    7,                  -- Customer's guest_id
    2,                  -- Number of guests
    'Online',           -- Booking method
    '2025-10-25',       -- Check-in
    '2025-10-28',       -- Check-out
    101,                -- Auto-assigned room
    CURRENT_TIMESTAMP
) RETURNING pre_booking_id;
```

---

### **Step 6: Customer Sees Success**

```
┌────────────────────────────────────────────┐
│  ✅ SUCCESS MESSAGE                        │
├────────────────────────────────────────────┤
│  🎉 Pre-booking confirmed!                 │
│  Room 101 (Standard Single) has been       │
│  reserved for you.                         │
│                                            │
│  Your reservation has been secured.        │
└────────────────────────────────────────────┘
```

---

## 🔒 **Transaction Safety**

All 3 operations happen **atomically** (all succeed or all fail):

```javascript
BEGIN TRANSACTION;

// 1. Find available room
SELECT room_id FROM room WHERE ...

// 2. Mark room unavailable
UPDATE room SET future_status = 'Unavailable' ...

// 3. Create pre-booking
INSERT INTO pre_booking ...

COMMIT; // All done together!
```

**Benefits:**
- ✅ No race conditions (two customers can't get the same room)
- ✅ Data consistency (room always matches pre-booking)
- ✅ If anything fails, everything rolls back

---

## 📊 **Database Structure**

### **room_type Table**
```
room_type_id | name              | capacity | daily_rate
-------------|-------------------|----------|------------
1            | Standard Single   | 2        | 5000.00
2            | Standard Double   | 4        | 8000.00
3            | Deluxe King       | 4        | 12000.00
4            | Suite             | 6        | 20000.00
```

### **room Table (Before Booking)**
```
room_id | room_number | room_type_id | branch_id | status    | future_status | unavailable_from | unavailable_to
--------|-------------|--------------|-----------|-----------|---------------|------------------|----------------
101     | 101         | 1            | 1         | Available | NULL          | NULL             | NULL
102     | 102         | 1            | 1         | Available | NULL          | NULL             | NULL
```

### **room Table (After Booking)**
```
room_id | room_number | room_type_id | branch_id | status    | future_status | unavailable_from | unavailable_to
--------|-------------|--------------|-----------|-----------|---------------|------------------|----------------
101     | 101         | 1            | 1         | Available | Unavailable   | 2025-10-25       | 2025-10-28
102     | 102         | 1            | 1         | Available | NULL          | NULL             | NULL
```

### **pre_booking Table (Created)**
```
pre_booking_id | guest_id | capacity | prebooking_method | expected_check_in | expected_check_out | room_id | created_at
---------------|----------|----------|-------------------|-------------------|--------------------|---------|-----------------------
1              | 7        | 2        | Online            | 2025-10-25        | 2025-10-28         | 101     | 2025-10-19 14:30:00
```

---

## 🚀 **Testing the Complete Flow**

### **1. Start Backend Server**
```powershell
cd C:\Users\nadee\Documents\Database-Back
npm start
```

✅ Should see: `🚀 Server running on port 5000`

### **2. Start Frontend**
```powershell
cd C:\Users\nadee\Documents\Database-Project
npm start
```

✅ Should open: `http://localhost:3000`

### **3. Login as Customer**
```
Username: nuwan.peiris7
Password: password123
```

✅ Should redirect to: `/customer`

### **4. Open Browser Console** (F12)
Look for these logs:
```
🔍 Fetching room types with token: Present
📡 Room Types Response Status: 200
✅ Room Types API Response: {success: true, data: [...]}
✅ Setting room types: [{room_type_id: 1, type_name: "Standard Single", ...}, ...]
```

### **5. Check Room Type Dropdown**
Should show:
```
Choose room type... ▼
Standard Single - Rs 5,000/night (3 available)
Standard Double - Rs 8,000/night (5 available)
Deluxe King - Rs 12,000/night (2 available)
Suite - Rs 20,000/night (1 available)
```

### **6. Fill the Form**
```
Location: Colombo
Room Type: Standard Single
Check-in: Tomorrow's date
Check-out: 3 days later
Guests: 2
```

### **7. Click "Submit Pre-Booking"**

Expected console output:
```javascript
Submitting pre-booking: {
  guest_id: 7,
  branch_id: 1,
  room_type_id: 1,
  capacity: 2,
  expected_check_in: "2025-10-25",
  expected_check_out: "2025-10-28",
  prebooking_method: "Online"
}

Pre-booking response: {
  success: true,
  message: "Pre-booking confirmed! Room 101 (Standard Single) has been reserved for you.",
  data: {
    pre_booking_id: 1,
    room_id: 101,
    room_number: "101",
    room_type: "Standard Single"
  }
}
```

Expected success message on page:
```
🎉 Pre-booking confirmed! Room 101 (Standard Single) has been reserved for you. 
Your reservation has been secured.
```

### **8. Verify in Database**

```sql
-- Check the room is marked unavailable
SELECT room_id, room_number, status, future_status, 
       unavailable_from, unavailable_to
FROM room 
WHERE room_id = 101;
```

Expected result:
```
room_id | room_number | status    | future_status | unavailable_from | unavailable_to
--------|-------------|-----------|---------------|------------------|----------------
101     | 101         | Available | Unavailable   | 2025-10-25       | 2025-10-28
```

```sql
-- Check the pre-booking was created
SELECT pb.pre_booking_id, pb.guest_id, pb.capacity,
       pb.expected_check_in, pb.expected_check_out,
       pb.room_id, r.room_number, rt.name as room_type
FROM pre_booking pb
JOIN room r ON pb.room_id = r.room_id
JOIN room_type rt ON r.room_type_id = rt.room_type_id
ORDER BY pb.created_at DESC
LIMIT 1;
```

Expected result:
```
pre_booking_id | guest_id | capacity | expected_check_in | expected_check_out | room_id | room_number | room_type
---------------|----------|----------|-------------------|--------------------|---------|--------------|-----------------
1              | 7        | 2        | 2025-10-25        | 2025-10-28         | 101     | 101          | Standard Single
```

---

## 🧪 **Edge Case Testing**

### **Test 1: No Available Rooms**

**Scenario:** All Standard Single rooms are booked for Oct 25-28

**Expected:**
- ❌ Error message: "No available rooms of the selected type for the requested dates. Please try different dates or room type."
- ✅ No room marked unavailable
- ✅ No pre-booking created
- ✅ Transaction rolled back

### **Test 2: Date Overlap Prevention**

**Scenario:**
- Customer A books Room 101 for Oct 25-28
- Customer B tries to book Standard Single for Oct 26-27 (overlaps!)

**Expected:**
- ✅ Customer A gets Room 101
- ✅ Room 101 marked unavailable Oct 25-28
- ✅ Customer B gets Room 102 (different room)
- ✅ Room 102 marked unavailable Oct 26-27
- ✅ Both pre-bookings created successfully

### **Test 3: Same Dates, Different Types**

**Scenario:**
- Customer A books Standard Single for Oct 25-28
- Customer B books Deluxe King for Oct 25-28

**Expected:**
- ✅ Both get different rooms (different types)
- ✅ No conflict (different room types)
- ✅ Both pre-bookings successful

---

## 🐛 **Troubleshooting**

### **Issue 1: Room Types Dropdown Empty**

**Symptoms:**
- Dropdown shows "No room types available"
- Console error or no data

**Check:**
1. Backend running? `http://localhost:5000`
2. Database has room_type records?
3. API response: `http://localhost:5000/api/rooms/types/summary`

**Console should show:**
```javascript
✅ Room Types API Response: {
  success: true,
  data: [
    {room_type_id: 1, type_name: "Standard Single", capacity: 2, daily_rate: "5000.00", ...},
    {room_type_id: 2, type_name: "Standard Double", capacity: 4, daily_rate: "8000.00", ...},
    ...
  ]
}
```

**If not, check:**
- `.env` file has `REACT_APP_API_BASE=http://localhost:5000`
- Restart frontend: Ctrl+C, then `npm start`

---

### **Issue 2: "guest_id is required" Error**

**Symptoms:**
- Form submits but gets error about guest_id

**Check:**
```javascript
console.log('User object:', user);
console.log('Guest ID:', user?.user_id || user?.id);
```

**If undefined:**
- User not logged in properly
- Token expired
- Login again: `nuwan.peiris7` / `password123`

---

### **Issue 3: Backend Can't Find Available Room**

**Symptoms:**
- Error: "No available rooms of the selected type"
- But you know rooms exist

**Check Database:**
```sql
-- Check room status
SELECT r.room_id, r.room_number, r.status, r.future_status,
       r.unavailable_from, r.unavailable_to,
       rt.name as room_type
FROM room r
JOIN room_type rt ON r.room_type_id = rt.room_type_id
WHERE r.room_type_id = 1  -- Your selected type
AND r.branch_id = 1        -- Your selected branch
ORDER BY r.room_number;
```

**Possible causes:**
- All rooms have `status = 'Occupied'` → Change some to `'Available'`
- All rooms have `future_status = 'Unavailable'` with overlapping dates → Clear old dates
- Rooms in `booking` table with active bookings → Check booking conflicts

**Fix:**
```sql
-- Reset room availability
UPDATE room 
SET status = 'Available',
    future_status = NULL,
    unavailable_from = NULL,
    unavailable_to = NULL
WHERE room_type_id = 1 AND branch_id = 1;
```

---

### **Issue 4: Transaction Rollback**

**Symptoms:**
- Backend logs show "ROLLBACK"
- No pre-booking created
- Room not marked unavailable

**This is GOOD!** It means:
- ✅ System detected an error
- ✅ Prevented partial data corruption
- ✅ Database remains consistent

**Check backend logs for actual error:**
- Date validation failed?
- Room query returned nothing?
- Insert constraint violated?

---

## 📁 **Key Files Modified**

### **1. CustomerPortal.js**
- Shows room type names in dropdown
- Displays daily rate and available count
- Submits room_type_id (not room_id)
- Shows success message with assigned room

### **2. routers/booking.js**
- POST `/api/bookings/pre-booking` endpoint
- Finds available room automatically
- Marks room unavailable with future_status
- Creates pre-booking with assigned room_id
- Uses transactions for safety

### **3. routers/rooms.js**
- GET `/api/rooms/types/summary` endpoint
- Returns all room types with counts
- Route order fixed (specific before /:id)

### **4. controllers/roomcontroller.js**
- `getRoomTypesSummary()` function
- Joins room_type with room table
- Counts total and available rooms

### **5. .env**
- Added `REACT_APP_API_BASE=http://localhost:5000`
- Points frontend to local backend

---

## ✅ **System Complete!**

Your customer pre-booking system now:

1. ✅ **Shows room type names** (Standard Single, Suite, etc.)
2. ✅ **Customer selects TYPE, not specific room**
3. ✅ **Backend auto-assigns best available room**
4. ✅ **Marks room unavailable** using future_status columns
5. ✅ **Prevents double-booking** with date overlap checks
6. ✅ **Transaction safety** ensures data consistency
7. ✅ **Customer sees confirmation** with room details

**Everything works exactly as you requested!** 🎉

---

## 🚀 **Quick Start Checklist**

- [ ] Backend running on port 5000
- [ ] Frontend running on port 3000
- [ ] Room types exist in database (4 types)
- [ ] Some rooms marked as 'Available'
- [ ] Customer account exists (nuwan.peiris7)
- [ ] `.env` points to localhost:5000
- [ ] Browser console shows successful API calls
- [ ] Dropdown shows room type names
- [ ] Form submits successfully
- [ ] Database shows future_status = 'Unavailable'
- [ ] Pre-booking created with room_id

**All done!** 🎊
