import apiClient from './apiClient';

// Guest API functions
export const guestAPI = {
  // Get all guests
  getAllGuests: () => apiClient.get('/guests'),
  
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

// Reservation API functions
export const reservationAPI = {
  // Get all reservations
  getAllReservations: () => apiClient.get('/reservations'),
  
  // Get reservation by ID
  getReservationById: (id) => apiClient.get(`/reservations/${id}`),
  
  // Create new reservation
  createReservation: (reservationData) => apiClient.post('/reservations', reservationData),
  
  // Update reservation
  updateReservation: (id, reservationData) => apiClient.put(`/reservations/${id}`, reservationData),
  
  // Delete reservation
  deleteReservation: (id) => apiClient.delete(`/reservations/${id}`),
  
  // Get reservations by status
  getReservationsByStatus: (status) => apiClient.get(`/reservations/status/${status}`),
  
  // Check-in guest
  checkIn: (reservationId) => apiClient.post(`/reservations/${reservationId}/checkin`),
  
  // Check-out guest
  checkOut: (reservationId) => apiClient.post(`/reservations/${reservationId}/checkout`)
};

// Room API functions
export const roomAPI = {
  // Get all rooms
  getAllRooms: () => apiClient.get('/rooms'),
  
  // Get room by ID
  getRoomById: (id) => apiClient.get(`/rooms/${id}`),
  
  // Create new room
  createRoom: (roomData) => apiClient.post('/rooms', roomData),
  
  // Update room
  updateRoom: (id, roomData) => apiClient.put(`/rooms/${id}`, roomData),
  
  // Delete room
  deleteRoom: (id) => apiClient.delete(`/rooms/${id}`),
  
  // Get available rooms
  getAvailableRooms: (checkIn, checkOut) => 
    apiClient.get(`/rooms/available?checkIn=${checkIn}&checkOut=${checkOut}`),
  
  // Update room status
  updateRoomStatus: (id, status) => apiClient.patch(`/rooms/${id}/status`, { status })
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
  deleteService: (id) => apiClient.delete(`/services/${id}`),
  
  // Get services by status
  getServicesByStatus: (status) => apiClient.get(`/services/status/${status}`),
  
  // Assign service to staff
  assignService: (serviceId, staffId) => 
    apiClient.patch(`/services/${serviceId}/assign`, { staffId })
};

// Report API functions
export const reportAPI = {
  // Get occupancy report
  getOccupancyReport: (startDate, endDate) => 
    apiClient.get(`/reports/occupancy?start=${startDate}&end=${endDate}`),
  
  // Get revenue report
  getRevenueReport: (startDate, endDate) => 
    apiClient.get(`/reports/revenue?start=${startDate}&end=${endDate}`),
  
  // Get guest report
  getGuestReport: (startDate, endDate) => 
    apiClient.get(`/reports/guests?start=${startDate}&end=${endDate}`),
  
  // Get dashboard stats
  getDashboardStats: () => apiClient.get('/reports/dashboard'),
  
  // Export report
  exportReport: (reportType, format, startDate, endDate) => 
    apiClient.get(`/reports/export/${reportType}?format=${format}&start=${startDate}&end=${endDate}`, {
      responseType: 'blob'
    })
};