// Enums matching the PostgreSQL schema

export const RoomStatus = {
  AVAILABLE: 'Available',
  OCCUPIED: 'Occupied',
  MAINTENANCE: 'Maintenance'
};

export const BookingStatus = {
  BOOKED: 'Booked',
  CHECKED_IN: 'Checked_In',
  CHECKED_OUT: 'Checked_Out',
  CANCELLED: 'Cancelled'
};

export const PaymentMethod = {
  CASH: 'Cash',
  CARD: 'Card',
  ONLINE: 'Online',
  BANK_TRANSFER: 'BankTransfer'
};

export const UserRole = {
  ADMIN: 'Admin',
  MANAGER: 'Manager',
  RECEPTIONIST: 'Receptionist',
  ACCOUNTANT: 'Accountant',
  CUSTOMER: 'Customer'
};

export const PreBookingMethod = {
  ONLINE: 'Online',
  PHONE: 'Phone',
  WALK_IN: 'Walk_in'
};

export const AdjustmentType = {
  REFUND: 'refund',
  CHARGEBACK: 'chargeback',
  MANUAL_ADJUSTMENT: 'manual_adjustment'
};

// Sample data matching ERD structure

export const branches = [
  {
    branch_id: 1,
    branch_name: 'SkyNest Colombo',
    contact_number: '+94 11 234 5678',
    address: '123 Galle Road, Colombo 03, Sri Lanka',
    manager_name: 'Anura Perera'
  },
  {
    branch_id: 2,
    branch_name: 'SkyNest Kandy',
    contact_number: '+94 81 234 5678',
    address: '45 Peradeniya Road, Kandy, Sri Lanka',
    manager_name: 'Shalini Fernando'
  },
  {
    branch_id: 3,
    branch_name: 'SkyNest Galle',
    contact_number: '+94 91 234 5678',
    address: '78 Fort Road, Galle, Sri Lanka',
    manager_name: 'Rajitha Silva'
  }
];

export const roomTypes = [
  {
    room_type_id: 1,
    name: 'Single',
    capacity: 1,
    daily_rate: 8000.00,
    amenities: 'WiFi, AC, TV, Mini Bar, Safe'
  },
  {
    room_type_id: 2,
    name: 'Double',
    capacity: 2,
    daily_rate: 12000.00,
    amenities: 'WiFi, AC, TV, Mini Bar, Safe, Balcony'
  },
  {
    room_type_id: 3,
    name: 'Suite',
    capacity: 4,
    daily_rate: 20000.00,
    amenities: 'WiFi, AC, TV, Mini Bar, Safe, Balcony, Living Area, Kitchenette'
  }
];

export const rooms = [
  // Colombo Branch
  { room_id: 1, branch_id: 1, room_type_id: 1, room_number: '101', status: RoomStatus.AVAILABLE },
  { room_id: 2, branch_id: 1, room_type_id: 1, room_number: '102', status: RoomStatus.OCCUPIED },
  { room_id: 3, branch_id: 1, room_type_id: 2, room_number: '201', status: RoomStatus.AVAILABLE },
  { room_id: 4, branch_id: 1, room_type_id: 3, room_number: '301', status: RoomStatus.AVAILABLE },
  
  // Kandy Branch
  { room_id: 5, branch_id: 2, room_type_id: 1, room_number: '101', status: RoomStatus.AVAILABLE },
  { room_id: 6, branch_id: 2, room_type_id: 2, room_number: '205', status: RoomStatus.OCCUPIED },
  { room_id: 7, branch_id: 2, room_type_id: 3, room_number: '308', status: RoomStatus.MAINTENANCE },
  
  // Galle Branch
  { room_id: 8, branch_id: 3, room_type_id: 1, room_number: '102', status: RoomStatus.AVAILABLE },
  { room_id: 9, branch_id: 3, room_type_id: 2, room_number: '201', status: RoomStatus.AVAILABLE },
  { room_id: 10, branch_id: 3, room_type_id: 3, room_number: '305', status: RoomStatus.AVAILABLE }
];

