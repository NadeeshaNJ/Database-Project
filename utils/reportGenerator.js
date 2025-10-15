const { Booking, Room, Guest, Payment } = require('../models');
const { Op } = require('sequelize');
const moment = require('moment');
const { formatCurrency, generateDateRange } = require('./helpers');

/**
 * Report generator for various hotel reports
 */
class ReportGenerator {
  /**
   * Generate occupancy report
   */
  async generateOccupancyReport(startDate, endDate) {
    const dates = generateDateRange(startDate, endDate);
    
    const occupancyData = await Promise.all(
      dates.map(async (date) => {
        const occupiedRooms = await Booking.count({
          where: {
            [Op.and]: [
              { check_in: { [Op.lte]: date } },
              { check_out: { [Op.gt]: date } },
              { status: { [Op.in]: ['confirmed', 'checked_in'] } }
            ]
          }
        });

        const totalRooms = await Room.count();
        const occupancyRate = totalRooms > 0 ? (occupiedRooms / totalRooms) * 100 : 0;

        return {
          date,
          occupied_rooms: occupiedRooms,
          total_rooms: totalRooms,
          occupancy_rate: Math.round(occupancyRate * 100) / 100
        };
      })
    );

    return {
      report_type: 'occupancy',
      period: { start_date: startDate, end_date: endDate },
      data: occupancyData,
      summary: {
        average_occupancy: Math.round(
          occupancyData.reduce((sum, day) => sum + day.occupancy_rate, 0) / occupancyData.length
        ),
        peak_occupancy: Math.max(...occupancyData.map(day => day.occupancy_rate)),
        lowest_occupancy: Math.min(...occupancyData.map(day => day.occupancy_rate))
      }
    };
  }

  /**
   * Generate revenue report
   */
  async generateRevenueReport(startDate, endDate) {
    const payments = await Payment.findAll({
      where: {
        payment_status: 'completed',
        payment_date: {
          [Op.between]: [startDate, endDate]
        }
      },
      include: [{
        model: Booking,
        include: [Room, Guest]
      }]
    });

    const dailyRevenue = {};
    const roomTypeRevenue = {};
    let totalRevenue = 0;

    payments.forEach(payment => {
      const date = moment(payment.payment_date).format('YYYY-MM-DD');
      const roomType = payment.Booking.Room.room_type;
      const amount = parseFloat(payment.amount);

      // Daily revenue
      dailyRevenue[date] = (dailyRevenue[date] || 0) + amount;

      // Room type revenue
      roomTypeRevenue[roomType] = (roomTypeRevenue[roomType] || 0) + amount;

      totalRevenue += amount;
    });

    return {
      report_type: 'revenue',
      period: { start_date: startDate, end_date: endDate },
      total_revenue: totalRevenue,
      daily_revenue: dailyRevenue,
      room_type_revenue: roomTypeRevenue,
      payment_count: payments.length
    };
  }

  /**
   * Generate guest statistics report
   */
  async generateGuestReport(startDate, endDate) {
    const bookings = await Booking.findAll({
      where: {
        created_at: {
          [Op.between]: [startDate, endDate]
        }
      },
      include: [Guest]
    });

    const guestCountries = {};
    const repeatGuests = new Set();
    const guestCounts = {};
    let totalGuests = 0;

    bookings.forEach(booking => {
      const guestId = booking.guest_id;
      const country = booking.Guest.country || 'Unknown';

      // Count by country
      guestCountries[country] = (guestCountries[country] || 0) + 1;

      // Track repeat guests
      if (guestCounts[guestId]) {
        repeatGuests.add(guestId);
      }
      guestCounts[guestId] = true;

      totalGuests++;
    });

    return {
      report_type: 'guest_statistics',
      period: { start_date: startDate, end_date: endDate },
      total_guests: totalGuests,
      unique_guests: Object.keys(guestCounts).length,
      repeat_guests: repeatGuests.size,
      guest_by_country: guestCountries,
      repeat_guest_rate: Math.round((repeatGuests.size / Object.keys(guestCounts).length) * 100) || 0
    };
  }

  /**
   * Generate room performance report
   */
  async generateRoomPerformanceReport(startDate, endDate) {
    const rooms = await Room.findAll({
      include: [{
        model: Booking,
        where: {
          created_at: {
            [Op.between]: [startDate, endDate]
          }
        },
        required: false
      }]
    });

    const roomPerformance = rooms.map(room => {
      const bookings = room.Bookings || [];
      const revenue = bookings.reduce((sum, booking) => sum + parseFloat(booking.total_amount), 0);
      const occupiedNights = bookings.reduce((sum, booking) => {
        const nights = moment(booking.check_out).diff(moment(booking.check_in), 'days');
        return sum + nights;
      }, 0);

      const totalNights = moment(endDate).diff(moment(startDate), 'days');
      const utilization = totalNights > 0 ? (occupiedNights / totalNights) * 100 : 0;

      return {
        room_number: room.room_number,
        room_type: room.room_type,
        total_bookings: bookings.length,
        occupied_nights: occupiedNights,
        total_revenue: revenue,
        utilization_rate: Math.round(utilization * 100) / 100,
        revenue_per_night: occupiedNights > 0 ? revenue / occupiedNights : 0
      };
    });

    return {
      report_type: 'room_performance',
      period: { start_date: startDate, end_date: endDate },
      data: roomPerformance,
      summary: {
        total_revenue: roomPerformance.reduce((sum, room) => sum + room.total_revenue, 0),
        average_utilization: Math.round(
          roomPerformance.reduce((sum, room) => sum + room.utilization_rate, 0) / roomPerformance.length
        ),
        best_performing_room: roomPerformance.reduce((best, room) => 
          room.total_revenue > best.total_revenue ? room : best
        )
      }
    };
  }

  /**
   * Generate booking channel report
   */
  async generateBookingChannelReport(startDate, endDate) {
    // This would typically integrate with different booking channels
    // For now, we'll simulate some data
    const channels = {
      'Direct Website': 45,
      'Booking.com': 25,
      'Expedia': 15,
      'Walk-in': 10,
      'Phone': 5
    };

    const totalBookings = Object.values(channels).reduce((sum, count) => sum + count, 0);

    const channelData = Object.entries(channels).map(([channel, count]) => ({
      channel,
      bookings: count,
      percentage: Math.round((count / totalBookings) * 100)
    }));

    return {
      report_type: 'booking_channels',
      period: { start_date: startDate, end_date: endDate },
      data: channelData,
      total_bookings: totalBookings
    };
  }
}

module.exports = new ReportGenerator();