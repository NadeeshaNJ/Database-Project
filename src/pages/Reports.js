import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Form, Spinner, Table, Badge } from 'react-bootstrap';
import { FaChartBar, FaDollarSign, FaUsers, FaBed, FaCalendarAlt } from 'react-icons/fa';
import { apiUrl } from '../utils/api';

const Reports = () => {
  const [reportType, setReportType] = useState('revenue');
  const [loading, setLoading] = useState(false);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [groupBy, setGroupBy] = useState('day');
  
  const [revenueReport, setRevenueReport] = useState(null);
  const [occupancyReport, setOccupancyReport] = useState(null);
  const [serviceReport, setServiceReport] = useState(null);
  const [paymentMethodReport, setPaymentMethodReport] = useState(null);
  const [dashboardData, setDashboardData] = useState(null);

  useEffect(() => {
    fetchDashboardSummary();
  }, []);

  useEffect(() => {
    if (reportType) {
      fetchReport();
    }
  }, [reportType]);

  const fetchDashboardSummary = async () => {
    try {
      const response = await fetch(apiUrl('/api/reports/dashboard-summary'));
      const data = await response.json();
      if (data.success) {
        setDashboardData(data.data);
      }
    } catch (error) {
      console.error('Error fetching dashboard:', error);
    }
  };

  const fetchReport = async () => {
    setLoading(true);
    try {
      let url = '';
      const params = new URLSearchParams();
      if (startDate) params.append('start_date', startDate);
      if (endDate) params.append('end_date', endDate);

      switch (reportType) {
        case 'revenue':
          params.append('group_by', groupBy);
          url = `/api/reports/revenue?${params}`;
          const revResponse = await fetch(apiUrl(url));
          const revData = await revResponse.json();
          if (revData.success) setRevenueReport(revData.data);
          break;

        case 'occupancy':
          url = `/api/reports/occupancy?${params}`;
          const occResponse = await fetch(apiUrl(url));
          const occData = await occResponse.json();
          if (occData.success) setOccupancyReport(occData.data);
          break;

        case 'service':
          url = `/api/reports/service-usage?${params}`;
          const svcResponse = await fetch(apiUrl(url));
          const svcData = await svcResponse.json();
          if (svcData.success) setServiceReport(svcData.data);
          break;

        case 'payment':
          url = `/api/reports/payment-methods?${params}`;
          const payResponse = await fetch(apiUrl(url));
          const payData = await payResponse.json();
          if (payData.success) setPaymentMethodReport(payData.data);
          break;

        default:
          break;
      }
    } catch (error) {
      console.error('Error fetching report:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <Row className="mb-4">
        <Col>
          <h2>Reports & Analytics</h2>
        </Col>
      </Row>

      {/* Dashboard Summary */}
      {dashboardData && (
        <Row className="mb-4">
          <Col md={3}>
            <Card className="card-custom text-center">
              <Card.Body>
                <FaCalendarAlt size={30} className="text-primary mb-2" />
                <h4 className="text-primary">{dashboardData.today.today_checkins}</h4>
                <p className="mb-0">Today's Check-ins</p>
              </Card.Body>
            </Card>
          </Col>
          <Col md={3}>
            <Card className="card-custom text-center">
              <Card.Body>
                <FaCalendarAlt size={30} className="text-warning mb-2" />
                <h4 className="text-warning">{dashboardData.today.today_checkouts}</h4>
                <p className="mb-0">Today's Check-outs</p>
              </Card.Body>
            </Card>
          </Col>
          <Col md={3}>
            <Card className="card-custom text-center">
              <Card.Body>
                <FaUsers size={30} className="text-success mb-2" />
                <h4 className="text-success">{dashboardData.today.current_guests}</h4>
                <p className="mb-0">Current Guests</p>
              </Card.Body>
            </Card>
          </Col>
          <Col md={3}>
            <Card className="card-custom text-center">
              <Card.Body>
                <FaBed size={30} className="text-info mb-2" />
                <h4 className="text-info">{dashboardData.rooms.available_rooms}/{dashboardData.rooms.total_rooms}</h4>
                <p className="mb-0">Available Rooms</p>
              </Card.Body>
            </Card>
          </Col>
        </Row>
      )}

      {/* Monthly Summary */}
      {dashboardData && (
        <Row className="mb-4">
          <Col md={6}>
            <Card className="card-custom">
              <Card.Body>
                <h5 className="mb-3"><FaDollarSign className="me-2" />Monthly Revenue</h5>
                <h2 className="text-success mb-0">
                  Rs {parseFloat(dashboardData.monthly.monthly_revenue).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                </h2>
                <p className="text-muted">From {dashboardData.monthly.monthly_bookings} bookings this month</p>
              </Card.Body>
            </Card>
          </Col>
          <Col md={6}>
            <Card className="card-custom">
              <Card.Body>
                <h5 className="mb-3"><FaBed className="me-2" />Room Status</h5>
                <div className="d-flex justify-content-between">
                  <div>
                    <Badge bg="success" className="me-2">Available: {dashboardData.rooms.available_rooms}</Badge>
                    <Badge bg="primary" className="me-2">Occupied: {dashboardData.rooms.occupied_rooms}</Badge>
                    <Badge bg="warning">Maintenance: {dashboardData.rooms.maintenance_rooms}</Badge>
                  </div>
                </div>
              </Card.Body>
            </Card>
          </Col>
        </Row>
      )}

      {/* Report Generation */}
      <Card className="card-custom mb-4">
        <Card.Header><h5 className="mb-0"><FaChartBar className="me-2" />Generate Report</h5></Card.Header>
        <Card.Body>
          <Row>
            <Col md={3}>
              <Form.Group className="mb-3">
                <Form.Label>Report Type</Form.Label>
                <Form.Select value={reportType} onChange={(e) => setReportType(e.target.value)}>
                  <option value="revenue">Revenue Report</option>
                  <option value="occupancy">Occupancy Report</option>
                  <option value="service">Service Usage Report</option>
                  <option value="payment">Payment Methods Report</option>
                </Form.Select>
              </Form.Group>
            </Col>

            {reportType === 'revenue' && (
              <Col md={2}>
                <Form.Group className="mb-3">
                  <Form.Label>Group By</Form.Label>
                  <Form.Select value={groupBy} onChange={(e) => setGroupBy(e.target.value)}>
                    <option value="day">Daily</option>
                    <option value="week">Weekly</option>
                    <option value="month">Monthly</option>
                  </Form.Select>
                </Form.Group>
              </Col>
            )}

            <Col md={3}>
              <Form.Group className="mb-3">
                <Form.Label>Start Date</Form.Label>
                <Form.Control 
                  type="date" 
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                />
              </Form.Group>
            </Col>

            <Col md={3}>
              <Form.Group className="mb-3">
                <Form.Label>End Date</Form.Label>
                <Form.Control 
                  type="date" 
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                />
              </Form.Group>
            </Col>

            <Col md={1} className="d-flex align-items-end">
              <button className="btn btn-primary mb-3" onClick={fetchReport}>
                Generate
              </button>
            </Col>
          </Row>
        </Card.Body>
      </Card>

      {/* Report Display */}
      {loading ? (
        <div className="text-center py-5">
          <Spinner animation="border" />
        </div>
      ) : (
        <>
          {/* Revenue Report */}
          {reportType === 'revenue' && revenueReport && (
            <Card className="card-custom">
              <Card.Header>
                <h5 className="mb-0">Revenue Report</h5>
                <p className="mb-0 text-muted">Total Revenue: Rs {revenueReport.summary.totalRevenue} | Bookings: {revenueReport.summary.totalBookings} | Transactions: {revenueReport.summary.totalTransactions}</p>
              </Card.Header>
              <Card.Body>
                <Table responsive hover>
                  <thead className="table-light">
                    <tr>
                      <th>Period</th>
                      <th>Total Bookings</th>
                      <th>Transactions</th>
                      <th>Total Revenue (Rs)</th>
                      <th>Avg Transaction (Rs)</th>
                      <th>Card (Rs)</th>
                      <th>Cash (Rs)</th>
                      <th>Online (Rs)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {revenueReport.report.map((row, idx) => (
                      <tr key={idx}>
                        <td>{new Date(row.period).toLocaleDateString()}</td>
                        <td>{row.total_bookings}</td>
                        <td>{row.total_transactions}</td>
                        <td className="text-end"><strong>{parseFloat(row.total_revenue).toLocaleString('en-US', { minimumFractionDigits: 2 })}</strong></td>
                        <td className="text-end">{parseFloat(row.avg_transaction).toLocaleString('en-US', { minimumFractionDigits: 2 })}</td>
                        <td className="text-end">{parseFloat(row.card_revenue).toLocaleString('en-US', { minimumFractionDigits: 2 })}</td>
                        <td className="text-end">{parseFloat(row.cash_revenue).toLocaleString('en-US', { minimumFractionDigits: 2 })}</td>
                        <td className="text-end">{parseFloat(row.online_revenue).toLocaleString('en-US', { minimumFractionDigits: 2 })}</td>
                      </tr>
                    ))}
                  </tbody>
                </Table>
              </Card.Body>
            </Card>
          )}

          {/* Occupancy Report */}
          {reportType === 'occupancy' && occupancyReport && (
            <Card className="card-custom">
              <Card.Header>
                <h5 className="mb-0">Occupancy Report</h5>
                <p className="mb-0 text-muted">Average Occupancy: {occupancyReport.summary.averageOccupancy}%</p>
              </Card.Header>
              <Card.Body>
                <Table responsive hover>
                  <thead className="table-light">
                    <tr>
                      <th>Branch</th>
                      <th>Total Rooms</th>
                      <th>Occupied Rooms</th>
                      <th>Total Bookings</th>
                      <th>Occupancy Rate</th>
                    </tr>
                  </thead>
                  <tbody>
                    {occupancyReport.occupancyReport.map((row) => (
                      <tr key={row.branch_id}>
                        <td><strong>{row.branch_name}</strong></td>
                        <td>{row.total_rooms}</td>
                        <td>{row.occupied_rooms}</td>
                        <td>{row.total_bookings}</td>
                        <td>
                          <Badge bg={parseFloat(row.occupancy_rate) > 80 ? 'success' : parseFloat(row.occupancy_rate) > 60 ? 'warning' : 'danger'}>
                            {row.occupancy_rate}%
                          </Badge>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </Table>
              </Card.Body>
            </Card>
          )}

          {/* Service Usage Report */}
          {reportType === 'service' && serviceReport && (
            <Card className="card-custom">
              <Card.Header>
                <h5 className="mb-0">Service Usage Report</h5>
                <p className="mb-0 text-muted">Total Revenue: Rs {serviceReport.summary.totalRevenue} | Total Usages: {serviceReport.summary.totalUsages}</p>
              </Card.Header>
              <Card.Body>
                <Table responsive hover>
                  <thead className="table-light">
                    <tr>
                      <th>Service</th>
                      <th>Category</th>
                      <th>Usage Count</th>
                      <th>Total Quantity</th>
                      <th>Total Revenue (Rs)</th>
                      <th>Avg Unit Price (Rs)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {serviceReport.serviceReport.map((row) => (
                      <tr key={row.service_id}>
                        <td><strong>{row.service_name}</strong></td>
                        <td><Badge bg="info">{row.category}</Badge></td>
                        <td>{row.usage_count}</td>
                        <td>{row.total_quantity}</td>
                        <td className="text-end"><strong>{parseFloat(row.total_revenue || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}</strong></td>
                        <td className="text-end">{parseFloat(row.avg_unit_price || 0).toFixed(2)}</td>
                      </tr>
                    ))}
                  </tbody>
                </Table>
              </Card.Body>
            </Card>
          )}

          {/* Payment Methods Report */}
          {reportType === 'payment' && paymentMethodReport && (
            <Card className="card-custom">
              <Card.Header>
                <h5 className="mb-0">Payment Methods Report</h5>
                <p className="mb-0 text-muted">Total: Rs {paymentMethodReport.summary.totalAmount} | Transactions: {paymentMethodReport.summary.totalTransactions}</p>
              </Card.Header>
              <Card.Body>
                <Table responsive hover>
                  <thead className="table-light">
                    <tr>
                      <th>Payment Method</th>
                      <th>Transaction Count</th>
                      <th>Total Amount (Rs)</th>
                      <th>Percentage</th>
                      <th>Avg Amount (Rs)</th>
                      <th>Min Amount (Rs)</th>
                      <th>Max Amount (Rs)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {paymentMethodReport.paymentMethodReport.map((row) => (
                      <tr key={row.method}>
                        <td><strong>{row.method}</strong></td>
                        <td>{row.transaction_count}</td>
                        <td className="text-end"><strong>{parseFloat(row.total_amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}</strong></td>
                        <td>
                          <Badge bg="primary">{row.percentage}%</Badge>
                        </td>
                        <td className="text-end">{parseFloat(row.avg_amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}</td>
                        <td className="text-end">{parseFloat(row.min_amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}</td>
                        <td className="text-end">{parseFloat(row.max_amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}</td>
                      </tr>
                    ))}
                  </tbody>
                </Table>
              </Card.Body>
            </Card>
          )}
        </>
      )}
    </div>
  );
};

export default Reports;