export const guests = [
  {
    guest_id: 1,
    nic: '199012345678',
    full_name: 'Nimal Perera',
    email: 'nimal.perera@email.com',
    phone: '+94 77 123 4567',
    gender: 'Male',
    date_of_birth: '1990-05-15',
    address: '123, Temple Road, Colombo 05',
    nationality: 'Sri Lankan'
  },
  {
    guest_id: 2,
    nic: '198523456789',
    full_name: 'Sanduni Silva',
    email: 'sanduni.silva@email.com',
    phone: '+94 71 234 5678',
    gender: 'Female',
    date_of_birth: '1985-08-22',
    address: '456, Lake Road, Kandy',
    nationality: 'Sri Lankan'
  },
  {
    guest_id: 3,
    nic: '199234567890',
    full_name: 'Kamal Fernando',
    email: 'kamal.fernando@email.com',
    phone: '+94 76 345 6789',
    gender: 'Male',
    date_of_birth: '1992-03-10',
    address: '789, Beach Road, Galle',
    nationality: 'Sri Lankan'
  },
  {
    guest_id: 4,
    nic: null,
    full_name: 'John Smith',
    email: 'john.smith@email.com',
    phone: '+1 555 123 4567',
    gender: 'Male',
    date_of_birth: '1988-11-30',
    address: '123 Main St, New York, USA',
    nationality: 'American'
  }
];

export const serviceCatalog = [
  {
    service_id: 1,
    code: 'BRKFST',
    name: 'Breakfast',
    category: 'Food & Beverage',
    unit_price: 1500.00,
    tax_rate_percent: 10.00,
    active: true
  },
  {
    service_id: 2,
    code: 'LUNCH',
    name: 'Lunch',
    category: 'Food & Beverage',
    unit_price: 2500.00,
    tax_rate_percent: 10.00,
    active: true
  },
  {
    service_id: 3,
    code: 'DINNER',
    name: 'Dinner',
    category: 'Food & Beverage',
    unit_price: 3000.00,
    tax_rate_percent: 10.00,
    active: true
  },
  {
    service_id: 4,
    code: 'LAUNDRY',
    name: 'Laundry Service',
    category: 'Housekeeping',
    unit_price: 500.00,
    tax_rate_percent: 10.00,
    active: true
  },
  {
    service_id: 5,
    code: 'SPA',
    name: 'Spa Treatment',
    category: 'Wellness',
    unit_price: 5000.00,
    tax_rate_percent: 10.00,
    active: true
  },
  {
    service_id: 6,
    code: 'AIRPORT',
    name: 'Airport Transfer',
    category: 'Transportation',
    unit_price: 3500.00,
    tax_rate_percent: 10.00,
    active: true
  },
  {
    service_id: 7,
    code: 'PARKING',
    name: 'Parking',
    category: 'Facilities',
    unit_price: 500.00,
    tax_rate_percent: 10.00,
    active: true
  }
];

export const bookings = [
  {
    booking_id: 1,
    pre_booking_id: null,
    guest_id: 1,
    room_id: 2,
    check_in_date: '2025-10-10',
    check_out_date: '2025-10-15',
    status: BookingStatus.CHECKED_IN,
    booked_rate: 8000.00,
    tax_rate_percent: 10.00,
    discount_amount: 0.00,
    late_fee_amount: 0.00,
    advance_payment: 20000.00,
    preferred_payment_method: PaymentMethod.CARD,
    created_at: '2025-10-05T10:30:00Z'
  },
  {
    booking_id: 2,
    pre_booking_id: null,
    guest_id: 2,
    room_id: 6,
    check_in_date: '2025-10-12',
    check_out_date: '2025-10-18',
    status: BookingStatus.CHECKED_IN,
    booked_rate: 12000.00,
    tax_rate_percent: 10.00,
    discount_amount: 2000.00,
    late_fee_amount: 0.00,
    advance_payment: 30000.00,
    preferred_payment_method: PaymentMethod.ONLINE,
    created_at: '2025-10-08T14:20:00Z'
  },
  {
    booking_id: 3,
    pre_booking_id: null,
    guest_id: 3,
    room_id: 3,
    check_in_date: '2025-10-20',
    check_out_date: '2025-10-25',
    status: BookingStatus.BOOKED,
    booked_rate: 12000.00,
    tax_rate_percent: 10.00,
    discount_amount: 0.00,
    late_fee_amount: 0.00,
    advance_payment: 12000.00,
    preferred_payment_method: PaymentMethod.CASH,
    created_at: '2025-10-14T09:15:00Z'
  }
];

