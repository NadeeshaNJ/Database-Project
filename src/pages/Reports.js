import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Form, Spinner, Table, Badge } from 'react-bootstrap';
import { FaChartBar, FaDollarSign, FaUsers, FaBed, FaCalendarAlt } from 'react-icons/fa';
import { apiUrl } from '../utils/api';
import { useBranch } from '../context/BranchContext';

const Reports = () => {
  const { selectedBranchId } = useBranch();
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
  }, [selectedBranchId]);

  useEffect(() => {
    if (reportType) {
      fetchReport();
    }
  }, [reportType, selectedBranchId]);

  const fetchDashboardSummary = async () => {
    try {
      let url = '/api/reports/dashboard-summary';
      if (selectedBranchId !== 'All') {
        url += `?branch_id=${selectedBranchId}`;
      }
      const response = await fetch(apiUrl(url));
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
      if (selectedBranchId !== 'All') params.append('branch_id', selectedBranchId);

      console.log('📊 Generating report:', {
        type: reportType,
        startDate,
        endDate,
        branchId: selectedBranchId,
        groupBy
      });

      switch (reportType) {
        case 'revenue':
          params.append('group_by', groupBy);
          url = `/api/reports/revenue?${params}`;
          console.log('📍 Fetching revenue report:', apiUrl(url));
          const revResponse = await fetch(apiUrl(url));
          const revData = await revResponse.json();
          console.log('✅ Revenue Report Response:', revData);
          if (revData.success) setRevenueReport(revData.data);
          else console.error('❌ Revenue Report Error:', revData);
          break;

        case 'occupancy':
          url = `/api/reports/occupancy?${params}`;
          console.log('📍 Fetching occupancy report:', apiUrl(url));
          const occResponse = await fetch(apiUrl(url));
          const occData = await occResponse.json();
          console.log('✅ Occupancy Report Response:', occData);
          if (occData.success) setOccupancyReport(occData.data);
          else console.error('❌ Occupancy Report Error:', occData);
          break;

        case 'service':
          url = `/api/reports/service-usage?${params}`;
          console.log('📍 Fetching service usage report:', apiUrl(url));
          const svcResponse = await fetch(apiUrl(url));
          const svcData = await svcResponse.json();
          console.log('✅ Service Usage Report Response:', svcData);
          if (svcData.success) setServiceReport(svcData.data);
          else console.error('❌ Service Usage Report Error:', svcData);
          break;

        case 'payment':
          url = `/api/reports/payment-methods?${params}`;
          console.log('📍 Fetching payment methods report:', apiUrl(url));
          const payResponse = await fetch(apiUrl(url));
          const payData = await payResponse.json();
          console.log('✅ Payment Methods Report Response:', payData);
          if (payData.success) setPaymentMethodReport(payData.data);
          else console.error('❌ Payment Methods Report Error:', payData);
          break;

        default:
          break;
      }
    } catch (error) {
      console.error('❌ Error fetching report:', error);
      alert('Failed to generate report. Check console for details.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      {/* Page Header */}
      <Row className="mb-4">
        <Col>
          <div className="page-header" style={{
            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
            padding: '2rem',
            borderRadius: '1rem',
            boxShadow: '0 4px 15px rgba(0,0,0,0.1)',
            color: 'white'
          }}>
            <h1 style={{ fontSize: '2.5rem', fontWeight: 'bold', marginBottom: '8px' }}><FaChartBar className="me-2" />
              Reports & Analytics
            </h1>
            <p style={{ marginBottom: 0, color: 'rgba(255, 255, 255, 0.9)' }}>Comprehensive business insights and performance metrics</p>
          </div>
        </Col>
      </Row>

      {/* Dashboard Summary */}
      {dashboardData && (
        <Row className="mb-4">
          <Col md={3}>
            <Card className="text-center" style={{
              background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
              border: 'none',
              borderRadius: '1rem',
              boxShadow: '0 4px 15px rgba(26, 35, 126, 0.3)',
              transition: 'transform 0.3s ease, box-shadow 0.3s ease',
              color: 'white'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-5px)';
              e.currentTarget.style.boxShadow = '0 8px 25px rgba(26, 35, 126, 0.4)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = '0 4px 15px rgba(26, 35, 126, 0.3)';
            }}>
              <Card.Body>
                <FaCalendarAlt size={30} style={{ color: 'white' }} className="mb-2" />
                <h4 style={{ color: 'white', fontWeight: '700' }}>{dashboardData.today.today_checkins}</h4>
                <p className="mb-0" style={{ color: 'rgba(255, 255, 255, 0.9)' }}>Today's Check-ins</p>
              </Card.Body>
            </Card>
          </Col>
          <Col md={3}>
            <Card className="text-center" style={{
              background: 'linear-gradient(135deg, #f57c00 0%, #ff9800 100%)',
              border: 'none',
              borderRadius: '1rem',
              boxShadow: '0 4px 15px rgba(245, 124, 0, 0.3)',
              transition: 'transform 0.3s ease, box-shadow 0.3s ease',
              color: 'white'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-5px)';
              e.currentTarget.style.boxShadow = '0 8px 25px rgba(245, 124, 0, 0.4)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = '0 4px 15px rgba(245, 124, 0, 0.3)';
            }}>
              <Card.Body>
                <FaCalendarAlt size={30} style={{ color: 'white' }} className="mb-2" />
                <h4 style={{ color: 'white', fontWeight: '700' }}>{dashboardData.today.today_checkouts}</h4>
                <p className="mb-0" style={{ color: 'rgba(255, 255, 255, 0.9)' }}>Today's Check-outs</p>
              </Card.Body>
            </Card>
          </Col>
          <Col md={3}>
            <Card className="text-center" style={{
              background: 'linear-gradient(135deg, #388e3c 0%, #4caf50 100%)',
              border: 'none',
              borderRadius: '1rem',
              boxShadow: '0 4px 15px rgba(56, 142, 60, 0.3)',
              transition: 'transform 0.3s ease, box-shadow 0.3s ease',
              color: 'white'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-5px)';
              e.currentTarget.style.boxShadow = '0 8px 25px rgba(56, 142, 60, 0.4)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = '0 4px 15px rgba(56, 142, 60, 0.3)';
            }}>
              <Card.Body>
                <FaUsers size={30} style={{ color: 'white' }} className="mb-2" />
                <h4 style={{ color: 'white', fontWeight: '700' }}>{dashboardData.today.current_guests}</h4>
                <p className="mb-0" style={{ color: 'rgba(255, 255, 255, 0.9)' }}>Current Guests</p>
              </Card.Body>
            </Card>
          </Col>
          <Col md={3}>
            <Card className="text-center" style={{
              background: 'linear-gradient(135deg, #0288d1 0%, #03a9f4 100%)',
              border: 'none',
              borderRadius: '1rem',
              boxShadow: '0 4px 15px rgba(2, 136, 209, 0.3)',
              transition: 'transform 0.3s ease, box-shadow 0.3s ease',
              color: 'white'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-5px)';
              e.currentTarget.style.boxShadow = '0 8px 25px rgba(2, 136, 209, 0.4)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = '0 4px 15px rgba(2, 136, 209, 0.3)';
            }}>
              <Card.Body>
                <FaBed size={30} style={{ color: 'white' }} className="mb-2" />
                <h4 style={{ color: 'white', fontWeight: '700' }}>{dashboardData.rooms.available_rooms}/{dashboardData.rooms.total_rooms}</h4>
                <p className="mb-0" style={{ color: 'rgba(255, 255, 255, 0.9)' }}>Available Rooms</p>
              </Card.Body>
            </Card>
          </Col>
        </Row>
      )}

      {/* Monthly Summary */}
      {dashboardData && (
        <Row className="mb-4">
          <Col md={6}>
            <Card style={{
              border: 'none',
              borderRadius: '1rem',
              boxShadow: '0 4px 15px rgba(0,0,0,0.1)'
            }}>
              <Card.Body>
                <h5 className="mb-3" style={{ color: '#1a237e', fontWeight: '700' }}>
                  <FaDollarSign className="me-2" style={{ color: '#1976d2' }} />
                  Monthly Revenue
                </h5>
                <h2 className="text-success mb-0" style={{ fontWeight: '700' }}>
                  Rs {parseFloat(dashboardData.monthly.monthly_revenue).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                </h2>
                <p className="text-muted">From {dashboardData.monthly.monthly_bookings} bookings this month</p>
              </Card.Body>
            </Card>
          </Col>
          <Col md={6}>
            <Card style={{
              border: 'none',
              borderRadius: '1rem',
              boxShadow: '0 4px 15px rgba(0,0,0,0.1)'
            }}>
              <Card.Body>
                <h5 className="mb-3" style={{ color: '#1a237e', fontWeight: '700' }}>
                  <FaBed className="me-2" style={{ color: '#1976d2' }} />
                  Room Status
                </h5>
                <div className="d-flex justify-content-between">
                  <div>
                    <Badge bg="success" className="me-2">Available: {dashboardData.rooms.available_rooms}</Badge>
                    <Badge style={{ background: '#1976d2' }} className="me-2">Occupied: {dashboardData.rooms.occupied_rooms}</Badge>
                    <Badge bg="warning">Maintenance: {dashboardData.rooms.maintenance_rooms}</Badge>
                  </div>
                </div>
              </Card.Body>
            </Card>
          </Col>
        </Row>
      )}

      {/* Report Generation */}
      <Card className="mb-4" style={{
        border: 'none',
        borderRadius: '1rem',
        boxShadow: '0 4px 15px rgba(0,0,0,0.1)'
      }}>
        <Card.Header style={{
          background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
          borderBottom: 'none',
          borderRadius: '1rem 1rem 0 0',
          padding: '1.5rem'
        }}>
          <h5 className="mb-0" style={{ color: 'white', fontWeight: '700' }}>
            <FaChartBar className="me-2" />
            Generate Report
          </h5>
        </Card.Header>
        <Card.Body>
          <Row>
            <Col md={2}>
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

            <Col md={1} className="d-flex align-items-end">
              <button 
                className="btn mb-3" 
                onClick={fetchReport}
                style={{
                  background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                  color: 'white',
                  border: 'none',
                  fontWeight: '600',
                  padding: '0.5rem 1.5rem',
                  borderRadius: '0.5rem',
                  boxShadow: '0 4px 10px rgba(26, 35, 126, 0.3)',
                  transition: 'all 0.3s ease'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.transform = 'translateY(-2px)';
                  e.currentTarget.style.boxShadow = '0 6px 15px rgba(25, 118, 210, 0.4)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.transform = 'translateY(0)';
                  e.currentTarget.style.boxShadow = '0 4px 10px rgba(26, 35, 126, 0.3)';
                }}
              >
                Generate
              </button>
            </Col>
          </Row>
        </Card.Body>
      </Card>

      {/* Report Display */}
      {loading ? (
        <div className="text-center py-5">
          <Spinner animation="border" style={{ color: '#1976d2', width: '3rem', height: '3rem' }} />
          <p className="mt-3" style={{ color: '#1976d2' }}>Generating report...</p>
        </div>
      ) : (
        <>
          {/* Revenue Report */}
          {reportType === 'revenue' && revenueReport && (
            <Card style={{
              border: 'none',
              borderRadius: '1rem',
              boxShadow: '0 4px 15px rgba(0,0,0,0.1)'
            }}>
              <Card.Header style={{
                background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                borderBottom: 'none',
                borderRadius: '1rem 1rem 0 0',
                padding: '1.5rem',
                color: 'white'
              }}>
                <h5 className="mb-0" style={{ fontWeight: '700' }}>Revenue Report</h5>
                <p className="mb-0" style={{ color: 'rgba(255, 255, 255, 0.9)' }}>Total Revenue: Rs {revenueReport.summary.totalRevenue} | Bookings: {revenueReport.summary.totalBookings} | Transactions: {revenueReport.summary.totalTransactions}</p>
              </Card.Header>
              <Card.Body>
                {revenueReport.report && revenueReport.report.length > 0 ? (
                  <Table responsive hover>
                    <thead style={{
                      background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)'
                    }}>
                      <tr>
                        <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Period</th>
                        <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Total Bookings</th>
                        <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Transactions</th>
                        <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Total Revenue (Rs)</th>
                        <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Avg Transaction (Rs)</th>
                        <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Card (Rs)</th>
                        <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Cash (Rs)</th>
                        <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Online (Rs)</th>
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
                ) : (
                  <div className="text-center py-4 text-muted">
                    No revenue data found for the selected period. Try adjusting the date range.
                  </div>
                )}
              </Card.Body>
            </Card>
          )}

          {/* Occupancy Report */}
          {reportType === 'occupancy' && occupancyReport && (
            <Card style={{
              border: 'none',
              borderRadius: '1rem',
              boxShadow: '0 4px 15px rgba(0,0,0,0.1)'
            }}>
              <Card.Header style={{
                background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                borderBottom: 'none',
                borderRadius: '1rem 1rem 0 0',
                padding: '1.5rem',
                color: 'white'
              }}>
                <h5 className="mb-0" style={{ fontWeight: '700' }}>Occupancy Report</h5>
                <p className="mb-0" style={{ color: 'rgba(255, 255, 255, 0.9)' }}>Average Occupancy: {occupancyReport.summary.averageOccupancy}%</p>
              </Card.Header>
              <Card.Body>
                <Table responsive hover>
                  <thead style={{
                    background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)'
                  }}>
                    <tr>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Branch</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Total Rooms</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Occupied Rooms</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Total Bookings</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Occupancy Rate</th>
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
            <Card style={{
              border: 'none',
              borderRadius: '1rem',
              boxShadow: '0 4px 15px rgba(0,0,0,0.1)'
            }}>
              <Card.Header style={{
                background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                borderBottom: 'none',
                borderRadius: '1rem 1rem 0 0',
                padding: '1.5rem',
                color: 'white'
              }}>
                <h5 className="mb-0" style={{ fontWeight: '700' }}>Service Usage Report</h5>
                <p className="mb-0" style={{ color: 'rgba(255, 255, 255, 0.9)' }}>Total Revenue: Rs {serviceReport.summary.totalRevenue} | Total Usages: {serviceReport.summary.totalUsages}</p>
              </Card.Header>
              <Card.Body>
                <Table responsive hover>
                  <thead style={{
                    background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)'
                  }}>
                    <tr>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Service</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Category</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Usage Count</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Total Quantity</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Total Revenue (Rs)</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Avg Unit Price (Rs)</th>
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
            <Card style={{
              border: 'none',
              borderRadius: '1rem',
              boxShadow: '0 4px 15px rgba(0,0,0,0.1)'
            }}>
              <Card.Header style={{
                background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                borderBottom: 'none',
                borderRadius: '1rem 1rem 0 0',
                padding: '1.5rem',
                color: 'white'
              }}>
                <h5 className="mb-0" style={{ fontWeight: '700' }}>Payment Methods Report</h5>
                <p className="mb-0" style={{ color: 'rgba(255, 255, 255, 0.9)' }}>Total: Rs {paymentMethodReport.summary.totalAmount} | Transactions: {paymentMethodReport.summary.totalTransactions}</p>
              </Card.Header>
              <Card.Body>
                <Table responsive hover>
                  <thead style={{
                    background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)'
                  }}>
                    <tr>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Payment Method</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Transaction Count</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Total Amount (Rs)</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Percentage</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Avg Amount (Rs)</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Min Amount (Rs)</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Max Amount (Rs)</th>
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
