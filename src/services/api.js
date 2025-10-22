import apiClient from './apiClient';

// ==================== AUTH API ====================
export const authAPI = {
  // Login
  login: (credentials) => apiClient.post('/auth/login', credentials),
  
  // Register Staff (Admin, Receptionist, Manager, Accountant)
  registerStaff: (staffData) => apiClient.post('/auth/register/staff', staffData),
  
  // Register Customer
  registerCustomer: (customerData) => apiClient.post('/auth/register/customer', customerData),
  
  // Get current user profile
  getProfile: () => apiClient.get('/auth/profile'),
  
  // Update staff profile
  updateStaffProfile: (profileData) => apiClient.put('/auth/updateprofile/staff', profileData),
  
  // Update customer profile
  updateCustomerProfile: (profileData) => apiClient.put('/auth/updateprofile/customer', profileData),
  
  // Logout (client-side)
  logout: () => {
    localStorage.removeItem('authToken');
    localStorage.removeItem('user');
  }
};

// ==================== GUEST API ====================
export const guestAPI = {
  // Get all guests
  getAllGuests: (params) => apiClient.get('/guests', { params }),
  
  // Get guest by ID
  getGuestById: (id) => apiClient.get(`/guests/${id}`),
  
  // Create new guest
  createGuest: (guestData) => apiClient.post('/guests', guestData),
  
  // Update guest
  updateGuest: (id, guestData) => apiClient.put(`/guests/${id}`, guestData),
  
  // Delete guest
  deleteGuest: (id) => apiClient.delete(`/guests/${id}`),
  
  // Search guests
  searchGuests: (searchTerm) => apiClient.get(`/guests/search?q=${searchTerm}`)
};

// ==================== ROOM API ====================
export const roomAPI = {
  // Get all rooms with filters
  getAllRooms: (params) => apiClient.get('/rooms', { params }),
  
  // Get room by ID
  getRoomById: (id) => apiClient.get(`/rooms/${id}`),
  
  // Create new room (admin/manager only)
  createRoom: (roomData) => apiClient.post('/rooms', roomData),
  
  // Update room (admin/manager only)
  updateRoom: (id, roomData) => apiClient.put(`/rooms/${id}`, roomData),
  
  // Delete room (admin only)
  deleteRoom: (id) => apiClient.delete(`/rooms/${id}`),
  
  // Get room availability for date range
  getRoomAvailability: (startDate, endDate) => 
    apiClient.get('/rooms/availability/check', { 
      params: { start_date: startDate, end_date: endDate } 
    }),
  
  // Update room status (admin/manager only)
  updateRoomStatus: (id, status) => apiClient.patch(`/rooms/${id}/status`, { status }),
  
  // Get room types summary
  getRoomTypesSummary: () => apiClient.get('/rooms/types/summary')
};

// ==================== BOOKING API ====================
export const bookingAPI = {
  // Get all pre-bookings
  getAllPreBookings: (params) => apiClient.get('/bookings/prebkooking/all', { params }),
  
  // Get all confirmed bookings
  getAllBookings: (params) => apiClient.get('/bookings/booking/all', { params }),
  
  // Get booking by ID
  getBookingById: (id) => apiClient.get(`/bookings/${id}`),
  
  // Create new pre-booking
  createPreBooking: (preBookingData) => apiClient.post('/bookings/prebooking', preBookingData),
  
  // Create new confirmed booking
  createBooking: (bookingData) => apiClient.post('/bookings/confirmed', bookingData),
  
  // Cancel a created booking
  cancelCreatedBooking: (bookingId) => apiClient.post('/bookings/booking/cancel', { booking_id: bookingId }),
  
  // Cancel booking (with reason)
  cancelBooking: (id, reason) => apiClient.post(`/bookings/${id}/cancel`, { reason }),
  
  // Check-in guest
  checkIn: (id) => apiClient.post(`/bookings/${id}/checkin`),
  
  // Check-out guest
  checkOut: (id) => apiClient.post(`/bookings/${id}/checkout`),
  
  // Get today's check-ins
  getTodayCheckIns: () => apiClient.get('/bookings/today/checkins'),
  
  // Get today's check-outs
  getTodayCheckOuts: () => apiClient.get('/bookings/today/checkouts')
};