export const serviceUsage = [
  {
    service_usage_id: 1,
    booking_id: 1,
    service_id: 1,
    used_on: '2025-10-11',
    qty: 2,
    unit_price_at_use: 1500.00
  },
  {
    service_usage_id: 2,
    booking_id: 1,
    service_id: 3,
    used_on: '2025-10-11',
    qty: 2,
    unit_price_at_use: 3000.00
  },
  {
    service_usage_id: 3,
    booking_id: 2,
    service_id: 1,
    used_on: '2025-10-13',
    qty: 2,
    unit_price_at_use: 1500.00
  },
  {
    service_usage_id: 4,
    booking_id: 2,
    service_id: 5,
    used_on: '2025-10-14',
    qty: 1,
    unit_price_at_use: 5000.00
  }
];

export const payments = [
  {
    payment_id: 1,
    booking_id: 1,
    amount: 20000.00,
    method: PaymentMethod.CARD,
    paid_at: '2025-10-10T14:00:00Z',
    payment_reference: 'PAY-001-2025'
  },
  {
    payment_id: 2,
    booking_id: 2,
    amount: 30000.00,
    method: PaymentMethod.ONLINE,
    paid_at: '2025-10-12T10:00:00Z',
    payment_reference: 'PAY-002-2025'
  },
  {
    payment_id: 3,
    booking_id: 3,
    amount: 12000.00,
    method: PaymentMethod.CASH,
    paid_at: '2025-10-14T11:00:00Z',
    payment_reference: 'PAY-003-2025'
  }
];

// Helper functions
export const getBranchById = (branch_id) => branches.find(b => b.branch_id === branch_id);
export const getRoomTypeById = (room_type_id) => roomTypes.find(rt => rt.room_type_id === room_type_id);
export const getRoomById = (room_id) => rooms.find(r => r.room_id === room_id);
export const getGuestById = (guest_id) => guests.find(g => g.guest_id === guest_id);
export const getServiceById = (service_id) => serviceCatalog.find(s => s.service_id === service_id);

export const getRoomsByBranch = (branch_id) => rooms.filter(r => r.branch_id === branch_id);
export const getBookingsByGuest = (guest_id) => bookings.filter(b => b.guest_id === guest_id);
export const getServiceUsageByBooking = (booking_id) => serviceUsage.filter(su => su.booking_id === booking_id);
export const getPaymentsByBooking = (booking_id) => payments.filter(p => p.booking_id === booking_id);

// Calculate booking totals
export const calculateBookingTotal = (booking) => {
  const nights = Math.ceil(
    (new Date(booking.check_out_date) - new Date(booking.check_in_date)) / (1000 * 60 * 60 * 24)
  );
  
  const roomTotal = booking.booked_rate * nights;
  const roomTax = roomTotal * (booking.tax_rate_percent / 100);
  
  // Calculate service charges
  const services = getServiceUsageByBooking(booking.booking_id);
  const serviceTotal = services.reduce((sum, su) => sum + (su.unit_price_at_use * su.qty), 0);
  const serviceTax = services.reduce((sum, su) => {
    const service = getServiceById(su.service_id);
    return sum + (su.unit_price_at_use * su.qty * (service?.tax_rate_percent || 0) / 100);
  }, 0);
  
  const subtotal = roomTotal + serviceTotal;
  const totalTax = roomTax + serviceTax;
  const grandTotal = subtotal + totalTax - booking.discount_amount + booking.late_fee_amount;
  
  // Calculate paid and outstanding
  const totalPaid = getPaymentsByBooking(booking.booking_id)
    .reduce((sum, p) => sum + p.amount, 0);
  const outstanding = grandTotal - totalPaid;
  
  return {
    nights,
    roomTotal,
    roomTax,
    serviceTotal,
    serviceTax,
    subtotal,
    totalTax,
    discount: booking.discount_amount,
    lateFee: booking.late_fee_amount,
    grandTotal,
    totalPaid,
    outstanding
  };
};
