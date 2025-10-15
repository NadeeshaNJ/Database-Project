const nodemailer = require('nodemailer');

/**
 * Email service for sending notifications
 */
class EmailService {
  constructor() {
    this.transporter = nodemailer.createTransporter({
      host: process.env.EMAIL_HOST,
      port: parseInt(process.env.EMAIL_PORT),
      secure: false,
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
      }
    });
  }

  /**
   * Send booking confirmation email
   */
  async sendBookingConfirmation(guest, booking, room) {
    const mailOptions = {
      from: `"Hotel Management System" <${process.env.EMAIL_USER}>`,
      to: guest.email,
      subject: 'Booking Confirmation - Hotel Management System',
      html: this.generateBookingConfirmationTemplate(guest, booking, room)
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log(`Booking confirmation email sent to ${guest.email}`);
    } catch (error) {
      console.error('Error sending booking confirmation email:', error);
    }
  }

  /**
   * Send check-in reminder email
   */
  async sendCheckInReminder(guest, booking, room) {
    const mailOptions = {
      from: `"Hotel Management System" <${process.env.EMAIL_USER}>`,
      to: guest.email,
      subject: 'Check-in Reminder - Hotel Management System',
      html: this.generateCheckInReminderTemplate(guest, booking, room)
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log(`Check-in reminder email sent to ${guest.email}`);
    } catch (error) {
      console.error('Error sending check-in reminder email:', error);
    }
  }

  /**
   * Generate booking confirmation email template
   */
  generateBookingConfirmationTemplate(guest, booking, room) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #2c3e50; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background: #f9f9f9; }
          .booking-details { background: white; padding: 15px; border-radius: 5px; margin: 15px 0; }
          .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Booking Confirmed!</h1>
          </div>
          <div class="content">
            <p>Dear ${guest.first_name} ${guest.last_name},</p>
            <p>Your booking has been confirmed. Here are your booking details:</p>
            
            <div class="booking-details">
              <h3>Booking Information</h3>
              <p><strong>Booking ID:</strong> ${booking.id}</p>
              <p><strong>Check-in:</strong> ${booking.check_in}</p>
              <p><strong>Check-out:</strong> ${booking.check_out}</p>
              <p><strong>Room:</strong> ${room.room_number} (${room.room_type})</p>
              <p><strong>Total Amount:</strong> $${booking.total_amount}</p>
            </div>

            <p>We look forward to welcoming you!</p>
            <p>Best regards,<br>Hotel Management Team</p>
          </div>
          <div class="footer">
            <p>This is an automated message. Please do not reply to this email.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  /**
   * Generate check-in reminder email template
   */
  generateCheckInReminderTemplate(guest, booking, room) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #e67e22; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background: #f9f9f9; }
          .booking-details { background: white; padding: 15px; border-radius: 5px; margin: 15px 0; }
          .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Check-in Reminder</h1>
          </div>
          <div class="content">
            <p>Dear ${guest.first_name} ${guest.last_name},</p>
            <p>This is a friendly reminder about your upcoming stay with us.</p>
            
            <div class="booking-details">
              <h3>Your Stay Details</h3>
              <p><strong>Check-in:</strong> ${booking.check_in}</p>
              <p><strong>Check-out:</strong> ${booking.check_out}</p>
              <p><strong>Room:</strong> ${room.room_number} (${room.room_type})</p>
              <p><strong>Address:</strong> 123 Hotel Street, City, Country</p>
            </div>

            <p>Check-in time is from 3:00 PM. We can't wait to see you!</p>
            <p>Best regards,<br>Hotel Management Team</p>
          </div>
          <div class="footer">
            <p>This is an automated message. Please do not reply to this email.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  /**
   * Test email configuration
   */
  async testConnection() {
    try {
      await this.transporter.verify();
      console.log('Email server connection verified');
      return true;
    } catch (error) {
      console.error('Email server connection failed:', error);
      return false;
    }
  }
}

module.exports = new EmailService();