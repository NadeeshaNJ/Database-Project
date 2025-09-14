import React, { useState } from 'react';
import { Row, Col, Card, Button, Form } from 'react-bootstrap';
import { FaChartBar, FaDownload, FaCalendarAlt, FaDollarSign, FaUsers, FaBed } from 'react-icons/fa';

const Reports = () => {
  const [reportType, setReportType] = useState('occupancy');
  const [dateRange, setDateRange] = useState('month');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  // Sample report data
  const occupancyData = {
    thisMonth: 78,
    lastMonth: 72,
    thisYear: 75,
    totalRooms: 50,
    occupiedRooms: 39
  };

  const revenueData = {
    thisMonth: 24580,
    lastMonth: 22340,
    thisYear: 284000,
    averageRate: 180,
    revpar: 140
  };

  const guestData = {
    totalGuests: 248,
    newGuests: 45,
    returningGuests: 203,
    averageStay: 2.8,
    satisfaction: 4.6
  };

  const generateReport = () => {
    // This would typically make an API call to generate the report
    console.log('Generating report:', { reportType, dateRange, startDate, endDate });
  };

  return (
    <div>
      <Row className="mb-4">
        <Col>
          <h2>Reports & Analytics</h2>
        </Col>
      </Row>

      {/* Report Generation Controls */}
      <Card className="card-custom mb-4">
        <Card.Header>
          <h5 className="mb-0">Generate Report</h5>
        </Card.Header>
        <Card.Body>
          <Row>
            <Col md={3}>
              <Form.Group className="mb-3">
                <Form.Label>Report Type</Form.Label>
                <Form.Select 
                  value={reportType} 
                  onChange={(e) => setReportType(e.target.value)}
                >
                  <option value="occupancy">Occupancy Report</option>
                  <option value="revenue">Revenue Report</option>
                  <option value="guest">Guest Report</option>
                  <option value="service">Service Report</option>
                  <option value="room">Room Status Report</option>
                </Form.Select>
              </Form.Group>
            </Col>
            <Col md={3}>
              <Form.Group className="mb-3">
                <Form.Label>Date Range</Form.Label>
                <Form.Select 
                  value={dateRange} 
                  onChange={(e) => setDateRange(e.target.value)}
                >
                  <option value="today">Today</option>
                  <option value="week">This Week</option>
                  <option value="month">This Month</option>
                  <option value="quarter">This Quarter</option>
                  <option value="year">This Year</option>
                  <option value="custom">Custom Range</option>
                </Form.Select>
              </Form.Group>
            </Col>
            {dateRange === 'custom' && (
              <>
                <Col md={2}>
                  <Form.Group className="mb-3">
                    <Form.Label>Start Date</Form.Label>
                    <Form.Control
                      type="date"
                      value={startDate}
                      onChange={(e) => setStartDate(e.target.value)}
                    />
                  </Form.Group>
                </Col>
                <Col md={2}>
                  <Form.Group className="mb-3">
                    <Form.Label>End Date</Form.Label>
                    <Form.Control
                      type="date"
                      value={endDate}
                      onChange={(e) => setEndDate(e.target.value)}
                    />
                  </Form.Group>
                </Col>
              </>
            )}
            <Col md={2} className="d-flex align-items-end">
              <div className="d-grid gap-2 w-100">
                <Button 
                  variant="primary" 
                  onClick={generateReport}
                  className="btn-primary-custom"
                >
                  <FaChartBar className="me-2" />
                  Generate
                </Button>
                <Button variant="outline-success" size="sm">
                  <FaDownload className="me-2" />
                  Export
                </Button>
              </div>
            </Col>
          </Row>
        </Card.Body>
      </Card>

      {/* Quick Stats Overview */}
      <Row className="mb-4">
        <Col md={4}>
          <Card className="card-custom">
            <Card.Header className="d-flex align-items-center">
              <FaBed className="me-2 text-primary" />
              <h6 className="mb-0">Occupancy Overview</h6>
            </Card.Header>
            <Card.Body>
              <div className="d-flex justify-content-between mb-2">
                <span>Current Occupancy:</span>
                <strong className="text-primary">{occupancyData.thisMonth}%</strong>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>Last Month:</span>
                <span>{occupancyData.lastMonth}%</span>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>Year Average:</span>
                <span>{occupancyData.thisYear}%</span>
              </div>
              <hr />
              <div className="d-flex justify-content-between">
                <span>Occupied Rooms:</span>
                <strong>{occupancyData.occupiedRooms}/{occupancyData.totalRooms}</strong>
              </div>
            </Card.Body>
          </Card>
        </Col>
        
        <Col md={4}>
          <Card className="card-custom">
            <Card.Header className="d-flex align-items-center">
              <FaDollarSign className="me-2 text-success" />
              <h6 className="mb-0">Revenue Overview</h6>
            </Card.Header>
            <Card.Body>
              <div className="d-flex justify-content-between mb-2">
                <span>This Month:</span>
                <strong className="text-success">${revenueData.thisMonth.toLocaleString()}</strong>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>Last Month:</span>
                <span>${revenueData.lastMonth.toLocaleString()}</span>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>Year Total:</span>
                <span>${revenueData.thisYear.toLocaleString()}</span>
              </div>
              <hr />
              <div className="d-flex justify-content-between mb-2">
                <span>Avg. Daily Rate:</span>
                <span>${revenueData.averageRate}</span>
              </div>
              <div className="d-flex justify-content-between">
                <span>RevPAR:</span>
                <span>${revenueData.revpar}</span>
              </div>
            </Card.Body>
          </Card>
        </Col>
        
        <Col md={4}>
          <Card className="card-custom">
            <Card.Header className="d-flex align-items-center">
              <FaUsers className="me-2 text-info" />
              <h6 className="mb-0">Guest Overview</h6>
            </Card.Header>
            <Card.Body>
              <div className="d-flex justify-content-between mb-2">
                <span>Total Guests:</span>
                <strong className="text-info">{guestData.totalGuests}</strong>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>New Guests:</span>
                <span>{guestData.newGuests}</span>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>Returning Guests:</span>
                <span>{guestData.returningGuests}</span>
              </div>
              <hr />
              <div className="d-flex justify-content-between mb-2">
                <span>Avg. Stay:</span>
                <span>{guestData.averageStay} nights</span>
              </div>
              <div className="d-flex justify-content-between">
                <span>Satisfaction:</span>
                <span>{guestData.satisfaction}/5.0 ⭐</span>
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Recent Activity Summary */}
      <Card className="card-custom">
        <Card.Header>
          <h5 className="mb-0">Recent Activity Summary</h5>
        </Card.Header>
        <Card.Body>
          <Row>
            <Col md={6}>
              <h6>Today's Activities</h6>
              <ul className="list-unstyled">
                <li className="mb-2">
                  <FaCalendarAlt className="me-2 text-primary" />
                  5 Check-ins scheduled
                </li>
                <li className="mb-2">
                  <FaCalendarAlt className="me-2 text-warning" />
                  3 Check-outs pending
                </li>
                <li className="mb-2">
                  <FaBed className="me-2 text-info" />
                  7 Rooms being cleaned
                </li>
                <li className="mb-2">
                  <FaUsers className="me-2 text-success" />
                  12 Service requests completed
                </li>
              </ul>
            </Col>
            <Col md={6}>
              <h6>Performance Indicators</h6>
              <div className="mb-3">
                <div className="d-flex justify-content-between">
                  <span>Occupancy Rate</span>
                  <span>78%</span>
                </div>
                <div className="progress" style={{height: '6px'}}>
                  <div className="progress-bar bg-primary" style={{width: '78%'}}></div>
                </div>
              </div>
              <div className="mb-3">
                <div className="d-flex justify-content-between">
                  <span>Revenue Target</span>
                  <span>92%</span>
                </div>
                <div className="progress" style={{height: '6px'}}>
                  <div className="progress-bar bg-success" style={{width: '92%'}}></div>
                </div>
              </div>
              <div className="mb-3">
                <div className="d-flex justify-content-between">
                  <span>Guest Satisfaction</span>
                  <span>96%</span>
                </div>
                <div className="progress" style={{height: '6px'}}>
                  <div className="progress-bar bg-info" style={{width: '96%'}}></div>
                </div>
              </div>
            </Col>
          </Row>
        </Card.Body>
      </Card>
    </div>
  );
};

export default Reports;