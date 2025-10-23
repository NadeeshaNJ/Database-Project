import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Table, Badge, Modal, Spinner, Tabs, Tab, ListGroup, Form } from 'react-bootstrap';
import { FaReceipt, FaEye, FaMoneyBillWave, FaCreditCard } from 'react-icons/fa';
import { apiUrl } from '../utils/api';
import { useBranch } from '../context/BranchContext';

const Billing = () => {
  const { selectedBranchId } = useBranch();
  const [activeTab, setActiveTab] = useState('payments');
  const [loading, setLoading] = useState(true);
  const [payments, setPayments] = useState([]);
  const [adjustments, setAdjustments] = useState([]);
  const [selectedBilling, setSelectedBilling] = useState(null);
  const [showModal, setShowModal] = useState(false);

  useEffect(() => {
    fetchPayments();
    fetchAdjustments();
  }, [selectedBranchId]);

  const fetchPayments = async () => {
    try {
      setLoading(true);
      let url = '/api/billing/payments?limit=1000';
      if (selectedBranchId !== 'All') {
        url += `&branch_id=${selectedBranchId}`;
      }
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      if (data.success && data.data && data.data.payments) {
        setPayments(data.data.payments);
      }
    } catch (error) {
      console.error('Error fetching payments:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchAdjustments = async () => {
    try {
      let url = '/api/billing/adjustments?limit=1000';
      if (selectedBranchId !== 'All') {
        url += `&branch_id=${selectedBranchId}`;
      }
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      if (data.success && data.data && data.data.adjustments) {
        setAdjustments(data.data.adjustments);
      }
    } catch (error) {
      console.error('Error fetching adjustments:', error);
    }
  };

  const fetchBillingSummary = async (bookingId) => {
    try {
      const response = await fetch(apiUrl(`/api/billing/summary/${bookingId}`));
      const data = await response.json();
      if (data.success) {
        setSelectedBilling(data.data);
        setShowModal(true);
      }
    } catch (error) {
      console.error('Error fetching billing summary:', error);
    }
  };

  const getPaymentMethodIcon = (method) => {
    switch (method) {
      case 'Card': return <FaCreditCard className="me-1" />;
      case 'Cash': return <FaMoneyBillWave className="me-1" />;
      case 'Online': return <FaCreditCard className="me-1" />;
      case 'BankTransfer': return <FaMoneyBillWave className="me-1" />;
      default: return null;
    }
  };

  return (
    <div style={{ backgroundColor: '#f8f9fa', minHeight: '100vh', padding: '20px' }}>
      {/* Page Header */}
      <div style={{
        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
        color: 'white',
        padding: '30px',
        borderRadius: '12px',
        marginBottom: '30px',
        boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
      }}>
        <h2 style={{ margin: 0, fontSize: '2rem', fontWeight: 'bold' }}>Billing & Payments</h2>
        <p style={{ marginBottom: 0, fontSize: '1.1rem', opacity: 0.9 }}>Manage payments, transactions, and billing adjustments</p>
      </div>

      {/* Statistics */}
      <Row className="mb-4">
        <Col md={3}>
          <Card style={{
            background: 'white',
            borderRadius: '12px',
            border: '1px solid #e2e8f0',
            boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
            transition: 'transform 0.3s ease'
          }}>
            <Card.Body className="text-center">
              <h4 style={{ color: '#28a745', fontWeight: 'bold', fontSize: '1.8rem' }}>Rs {payments.reduce((sum, p) => sum + parseFloat(p.amount || 0), 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}</h4>
              <p className="mb-0" style={{ color: '#666', fontWeight: '500' }}>Total Payments</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card style={{
            background: 'white',
            borderRadius: '12px',
            border: '1px solid #e2e8f0',
            boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
            transition: 'transform 0.3s ease'
          }}>
            <Card.Body className="text-center">
              <h4 style={{ color: '#1976d2', fontWeight: 'bold', fontSize: '1.8rem' }}>{payments.length}</h4>
              <p className="mb-0" style={{ color: '#666', fontWeight: '500' }}>Payment Transactions</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card style={{
            background: 'white',
            borderRadius: '12px',
            border: '1px solid #e2e8f0',
            boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
            transition: 'transform 0.3s ease'
          }}>
            <Card.Body className="text-center">
              <h4 style={{ color: '#f59e0b', fontWeight: 'bold', fontSize: '1.8rem' }}>Rs {adjustments.reduce((sum, a) => sum + parseFloat(a.amount || 0), 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}</h4>
              <p className="mb-0" style={{ color: '#666', fontWeight: '500' }}>Total Adjustments</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card style={{
            background: 'white',
            borderRadius: '12px',
            border: '1px solid #e2e8f0',
            boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
            transition: 'transform 0.3s ease'
          }}>
            <Card.Body className="text-center">
              <h4 style={{ color: '#0d47a1', fontWeight: 'bold', fontSize: '1.8rem' }}>{adjustments.length}</h4>
              <p className="mb-0" style={{ color: '#666', fontWeight: '500' }}>Adjustment Records</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Tabs */}
      <Card style={{
        background: 'white',
        borderRadius: '12px',
        border: '1px solid #e2e8f0',
        boxShadow: '0 2px 8px rgba(0,0,0,0.08)'
      }}>
        <Card.Body>
          <Tabs activeKey={activeTab} onSelect={(k) => setActiveTab(k)} className="mb-3">
            
            {/* Payments Tab */}
            <Tab eventKey="payments" title="Payments">
              {loading ? (
                <div className="text-center py-5">
                  <Spinner 
                    animation="border" 
                    style={{ 
                      color: '#1976d2',
                      width: '3rem',
                      height: '3rem',
                      borderWidth: '4px'
                    }} 
                  />
                  <p className="mt-3" style={{ color: '#0d47a1', fontSize: '1.1rem', fontWeight: '500' }}>Loading...</p>
                </div>
              ) : (
                <div className="table-container">
                  <Table responsive hover className="mb-0">
                    <thead className="table-light">
                      <tr>
                        <th>Payment ID</th>
                        <th>Booking ID</th>
                        <th>Guest Name</th>
                        <th>Room</th>
                        <th>Branch</th>
                        <th>Amount (Rs)</th>
                        <th>Method</th>
                        <th>Paid At</th>
                        <th>Status</th>
                        <th>Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      {payments.map((payment) => (
                        <tr key={payment.payment_id}>
                          <td><strong>#{payment.payment_id}</strong></td>
                          <td>BK{String(payment.booking_id).padStart(3, '0')}</td>
                          <td>{payment.guest_name}</td>
                          <td>{payment.room_number}</td>
                          <td>{payment.branch_name}</td>
                          <td className="text-end">
                            <strong>{parseFloat(payment.amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}</strong>
                          </td>
                          <td>
                            {getPaymentMethodIcon(payment.method)}
                            {payment.method}
                          </td>
                          <td>{new Date(payment.paid_at).toLocaleString()}</td>
                          <td>
                            <Badge bg={payment.booking_status === 'Checked-Out' ? 'success' : 'primary'}>
                              {payment.booking_status}
                            </Badge>
                          </td>
                          <td>
                            <button 
                              style={{
                                background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                                color: 'white',
                                border: 'none',
                                borderRadius: '6px',
                                padding: '6px 14px',
                                fontSize: '0.875rem',
                                fontWeight: '500',
                                cursor: 'pointer',
                                transition: 'all 0.3s ease'
                              }}
                              onMouseEnter={(e) => {
                                e.target.style.transform = 'translateY(-2px)';
                                e.target.style.boxShadow = '0 4px 8px rgba(25, 118, 210, 0.3)';
                              }}
                              onMouseLeave={(e) => {
                                e.target.style.transform = 'translateY(0)';
                                e.target.style.boxShadow = 'none';
                              }}
                              onClick={() => fetchBillingSummary(payment.booking_id)}
                            >
                              <FaEye /> View Bill
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </Table>
                </div>
              )}
            </Tab>

            {/* Adjustments Tab */}
            <Tab eventKey="adjustments" title="Payment Adjustments">
              <div className="table-container">
                <Table responsive hover className="mb-0">
                  <thead className="table-light">
                    <tr>
                      <th>Adjustment ID</th>
                      <th>Booking ID</th>
                      <th>Guest Name</th>
                      <th>Room</th>
                      <th>Type</th>
                      <th>Amount (Rs)</th>
                      <th>Reference Note</th>
                      <th>Date</th>
                    </tr>
                  </thead>
                  <tbody>
                    {adjustments.map((adjustment) => (
                      <tr key={adjustment.adjustment_id}>
                        <td><strong>#{adjustment.adjustment_id}</strong></td>
                        <td>BK{String(adjustment.booking_id).padStart(3, '0')}</td>
                        <td>{adjustment.guest_name}</td>
                        <td>{adjustment.room_number}</td>
                        <td>
                          <Badge bg={adjustment.type === 'refund' ? 'warning' : 'info'}>
                            {adjustment.type}
                          </Badge>
                        </td>
                        <td className="text-end">
                          {parseFloat(adjustment.amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                        </td>
                        <td>{adjustment.reference_note || '-'}</td>
                        <td>{new Date(adjustment.created_at).toLocaleString()}</td>
                      </tr>
                    ))}
                  </tbody>
                </Table>
              </div>
            </Tab>

          </Tabs>
        </Card.Body>
      </Card>

      {/* Billing Detail Modal */}
      <Modal show={showModal} onHide={() => setShowModal(false)} size="lg">
        <Modal.Header 
          closeButton
          style={{
            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
            color: 'white',
            borderBottom: '2px solid #1976d2'
          }}
        >
          <Modal.Title style={{ color: 'white', fontWeight: 'bold' }}>
            <FaReceipt className="me-2" />
            Billing Summary - Booking #{selectedBilling?.booking.booking_id}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {selectedBilling && (
            <>
              {/* Guest Info */}
              <Card className="mb-3">
                <Card.Body>
                  <Row>
                    <Col md={6}>
                      <p><strong>Guest:</strong> {selectedBilling.booking.guest_name}</p>
                      <p><strong>Email:</strong> {selectedBilling.booking.guest_email}</p>
                      <p><strong>Phone:</strong> {selectedBilling.booking.guest_phone}</p>
                    </Col>
                    <Col md={6}>
                      <p><strong>Room:</strong> {selectedBilling.booking.room_number} - {selectedBilling.booking.room_type}</p>
                      <p><strong>Branch:</strong> {selectedBilling.booking.branch_name}</p>
                      <p><strong>Dates:</strong> {new Date(selectedBilling.booking.check_in_date).toLocaleDateString()} to {new Date(selectedBilling.booking.check_out_date).toLocaleDateString()}</p>
                    </Col>
                  </Row>
                </Card.Body>
              </Card>

              {/* Charges Breakdown */}
              <Card className="mb-3" style={{ border: '1px solid #e2e8f0', borderRadius: '8px' }}>
                <Card.Header style={{
                  background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                  color: 'white',
                  fontWeight: 'bold',
                  borderBottom: '2px solid #1976d2'
                }}>
                  <strong>Charges Breakdown</strong>
                </Card.Header>
                <ListGroup variant="flush">
                  <ListGroup.Item className="d-flex justify-content-between">
                    <span>Room Charges ({selectedBilling.booking.nights} nights)</span>
                    <strong>Rs {selectedBilling.summary.roomCharges}</strong>
                  </ListGroup.Item>
                  <ListGroup.Item className="d-flex justify-content-between">
                    <span>Service Charges</span>
                    <strong>Rs {selectedBilling.summary.serviceCharges}</strong>
                  </ListGroup.Item>
                  <ListGroup.Item className="d-flex justify-content-between">
                    <span>Tax ({selectedBilling.booking.tax_rate_percent}%)</span>
                    <strong>Rs {selectedBilling.summary.tax}</strong>
                  </ListGroup.Item>
                  {parseFloat(selectedBilling.summary.discount) > 0 && (
                    <ListGroup.Item className="d-flex justify-content-between text-success">
                      <span>Discount</span>
                      <strong>- Rs {selectedBilling.summary.discount}</strong>
                    </ListGroup.Item>
                  )}
                  {parseFloat(selectedBilling.summary.lateFee) > 0 && (
                    <ListGroup.Item className="d-flex justify-content-between text-danger">
                      <span>Late Fee</span>
                      <strong>+ Rs {selectedBilling.summary.lateFee}</strong>
                    </ListGroup.Item>
                  )}
                  <ListGroup.Item className="d-flex justify-content-between bg-light">
                    <strong style={{ color: '#1a237e' }}>Grand Total</strong>
                    <strong style={{ color: '#1976d2', fontSize: '1.2rem' }}>Rs {selectedBilling.summary.grandTotal}</strong>
                  </ListGroup.Item>
                  <ListGroup.Item className="d-flex justify-content-between">
                    <span>Total Paid</span>
                    <strong className="text-success">Rs {selectedBilling.summary.totalPaid}</strong>
                  </ListGroup.Item>
                  {parseFloat(selectedBilling.summary.refunds) > 0 && (
                    <ListGroup.Item className="d-flex justify-content-between text-warning">
                      <span>Refunds</span>
                      <strong>Rs {selectedBilling.summary.refunds}</strong>
                    </ListGroup.Item>
                  )}
                  <ListGroup.Item className="d-flex justify-content-between" style={{ background: '#e3f2fd' }}>
                    <strong style={{ color: '#1a237e' }}>Balance</strong>
                    <strong style={{ color: '#0d47a1', fontSize: '1.2rem' }}>Rs {selectedBilling.summary.balance}</strong>
                  </ListGroup.Item>
                </ListGroup>
              </Card>

              {/* Payment History */}
              {selectedBilling.payments.length > 0 && (
                <Card className="mb-3" style={{ border: '1px solid #e2e8f0', borderRadius: '8px' }}>
                  <Card.Header style={{
                    background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                    color: 'white',
                    fontWeight: 'bold',
                    borderBottom: '2px solid #1976d2'
                  }}>
                    <strong>Payment History</strong>
                  </Card.Header>
                  <Card.Body>
                    <Table size="sm" responsive>
                      <thead>
                        <tr>
                          <th>Date</th>
                          <th>Amount</th>
                          <th>Method</th>
                        </tr>
                      </thead>
                      <tbody>
                        {selectedBilling.payments.map((payment) => (
                          <tr key={payment.payment_id}>
                            <td>{new Date(payment.paid_at).toLocaleString()}</td>
                            <td>Rs {parseFloat(payment.amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}</td>
                            <td>{payment.method}</td>
                          </tr>
                        ))}
                      </tbody>
                    </Table>
                  </Card.Body>
                </Card>
              )}

              {/* Services Used */}
              {selectedBilling.services.length > 0 && (
                <Card style={{ border: '1px solid #e2e8f0', borderRadius: '8px' }}>
                  <Card.Header style={{
                    background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                    color: 'white',
                    fontWeight: 'bold',
                    borderBottom: '2px solid #1976d2'
                  }}>
                    <strong>Services Used</strong>
                  </Card.Header>
                  <Card.Body>
                    <Table size="sm" responsive>
                      <thead>
                        <tr>
                          <th>Service</th>
                          <th>Date</th>
                          <th>Qty</th>
                          <th>Unit Price</th>
                          <th>Total</th>
                        </tr>
                      </thead>
                      <tbody>
                        {selectedBilling.services.map((service) => (
                          <tr key={service.service_usage_id}>
                            <td>{service.service_name}</td>
                            <td>{new Date(service.used_on).toLocaleDateString()}</td>
                            <td>{service.qty}</td>
                            <td>Rs {parseFloat(service.unit_price_at_use).toFixed(2)}</td>
                            <td>Rs {parseFloat(service.total_price).toFixed(2)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </Table>
                  </Card.Body>
                </Card>
              )}
            </>
          )}
        </Modal.Body>
      </Modal>
    </div>
  );
};

export default Billing;
