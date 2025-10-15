const ROOM_STATUS = {
    AVAILABLE: 'Available',
    BOOKED: 'Booked',
    OCCUPIED: 'Occupied',
    MAINTENANCE: 'Maintenance',
    WALK_IN: 'Walk_in'
};

const PREBOOKING_METHOD = {
    ONLINE: 'Online',
    PHONE: 'Phone',
    WALK_IN: 'Walk_in'
};

const BOOKING_STATUS = {
    BOOKED: 'Booked',
    CHECKED_IN: 'Checked_In',
    CHECKED_OUT: 'Checked_Out',
    CANCELLED: 'Cancelled'
};

const GENDER={
    MALE: 'Male',
    FEMALE: 'Female',
    OTHER: 'Other'
}
const ADJUSTMENT_TYPE = {
    REFUND: 'refund',
    CHARGEBACK: 'chargeback',
    MANUAL_ADJUSTMENT: 'manual_adjustment'
};

const PAYMENT_METHOD = {
    CASH: 'Cash',
    CARD: 'Card',
    ONLINE: 'Online',
    BANK_TRANSFER: 'BankTransfer'
};

const USER_ROLE = {
    ADMIN: 'Admin',
    MANAGER: 'Manager',
    RECEPTIONIST: 'Receptionist',
    ACCOUNTANT: 'Accountant',
    CUSTOMER: 'Customer'
};

module.exports = {
    ROOM_STATUS,
    PREBOOKING_METHOD,
    BOOKING_STATUS,
    ADJUSTMENT_TYPE,
    PAYMENT_METHOD,
    USER_ROLE,
    GENDER
};