// ==================== PAYMENT API ====================
export const paymentAPI = {
  // Get all payments
  getAllPayments: (params) => apiClient.get('/payments', { params }),
  
  // Get payment by ID
  getPaymentById: (id) => apiClient.get(`/payments/${id}`),
  
  // Create new payment
  createPayment: (paymentData) => apiClient.post('/payments', paymentData),
  
  // Get payments by booking ID
  getPaymentsByBooking: (bookingId) => apiClient.get(`/payments/booking/${bookingId}`),
  
  // Get payment summary
  getPaymentSummary: (startDate, endDate) => 
    apiClient.get('/payments/summary', { 
      params: { start_date: startDate, end_date: endDate } 
    })
};

// ==================== REPORT API ====================
export const reportAPI = {
  // Get occupancy report
  getOccupancyReport: (startDate, endDate) => 
    apiClient.get('/reports/occupancy', { 
      params: { start: startDate, end: endDate } 
    }),
  
  // Get revenue report
  getRevenueReport: (startDate, endDate) => 
    apiClient.get('/reports/revenue', { 
      params: { start: startDate, end: endDate } 
    }),
  
  // Get guest report
  getGuestReport: (startDate, endDate) => 
    apiClient.get('/reports/guests', { 
      params: { start: startDate, end: endDate } 
    }),
  
  // Get dashboard stats
  getDashboardStats: () => apiClient.get('/reports/dashboard'),
  
  // Export report
  exportReport: (reportType, format, startDate, endDate) => 
    apiClient.get(`/reports/export/${reportType}`, {
      params: { format, start: startDate, end: endDate },
      responseType: 'blob'
    })
};

// ==================== LEGACY COMPATIBILITY ====================
// Keeping old reservation API for backward compatibility
export const reservationAPI = {
  // Map to booking API
  getAllReservations: (params) => bookingAPI.getAllBookings(params),
  getReservationById: (id) => bookingAPI.getBookingById(id),
  createReservation: (data) => bookingAPI.createBooking(data),
  deleteReservation: (id) => bookingAPI.cancelBooking(id),
  getReservationsByStatus: (status) => bookingAPI.getAllBookings({ status }),
  checkIn: (id) => bookingAPI.checkIn(id),
  checkOut: (id) => bookingAPI.checkOut(id)
};

// Service API functions
export const serviceAPI = {
  // Get all services
  getAllServices: () => apiClient.get('/services'),
  
  // Get service by ID
  getServiceById: (id) => apiClient.get(`/services/${id}`),
  
  // Create new service request
  createService: (serviceData) => apiClient.post('/services', serviceData),
  
  // Update service
  updateService: (id, serviceData) => apiClient.put(`/services/${id}`, serviceData),
  
  // Delete service
  deleteService: (id) => apiClient.delete(`/services/${id}`)
};

// ==================== EMPLOYEE API ====================
export const employeeAPI = {
  // Get all employees
  getAllEmployees: (params) => apiClient.get('/employees', { params }),
  
  // Get employee by ID
  getEmployeeById: (id) => apiClient.get(`/employees/${id}`),
  
  // Create new employee
  createEmployee: (employeeData) => apiClient.post('/employees', employeeData),
  
  // Update employee
  updateEmployee: (id, employeeData) => apiClient.put(`/employees/${id}`, employeeData),
  
  // Delete employee
  deleteEmployee: (id) => apiClient.delete(`/employees/${id}`),
  
  // Get employee statistics
  getEmployeeStats: (params) => apiClient.get('/employees/stats', { params })
};

// Default export for convenience
export default {
  auth: authAPI,
  guest: guestAPI,
  room: roomAPI,
  booking: bookingAPI,
  payment: paymentAPI,
  report: reportAPI,
  reservation: reservationAPI,
  service: serviceAPI,
  employee: employeeAPI
};