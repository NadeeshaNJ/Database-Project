import React, { useState } from 'react';
import { Container, Row, Col, Card, Form, Button, Alert, Badge, ListGroup, Tab, Tabs } from 'react-bootstrap';
import { 
  FaCog, FaBell, FaShieldAlt, FaHotel, FaPalette, FaSave, 
  FaEnvelope, FaMoon, FaSun, FaLanguage, FaDatabase, FaUsers 
} from 'react-icons/fa';
import { useAuth } from '../context/AuthContext';

const Settings = () => {
  const { user } = useAuth();
  const [success, setSuccess] = useState('');
  const [activeTab, setActiveTab] = useState('general');

  // General Settings
  const [generalSettings, setGeneralSettings] = useState({
    hotelName: 'SkyNest Hotels',
    currency: 'LKR',
    timezone: 'Asia/Colombo',
    dateFormat: 'DD/MM/YYYY',
    language: 'English'
  });

  // Notification Settings
  const [notifications, setNotifications] = useState({
    emailNotifications: true,
    bookingAlerts: true,
    paymentAlerts: true,
    checkInReminders: true,
    checkOutReminders: true,
    maintenanceAlerts: true,
    lowInventoryAlerts: false,
    dailyReports: true
  });

  // Appearance Settings
  const [appearance, setAppearance] = useState({
    theme: 'light',
    sidebarCollapsed: false,
    compactView: false,
    showAvatars: true
  });

  // Security Settings
  const [security, setSecurity] = useState({
    twoFactorAuth: false,
    sessionTimeout: 30,
    passwordExpiry: 90,
    loginNotifications: true
  });

  // Hotel Preferences
  const [hotelPrefs, setHotelPrefs] = useState({
    checkInTime: '14:00',
    checkOutTime: '12:00',
    allowEarlyCheckIn: true,
    allowLateCheckOut: true,
    maxBookingDays: 30,
    minBookingDays: 1,
    defaultRoomStatus: 'Available'
  });

  const handleGeneralChange = (e) => {
    setGeneralSettings({
      ...generalSettings,
      [e.target.name]: e.target.value
    });
  };

  const handleNotificationChange = (e) => {
    setNotifications({
      ...notifications,
      [e.target.name]: e.target.checked
    });
  };

  const handleAppearanceChange = (e) => {
    const value = e.target.type === 'checkbox' ? e.target.checked : e.target.value;
    setAppearance({
      ...appearance,
      [e.target.name]: value
    });
  };

  const handleSecurityChange = (e) => {
    const value = e.target.type === 'checkbox' ? e.target.checked : e.target.value;
    setSecurity({
      ...security,
      [e.target.name]: value
    });
  };

  const handleHotelPrefsChange = (e) => {
    const value = e.target.type === 'checkbox' ? e.target.checked : e.target.value;
    setHotelPrefs({
      ...hotelPrefs,
      [e.target.name]: value
    });
  };

  const handleSave = (section) => {
    setSuccess(`${section} settings saved successfully!`);
    setTimeout(() => setSuccess(''), 3000);
  };

  return (
    <Container fluid className="py-4">
      <div className="mb-4 p-4 rounded-3" style={{
        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
        color: 'white',
        boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
      }}>
        <div className="d-flex align-items-center">
          <FaCog size={32} className="me-3" />
          <div>
            <h2 className="mb-0">Settings</h2>
            <p className="mb-0 opacity-75">Manage your account and system preferences</p>
          </div>
        </div>
      </div>

      {success && (
        <Alert variant="success" dismissible onClose={() => setSuccess('')}>
          {success}
        </Alert>
      )}

      <Row>
        <Col>
          <Card className="border-0 shadow-sm" style={{ borderRadius: '12px' }}>
            <Card.Body>
              <Tabs
                activeKey={activeTab}
                onSelect={(k) => setActiveTab(k)}
                className="mb-4"
                style={{
                  borderBottom: '2px solid #e9ecef'
                }}
              >
                {/* General Settings Tab */}
                <Tab eventKey="general" title={<span><FaCog className="me-2" />General</span>}>
                  <Row>
                    <Col lg={8}>
                      <h5 className="mb-3" style={{
                        color: '#1a237e',
                        fontWeight: '600',
                        paddingBottom: '12px',
                        borderBottom: '2px solid rgba(26, 35, 126, 0.2)'
                      }}>General Settings</h5>
                      <Form>
                        <Form.Group className="mb-3">
                          <Form.Label>Hotel Name</Form.Label>
                          <Form.Control
                            type="text"
                            name="hotelName"
                            value={generalSettings.hotelName}
                            onChange={handleGeneralChange}
                          />
                        </Form.Group>

                        <Row>
                          <Col md={6}>
                            <Form.Group className="mb-3">
                              <Form.Label>Currency</Form.Label>
                              <Form.Select
                                name="currency"
                                value={generalSettings.currency}
                                onChange={handleGeneralChange}
                              >
                                <option value="LKR">Sri Lankan Rupee (LKR)</option>
                                <option value="USD">US Dollar (USD)</option>
                                <option value="EUR">Euro (EUR)</option>
                                <option value="GBP">British Pound (GBP)</option>
                              </Form.Select>
                            </Form.Group>
                          </Col>
                          <Col md={6}>
                            <Form.Group className="mb-3">
                              <Form.Label>Timezone</Form.Label>
                              <Form.Select
                                name="timezone"
                                value={generalSettings.timezone}
                                onChange={handleGeneralChange}
                              >
                                <option value="Asia/Colombo">Asia/Colombo (GMT+5:30)</option>
                                <option value="UTC">UTC (GMT+0)</option>
                                <option value="America/New_York">America/New York (GMT-5)</option>
                              </Form.Select>
                            </Form.Group>
                          </Col>
                        </Row>

                        <Row>
                          <Col md={6}>
                            <Form.Group className="mb-3">
                              <Form.Label>Date Format</Form.Label>
                              <Form.Select
                                name="dateFormat"
                                value={generalSettings.dateFormat}
                                onChange={handleGeneralChange}
                              >
                                <option value="DD/MM/YYYY">DD/MM/YYYY</option>
                                <option value="MM/DD/YYYY">MM/DD/YYYY</option>
                                <option value="YYYY-MM-DD">YYYY-MM-DD</option>
                              </Form.Select>
                            </Form.Group>
                          </Col>
                          <Col md={6}>
                            <Form.Group className="mb-3">
                              <Form.Label>
                                <FaLanguage className="me-2" />
                                Language
                              </Form.Label>
                              <Form.Select
                                name="language"
                                value={generalSettings.language}
                                onChange={handleGeneralChange}
                              >
                                <option value="English">English</option>
                                <option value="Sinhala">Sinhala</option>
                                <option value="Tamil">Tamil</option>
                              </Form.Select>
                            </Form.Group>
                          </Col>
                        </Row>

                        <Button 
                          onClick={() => handleSave('General')}
                          style={{
                            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                            border: 'none',
                            borderRadius: '8px',
                            padding: '10px 24px',
                            fontWeight: '600',
                            transition: 'transform 0.3s ease, box-shadow 0.3s ease'
                          }}
                          onMouseOver={(e) => {
                            e.currentTarget.style.transform = 'translateY(-2px)';
                            e.currentTarget.style.boxShadow = '0 4px 8px rgba(26, 35, 126, 0.3)';
                          }}
                          onMouseOut={(e) => {
                            e.currentTarget.style.transform = 'translateY(0)';
                            e.currentTarget.style.boxShadow = 'none';
                          }}
                        >
                          <FaSave className="me-2" />
                          Save Changes
                        </Button>
                      </Form>
                    </Col>
                  </Row>
                </Tab>

                {/* Notifications Tab */}
                <Tab eventKey="notifications" title={<span><FaBell className="me-2" />Notifications</span>}>
                  <Row>
                    <Col lg={8}>
                      <h5 className="mb-3" style={{
                        color: '#1a237e',
                        fontWeight: '600',
                        paddingBottom: '12px',
                        borderBottom: '2px solid rgba(26, 35, 126, 0.2)'
                      }}>Notification Preferences</h5>
                      <Form>
                        <Card className="mb-3 border-0 shadow-sm" style={{ borderRadius: '10px' }}>
                          <Card.Body>
                            <h6 className="mb-3" style={{ color: '#1a237e', fontWeight: '600' }}>
                              <FaEnvelope className="me-2" />
                              Email Notifications
                            </h6>
                            <Form.Check
                              type="switch"
                              id="emailNotifications"
                              name="emailNotifications"
                              label="Enable email notifications"
                              checked={notifications.emailNotifications}
                              onChange={handleNotificationChange}
                              className="mb-2"
                            />
                            <Form.Check
                              type="switch"
                              id="dailyReports"
                              name="dailyReports"
                              label="Daily summary reports"
                              checked={notifications.dailyReports}
                              onChange={handleNotificationChange}
                              className="mb-2"
                            />
                          </Card.Body>
                        </Card>

                        <Card className="mb-3 border-0 shadow-sm" style={{ borderRadius: '10px' }}>
                          <Card.Body>
                            <h6 className="mb-3" style={{ color: '#1a237e', fontWeight: '600' }}>Booking Alerts</h6>
                            <Form.Check
                              type="switch"
                              id="bookingAlerts"
                              name="bookingAlerts"
                              label="New booking notifications"
                              checked={notifications.bookingAlerts}
                              onChange={handleNotificationChange}
                              className="mb-2"
                            />
                            <Form.Check
                              type="switch"
                              id="checkInReminders"
                              name="checkInReminders"
                              label="Check-in reminders"
                              checked={notifications.checkInReminders}
                              onChange={handleNotificationChange}
                              className="mb-2"
                            />
                            <Form.Check
                              type="switch"
                              id="checkOutReminders"
                              name="checkOutReminders"
                              label="Check-out reminders"
                              checked={notifications.checkOutReminders}
                              onChange={handleNotificationChange}
                              className="mb-2"
                            />
                          </Card.Body>
                        </Card>

                        <Card className="mb-3 border-0 shadow-sm" style={{ borderRadius: '10px' }}>
                          <Card.Body>
                            <h6 className="mb-3" style={{ color: '#1a237e', fontWeight: '600' }}>System Alerts</h6>
                            <Form.Check
                              type="switch"
                              id="paymentAlerts"
                              name="paymentAlerts"
                              label="Payment notifications"
                              checked={notifications.paymentAlerts}
                              onChange={handleNotificationChange}
                              className="mb-2"
                            />
                            <Form.Check
                              type="switch"
                              id="maintenanceAlerts"
                              name="maintenanceAlerts"
                              label="Maintenance alerts"
                              checked={notifications.maintenanceAlerts}
                              onChange={handleNotificationChange}
                              className="mb-2"
                            />
                            <Form.Check
                              type="switch"
                              id="lowInventoryAlerts"
                              name="lowInventoryAlerts"
                              label="Low inventory alerts"
                              checked={notifications.lowInventoryAlerts}
                              onChange={handleNotificationChange}
                              className="mb-2"
                            />
                          </Card.Body>
                        </Card>

                        <Button 
                          onClick={() => handleSave('Notification')}
                          style={{
                            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                            border: 'none',
                            borderRadius: '8px',
                            padding: '10px 24px',
                            fontWeight: '600',
                            transition: 'transform 0.3s ease, box-shadow 0.3s ease'
                          }}
                          onMouseOver={(e) => {
                            e.currentTarget.style.transform = 'translateY(-2px)';
                            e.currentTarget.style.boxShadow = '0 4px 8px rgba(26, 35, 126, 0.3)';
                          }}
                          onMouseOut={(e) => {
                            e.currentTarget.style.transform = 'translateY(0)';
                            e.currentTarget.style.boxShadow = 'none';
                          }}
                        >
                          <FaSave className="me-2" />
                          Save Preferences
                        </Button>
                      </Form>
                    </Col>
                  </Row>
                </Tab>

                {/* Appearance Tab */}
                <Tab eventKey="appearance" title={<span><FaPalette className="me-2" />Appearance</span>}>
                  <Row>
                    <Col lg={8}>
                      <h5 className="mb-3" style={{
                        color: '#1a237e',
                        fontWeight: '600',
                        paddingBottom: '12px',
                        borderBottom: '2px solid rgba(26, 35, 126, 0.2)'
                      }}>Appearance Settings</h5>
                      <Form>
                        <Form.Group className="mb-3">
                          <Form.Label>Theme</Form.Label>
                          <div>
                            <Form.Check
                              inline
                              type="radio"
                              id="theme-light"
                              name="theme"
                              label={<span><FaSun className="me-1" />Light</span>}
                              value="light"
                              checked={appearance.theme === 'light'}
                              onChange={handleAppearanceChange}
                            />
                            <Form.Check
                              inline
                              type="radio"
                              id="theme-dark"
                              name="theme"
                              label={<span><FaMoon className="me-1" />Dark</span>}
                              value="dark"
                              checked={appearance.theme === 'dark'}
                              onChange={handleAppearanceChange}
                            />
                          </div>
                        </Form.Group>

                        <Form.Check
                          type="switch"
                          id="sidebarCollapsed"
                          name="sidebarCollapsed"
                          label="Collapse sidebar by default"
                          checked={appearance.sidebarCollapsed}
                          onChange={handleAppearanceChange}
                          className="mb-3"
                        />

                        <Form.Check
                          type="switch"
                          id="compactView"
                          name="compactView"
                          label="Use compact view"
                          checked={appearance.compactView}
                          onChange={handleAppearanceChange}
                          className="mb-3"
                        />

                        <Form.Check
                          type="switch"
                          id="showAvatars"
                          name="showAvatars"
                          label="Show user avatars"
                          checked={appearance.showAvatars}
                          onChange={handleAppearanceChange}
                          className="mb-3"
                        />

                        <Button 
                          onClick={() => handleSave('Appearance')}
                          style={{
                            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                            border: 'none',
                            borderRadius: '8px',
                            padding: '10px 24px',
                            fontWeight: '600',
                            transition: 'transform 0.3s ease, box-shadow 0.3s ease'
                          }}
                          onMouseOver={(e) => {
                            e.currentTarget.style.transform = 'translateY(-2px)';
                            e.currentTarget.style.boxShadow = '0 4px 8px rgba(26, 35, 126, 0.3)';
                          }}
                          onMouseOut={(e) => {
                            e.currentTarget.style.transform = 'translateY(0)';
                            e.currentTarget.style.boxShadow = 'none';
                          }}
                        >
                          <FaSave className="me-2" />
                          Save Changes
                        </Button>
                      </Form>
                    </Col>
                  </Row>
                </Tab>

                {/* Security Tab */}
                <Tab eventKey="security" title={<span><FaShieldAlt className="me-2" />Security</span>}>
                  <Row>
                    <Col lg={8}>
                      <h5 className="mb-3" style={{
                        color: '#1a237e',
                        fontWeight: '600',
                        paddingBottom: '12px',
                        borderBottom: '2px solid rgba(26, 35, 126, 0.2)'
                      }}>Security Settings</h5>
                      <Form>
                        <Card className="mb-3 border-0 shadow-sm" style={{ borderRadius: '10px' }}>
                          <Card.Body>
                            <h6 className="mb-3" style={{ color: '#1a237e', fontWeight: '600' }}>Authentication</h6>
                            <Form.Check
                              type="switch"
                              id="twoFactorAuth"
                              name="twoFactorAuth"
                              label="Enable Two-Factor Authentication"
                              checked={security.twoFactorAuth}
                              onChange={handleSecurityChange}
                              className="mb-2"
                            />
                            <Form.Check
                              type="switch"
                              id="loginNotifications"
                              name="loginNotifications"
                              label="Login notifications"
                              checked={security.loginNotifications}
                              onChange={handleSecurityChange}
                              className="mb-2"
                            />
                          </Card.Body>
                        </Card>

                        <Form.Group className="mb-3">
                          <Form.Label>Session Timeout (minutes)</Form.Label>
                          <Form.Select
                            name="sessionTimeout"
                            value={security.sessionTimeout}
                            onChange={handleSecurityChange}
                          >
                            <option value="15">15 minutes</option>
                            <option value="30">30 minutes</option>
                            <option value="60">1 hour</option>
                            <option value="120">2 hours</option>
                            <option value="0">Never</option>
                          </Form.Select>
                        </Form.Group>

                        <Form.Group className="mb-3">
                          <Form.Label>Password Expiry (days)</Form.Label>
                          <Form.Select
                            name="passwordExpiry"
                            value={security.passwordExpiry}
                            onChange={handleSecurityChange}
                          >
                            <option value="30">30 days</option>
                            <option value="60">60 days</option>
                            <option value="90">90 days</option>
                            <option value="180">180 days</option>
                            <option value="0">Never</option>
                          </Form.Select>
                        </Form.Group>

                        <Button 
                          onClick={() => handleSave('Security')}
                          style={{
                            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                            border: 'none',
                            borderRadius: '8px',
                            padding: '10px 24px',
                            fontWeight: '600',
                            transition: 'transform 0.3s ease, box-shadow 0.3s ease'
                          }}
                          onMouseOver={(e) => {
                            e.currentTarget.style.transform = 'translateY(-2px)';
                            e.currentTarget.style.boxShadow = '0 4px 8px rgba(26, 35, 126, 0.3)';
                          }}
                          onMouseOut={(e) => {
                            e.currentTarget.style.transform = 'translateY(0)';
                            e.currentTarget.style.boxShadow = 'none';
                          }}
                        >
                          <FaSave className="me-2" />
                          Save Security Settings
                        </Button>
                      </Form>
                    </Col>
                  </Row>
                </Tab>

                {/* Hotel Preferences Tab */}
                <Tab eventKey="hotel" title={<span><FaHotel className="me-2" />Hotel Preferences</span>}>
                  <Row>
                    <Col lg={8}>
                      <h5 className="mb-3" style={{
                        color: '#1a237e',
                        fontWeight: '600',
                        paddingBottom: '12px',
                        borderBottom: '2px solid rgba(26, 35, 126, 0.2)'
                      }}>Hotel Operation Settings</h5>
                      <Form>
                        <Row>
                          <Col md={6}>
                            <Form.Group className="mb-3">
                              <Form.Label>Default Check-In Time</Form.Label>
                              <Form.Control
                                type="time"
                                name="checkInTime"
                                value={hotelPrefs.checkInTime}
                                onChange={handleHotelPrefsChange}
                              />
                            </Form.Group>
                          </Col>
                          <Col md={6}>
                            <Form.Group className="mb-3">
                              <Form.Label>Default Check-Out Time</Form.Label>
                              <Form.Control
                                type="time"
                                name="checkOutTime"
                                value={hotelPrefs.checkOutTime}
                                onChange={handleHotelPrefsChange}
                              />
                            </Form.Group>
                          </Col>
                        </Row>

                        <Form.Check
                          type="switch"
                          id="allowEarlyCheckIn"
                          name="allowEarlyCheckIn"
                          label="Allow early check-in"
                          checked={hotelPrefs.allowEarlyCheckIn}
                          onChange={handleHotelPrefsChange}
                          className="mb-3"
                        />

                        <Form.Check
                          type="switch"
                          id="allowLateCheckOut"
                          name="allowLateCheckOut"
                          label="Allow late check-out"
                          checked={hotelPrefs.allowLateCheckOut}
                          onChange={handleHotelPrefsChange}
                          className="mb-3"
                        />

                        <Row>
                          <Col md={6}>
                            <Form.Group className="mb-3">
                              <Form.Label>Minimum Booking Days</Form.Label>
                              <Form.Control
                                type="number"
                                name="minBookingDays"
                                value={hotelPrefs.minBookingDays}
                                onChange={handleHotelPrefsChange}
                                min="1"
                              />
                            </Form.Group>
                          </Col>
                          <Col md={6}>
                            <Form.Group className="mb-3">
                              <Form.Label>Maximum Booking Days</Form.Label>
                              <Form.Control
                                type="number"
                                name="maxBookingDays"
                                value={hotelPrefs.maxBookingDays}
                                onChange={handleHotelPrefsChange}
                                min="1"
                              />
                            </Form.Group>
                          </Col>
                        </Row>

                        <Form.Group className="mb-3">
                          <Form.Label>Default Room Status</Form.Label>
                          <Form.Select
                            name="defaultRoomStatus"
                            value={hotelPrefs.defaultRoomStatus}
                            onChange={handleHotelPrefsChange}
                          >
                            <option value="Available">Available</option>
                            <option value="Maintenance">Maintenance</option>
                            <option value="Cleaning">Cleaning</option>
                          </Form.Select>
                        </Form.Group>

                        <Button 
                          onClick={() => handleSave('Hotel Preferences')}
                          style={{
                            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                            border: 'none',
                            borderRadius: '8px',
                            padding: '10px 24px',
                            fontWeight: '600',
                            transition: 'transform 0.3s ease, box-shadow 0.3s ease'
                          }}
                          onMouseOver={(e) => {
                            e.currentTarget.style.transform = 'translateY(-2px)';
                            e.currentTarget.style.boxShadow = '0 4px 8px rgba(26, 35, 126, 0.3)';
                          }}
                          onMouseOut={(e) => {
                            e.currentTarget.style.transform = 'translateY(0)';
                            e.currentTarget.style.boxShadow = 'none';
                          }}
                        >
                          <FaSave className="me-2" />
                          Save Preferences
                        </Button>
                      </Form>
                    </Col>
                  </Row>
                </Tab>

                {/* System Info Tab */}
                {user?.role === 'Administrator' && (
                  <Tab eventKey="system" title={<span><FaDatabase className="me-2" />System</span>}>
                    <Row>
                      <Col lg={8}>
                        <h5 className="mb-3" style={{
                          color: '#1a237e',
                          fontWeight: '600',
                          paddingBottom: '12px',
                          borderBottom: '2px solid rgba(26, 35, 126, 0.2)'
                        }}>System Information</h5>
                        
                        <ListGroup className="mb-4">
                          <ListGroup.Item>
                            <strong>System Version:</strong> HRGSMS v1.0.0
                          </ListGroup.Item>
                          <ListGroup.Item>
                            <strong>Database:</strong> Connected
                            <Badge bg="success" className="ms-2">Active</Badge>
                          </ListGroup.Item>
                          <ListGroup.Item>
                            <strong>Server Status:</strong> Online
                            <Badge bg="success" className="ms-2">Running</Badge>
                          </ListGroup.Item>
                          <ListGroup.Item>
                            <strong>Last Backup:</strong> October 14, 2025 - 02:00 AM
                          </ListGroup.Item>
                          <ListGroup.Item>
                            <strong>Total Users:</strong> 15
                          </ListGroup.Item>
                          <ListGroup.Item>
                            <strong>Active Sessions:</strong> 8
                          </ListGroup.Item>
                        </ListGroup>

                        <h6 className="mb-3" style={{ color: '#1a237e', fontWeight: '600' }}>System Actions</h6>
                        <div className="d-flex gap-2 flex-wrap">
                          <Button 
                            variant="outline-primary"
                            style={{
                              borderColor: '#1a237e',
                              color: '#1a237e',
                              borderRadius: '8px',
                              fontWeight: '500'
                            }}
                          >
                            <FaDatabase className="me-2" />
                            Backup Database
                          </Button>
                          <Button 
                            variant="outline-warning"
                            style={{
                              borderRadius: '8px',
                              fontWeight: '500'
                            }}
                          >
                            <FaUsers className="me-2" />
                            Manage Users
                          </Button>
                          <Button 
                            variant="outline-info"
                            style={{
                              borderRadius: '8px',
                              fontWeight: '500'
                            }}
                          >
                            View Logs
                          </Button>
                          <Button 
                            variant="outline-danger"
                            style={{
                              borderRadius: '8px',
                              fontWeight: '500'
                            }}
                          >
                            Clear Cache
                          </Button>
                        </div>
                      </Col>
                    </Row>
                  </Tab>
                )}
              </Tabs>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
};

export default Settings;
