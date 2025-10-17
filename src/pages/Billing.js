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
    <div>
      <Row className="mb-4">
        <Col>
          <h2>Billing & Payments</h2>
        </Col>
      </Row>

      {/* Statistics */}
      <Row className="mb-4">
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-success">Rs {payments.reduce((sum, p) => sum + parseFloat(p.amount || 0), 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}</h4>
              <p className="mb-0">Total Payments</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-primary">{payments.length}</h4>
              <p className="mb-0">Payment Transactions</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-warning">Rs {adjustments.reduce((sum, a) => sum + parseFloat(a.amount || 0), 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}</h4>
              <p className="mb-0">Total Adjustments</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-info">{adjustments.length}</h4>
              <p className="mb-0">Adjustment Records</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Tabs */}
      <Card className="card-custom">
        <Card.Body>
          <Tabs activeKey={activeTab} onSelect={(k) => setActiveTab(k)} className="mb-3">
            
            {/* Payments Tab */}
            <Tab eventKey="payments" title="Payments">
              {loading ? (
                <div className="text-center py-5">
                  <Spinner animation="border" />
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
                              className="btn btn-sm btn-outline-primary"
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
        <Modal.Header closeButton>
          <Modal.Title>
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
              <Card className="mb-3">
                <Card.Header><strong>Charges Breakdown</strong></Card.Header>
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
                    <strong>Grand Total</strong>
                    <strong className="text-primary">Rs {selectedBilling.summary.grandTotal}</strong>
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
                  <ListGroup.Item className="d-flex justify-content-between bg-info text-white">
                    <strong>Balance</strong>
                    <strong>Rs {selectedBilling.summary.balance}</strong>
                  </ListGroup.Item>
                </ListGroup>
              </Card>

              {/* Payment History */}
              {selectedBilling.payments.length > 0 && (
                <Card className="mb-3">
                  <Card.Header><strong>Payment History</strong></Card.Header>
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
                <Card>
                  <Card.Header><strong>Services Used</strong></Card.Header>
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
