import React from 'react';
import { Row, Col, Card } from 'react-bootstrap';
import { FaUsers, FaCalendarAlt, FaBed, FaConciergeBell, FaDollarSign, FaChartLine } from 'react-icons/fa';

const Dashboard = () => {
  const stats = [
    { title: 'Total Guests', value: '248', icon: FaUsers, color: 'primary' },
    { title: 'Active Reservations', value: '42', icon: FaCalendarAlt, color: 'success' },
    { title: 'Available Rooms', value: '18', icon: FaBed, color: 'info' },
    { title: 'Services Requested', value: '15', icon: FaConciergeBell, color: 'warning' },
    { title: 'Monthly Revenue', value: '$24,580', icon: FaDollarSign, color: 'success' },
    { title: 'Occupancy Rate', value: '78%', icon: FaChartLine, color: 'primary' }
  ];

  const rowStyle = {
    backgroundColor: '#AAA59F'
  };

  return (
    <div>
      <h2 className="mb-4">Dashboard</h2>
      
      <Row>
        {stats.map((stat, index) => {
          const IconComponent = stat.icon;
          return (
            <Col md={4} lg={2} key={index} className="mb-4">
              <Card className="card-custom h-100">
                <Card.Body className="text-center">
                  <IconComponent 
                    size={40} 
                    className={`text-${stat.color} mb-3`} 
                  />
                  <Card.Title className="h5">{stat.title}</Card.Title>
                  <Card.Text className="h3 text-primary mb-0">
                    {stat.value}
                  </Card.Text>
                </Card.Body>
              </Card>
            </Col>
          );
        })}
      </Row>

      <Row className="mt-4">
        <Col md={8}>
          <Card className="card-custom">
            <Card.Header>
              <h5 className="mb-0">Recent Reservations</h5>
            </Card.Header>
            <Card.Body>
              <div className="table-container">
                <table className="table table-hover mb-0">
                  <thead className="table-light">
                    <tr>
                      <th>Guest Name</th>
                      <th>Room</th>
                      <th>Check-in</th>
                      <th>Check-out</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr style={rowStyle}>
                      <td>John Doe</td>
                      <td>101</td>
                      <td>2025-09-15</td>
                      <td>2025-09-18</td>
                      <td><span className="badge bg-success">Confirmed</span></td>
                    </tr>
                    <tr style={rowStyle}>
                      <td>Jane Smith</td>
                      <td>205</td>
                      <td>2025-09-14</td>
                      <td>2025-09-16</td>
                      <td><span className="badge bg-primary">Checked In</span></td>
                    </tr>
                    <tr style={rowStyle}>
                      <td>Mike Johnson</td>
                      <td>308</td>
                      <td>2025-09-16</td>
                      <td>2025-09-20</td>
                      <td><span className="badge bg-warning">Pending</span></td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </Card.Body>
          </Card>
        </Col>
        
        <Col md={4}>
          <Card className="card-custom">
            <Card.Header>
              <h5 className="mb-0">Quick Actions</h5>
            </Card.Header>
            <Card.Body>
              <div className="d-grid gap-2">
                <button className="btn btn-primary-custom">
                  <FaUsers className="me-2" />
                  Add New Guest
                </button>
                <button className="btn btn-success">
                  <FaCalendarAlt className="me-2" />
                  New Reservation
                </button>
                <button className="btn btn-info">
                  <FaBed className="me-2" />
                  Room Status
                </button>
                <button className="btn btn-warning">
                  <FaConciergeBell className="me-2" />
                  Service Request
                </button>
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default Dashboard;