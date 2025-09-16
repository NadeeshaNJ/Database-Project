import React, { useState, useEffect } from 'react';
import { Container, Row, Col, Card, Button, Table, Badge, Modal, Form, Alert, ListGroup } from 'react-bootstrap';
import { FaReceipt, FaPlus, FaEye, FaPrint, FaMoneyBillWave, FaCreditCard, FaExclamationTriangle } from 'react-icons/fa';

const Billing = () => {
  const [bills, setBills] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [selectedBill, setSelectedBill] = useState(null);
  const [modalType, setModalType] = useState('view');

  // Sample billing data
  const sampleBills = [
    {
      id: 'BILL001',
      bookingId: 'BK001',
      guestName: 'John Smith',
      hotelBranch: 'SkyNest Colombo',
      roomNumber: '301',
      checkInDate: '2024-01-15',
      checkOutDate: '2024-01-18',
      nights: 3,
      roomCharges: {
        roomType: 'Suite',
        ratePerNight: 15000,
        totalNights: 3,
        subtotal: 45000
      },
      serviceCharges: [
        { service: 'Room Service', date: '2024-01-15', quantity: 2, rate: 2500, total: 5000 },
        { service: 'Spa Treatment', date: '2024-01-16', quantity: 1, rate: 8000, total: 8000 },
        { service: 'Minibar', date: '2024-01-17', quantity: 3, rate: 1200, total: 3600 }
      ],
      taxes: {
        serviceTax: 3348, // 6% on services
        governmentTax: 6164 // 10% on total
      },
      totalAmount: 71112,
      paidAmount: 71112,
      paymentHistory: [
        { date: '2024-01-10', amount: 45000, method: 'Credit Card', type: 'Advance Payment' },
        { date: '2024-01-18', amount: 26112, method: 'Credit Card', type: 'Final Payment' }
      ],
      status: 'Paid',
      generatedDate: '2024-01-18',
      dueDate: '2024-01-18'
    },
    {
      id: 'BILL002',
      bookingId: 'BK002',
      guestName: 'Sarah Johnson',
      hotelBranch: 'SkyNest Kandy',
      roomNumber: '205',
      checkInDate: '2024-01-20',
      checkOutDate: '2024-01-23',
      nights: 3,
      roomCharges: {
        roomType: 'Double',
        ratePerNight: 9000,
        totalNights: 3,
        subtotal: 27000
      },
      serviceCharges: [
        { service: 'Laundry', date: '2024-01-21', quantity: 1, rate: 1500, total: 1500 },
        { service: 'Room Service', date: '2024-01-22', quantity: 1, rate: 1800, total: 1800 }
      ],
      taxes: {
        serviceTax: 198, // 6% on services
        governmentTax: 3030 // 10% on total
      },
      totalAmount: 33528,
      paidAmount: 27000,
      paymentHistory: [
        { date: '2024-01-12', amount: 27000, method: 'Cash', type: 'Room Charges' }
      ],
      status: 'Partial',
      generatedDate: '2024-01-23',
      dueDate: '2024-01-25'
    },
    {
      id: 'BILL003',
      bookingId: 'BK003',
      guestName: 'Michael Brown',
      hotelBranch: 'SkyNest Galle',
      roomNumber: '102',
      checkInDate: '2024-01-25',
      checkOutDate: '2024-01-27',
      nights: 2,
      roomCharges: {
        roomType: 'Single',
        ratePerNight: 8000,
        totalNights: 2,
        subtotal: 16000
      },
      serviceCharges: [
        { service: 'Minibar', date: '2024-01-25', quantity: 2, rate: 800, total: 1600 }
      ],
      taxes: {
        serviceTax: 96, // 6% on services
        governmentTax: 1760 // 10% on total
      },
      totalAmount: 19456,
      paidAmount: 8000,
      paymentHistory: [
        { date: '2024-01-14', amount: 8000, method: 'Bank Transfer', type: 'Partial Payment' }
      ],
      status: 'Outstanding',
      generatedDate: '2024-01-27',
      dueDate: '2024-01-29'
    }
  ];

  useEffect(() => {
    setBills(sampleBills);
  }, []);

  const handleShowModal = (type, bill = null) => {
    setModalType(type);
    setSelectedBill(bill);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedBill(null);
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'Paid': return 'success';
      case 'Partial': return 'warning';
      case 'Outstanding': return 'danger';
      case 'Overdue': return 'dark';
      default: return 'secondary';
    }
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-LK', {
      style: 'currency',
      currency: 'LKR'
    }).format(amount);
  };

  const calculateServiceTotal = (serviceCharges) => {
    return serviceCharges.reduce((sum, service) => sum + service.total, 0);
  };

  const getOutstandingAmount = (bill) => {
    return bill.totalAmount - bill.paidAmount;
  };

  const totalRevenue = bills.reduce((sum, bill) => sum + bill.paidAmount, 0);
  const totalOutstanding = bills.reduce((sum, bill) => sum + getOutstandingAmount(bill), 0);
  const paidBills = bills.filter(bill => bill.status === 'Paid').length;
  const outstandingBills = bills.filter(bill => bill.status === 'Outstanding' || bill.status === 'Partial').length;

  return (
    <Container fluid className="py-4">
      <Row className="mb-4">
        <Col>
          <div className="d-flex justify-content-between align-items-center">
            <div>
              <h2 className="mb-1">Billing & Payments</h2>
              <p className="text-muted">Manage guest billing, payments, and outstanding balances</p>
            </div>
            <Button 
              variant="primary" 
              onClick={() => handleShowModal('add')}
              className="d-flex align-items-center"
            >
              <FaPlus className="me-2" />
              Generate Bill
            </Button>
          </div>
        </Col>
      </Row>

      {/* Billing Statistics */}
      <Row className="mb-4">
        <Col md={3}>
          <Card className="text-center h-100 border-success">
            <Card.Body>
              <FaMoneyBillWave className="text-success mb-2" size={24} />
              <h4 className="text-success">{formatCurrency(totalRevenue)}</h4>
              <p className="mb-0 text-muted">Total Revenue</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center h-100 border-danger">
            <Card.Body>
              <FaExclamationTriangle className="text-danger mb-2" size={24} />
              <h4 className="text-danger">{formatCurrency(totalOutstanding)}</h4>
              <p className="mb-0 text-muted">Outstanding</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center h-100 border-primary">
            <Card.Body>
              <FaReceipt className="text-primary mb-2" size={24} />
              <h4 className="text-primary">{paidBills}</h4>
              <p className="mb-0 text-muted">Paid Bills</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center h-100 border-warning">
            <Card.Body>
              <FaCreditCard className="text-warning mb-2" size={24} />
              <h4 className="text-warning">{outstandingBills}</h4>
              <p className="mb-0 text-muted">Pending Bills</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Outstanding Bills Alert */}
      {outstandingBills > 0 && (
        <Row className="mb-4">
          <Col>
            <Alert variant="warning" className="d-flex align-items-center">
              <FaExclamationTriangle className="me-2" />
              <div>
                <strong>Payment Alert:</strong> You have {outstandingBills} bills with outstanding payments totaling {formatCurrency(totalOutstanding)}.
              </div>
            </Alert>
          </Col>
        </Row>
      )}

      {/* Bills Table */}
      <Row>
        <Col>
          <Card>
            <Card.Header>
              <h5 className="mb-0">Bills & Invoices</h5>
            </Card.Header>
            <Card.Body>
              <Table responsive striped hover>
                <thead>
                  <tr>
                    <th>Bill ID</th>
                    <th>Guest</th>
                    <th>Hotel/Room</th>
                    <th>Stay Period</th>
                    <th>Room Charges</th>
                    <th>Service Charges</th>
                    <th>Total Amount</th>
                    <th>Paid</th>
                    <th>Outstanding</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {bills.map((bill) => (
                    <tr key={bill.id}>
                      <td>
                        <strong>{bill.id}</strong>
                        <br />
                        <small className="text-muted">{bill.bookingId}</small>
                      </td>
                      <td>
                        <strong>{bill.guestName}</strong>
                      </td>
                      <td>
                        <div>
                          <strong>{bill.hotelBranch}</strong>
                          <br />
                          <small>Room {bill.roomNumber}</small>
                        </div>
                      </td>
                      <td>
                        <div>
                          {new Date(bill.checkInDate).toLocaleDateString()} -
                          <br />
                          {new Date(bill.checkOutDate).toLocaleDateString()}
                          <br />
                          <small>({bill.nights} nights)</small>
                        </div>
                      </td>
                      <td>{formatCurrency(bill.roomCharges.subtotal)}</td>
                      <td>{formatCurrency(calculateServiceTotal(bill.serviceCharges))}</td>
                      <td>
                        <strong>{formatCurrency(bill.totalAmount)}</strong>
                      </td>
                      <td className="text-success">
                        {formatCurrency(bill.paidAmount)}
                      </td>
                      <td>
                        <span className={getOutstandingAmount(bill) > 0 ? 'text-danger' : 'text-success'}>
                          {formatCurrency(getOutstandingAmount(bill))}
                        </span>
                      </td>
                      <td>
                        <Badge bg={getStatusColor(bill.status)}>
                          {bill.status}
                        </Badge>
                      </td>
                      <td>
                        <div className="d-flex gap-1">
                          <Button
                            variant="outline-primary"
                            size="sm"
                            onClick={() => handleShowModal('view', bill)}
                            title="View Details"
                          >
                            <FaEye />
                          </Button>
                          <Button
                            variant="outline-secondary"
                            size="sm"
                            onClick={() => window.print()}
                            title="Print Bill"
                          >
                            <FaPrint />
                          </Button>
                          {getOutstandingAmount(bill) > 0 && (
                            <Button
                              variant="outline-success"
                              size="sm"
                              onClick={() => handleShowModal('payment', bill)}
                              title="Add Payment"
                            >
                              <FaMoneyBillWave />
                            </Button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Modal for Bill Details */}
      <Modal show={showModal} onHide={handleCloseModal} size="lg">
        <Modal.Header closeButton>
          <Modal.Title>
            {modalType === 'view' && 'Bill Details'}
            {modalType === 'payment' && 'Add Payment'}
            {modalType === 'add' && 'Generate New Bill'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {selectedBill && modalType === 'view' ? (
            <div>
              {/* Bill Header */}
              <div className="d-flex justify-content-between align-items-center mb-4">
                <div>
                  <h4>Invoice #{selectedBill.id}</h4>
                  <p className="mb-0">Booking: {selectedBill.bookingId}</p>
                </div>
                <Badge bg={getStatusColor(selectedBill.status)} className="fs-6">
                  {selectedBill.status}
                </Badge>
              </div>

              <Row>
                <Col md={6}>
                  <h6>Guest Information</h6>
                  <p><strong>{selectedBill.guestName}</strong></p>
                  <p>{selectedBill.hotelBranch}</p>
                  <p>Room {selectedBill.roomNumber}</p>
                </Col>
                <Col md={6}>
                  <h6>Bill Information</h6>
                  <p><strong>Generated:</strong> {new Date(selectedBill.generatedDate).toLocaleDateString()}</p>
                  <p><strong>Due Date:</strong> {new Date(selectedBill.dueDate).toLocaleDateString()}</p>
                  <p><strong>Stay Period:</strong> {new Date(selectedBill.checkInDate).toLocaleDateString()} - {new Date(selectedBill.checkOutDate).toLocaleDateString()}</p>
                </Col>
              </Row>

              <hr />

              {/* Room Charges */}
              <h6>Room Charges</h6>
              <Table bordered>
                <tbody>
                  <tr>
                    <td>{selectedBill.roomCharges.roomType} Room</td>
                    <td>{selectedBill.roomCharges.totalNights} nights</td>
                    <td>{formatCurrency(selectedBill.roomCharges.ratePerNight)}/night</td>
                    <td className="text-end"><strong>{formatCurrency(selectedBill.roomCharges.subtotal)}</strong></td>
                  </tr>
                </tbody>
              </Table>

              {/* Service Charges */}
              {selectedBill.serviceCharges.length > 0 && (
                <>
                  <h6>Service Charges</h6>
                  <Table bordered>
                    <thead>
                      <tr>
                        <th>Service</th>
                        <th>Date</th>
                        <th>Qty</th>
                        <th>Rate</th>
                        <th className="text-end">Total</th>
                      </tr>
                    </thead>
                    <tbody>
                      {selectedBill.serviceCharges.map((service, index) => (
                        <tr key={index}>
                          <td>{service.service}</td>
                          <td>{new Date(service.date).toLocaleDateString()}</td>
                          <td>{service.quantity}</td>
                          <td>{formatCurrency(service.rate)}</td>
                          <td className="text-end">{formatCurrency(service.total)}</td>
                        </tr>
                      ))}
                      <tr className="table-info">
                        <td colSpan="4"><strong>Service Charges Total</strong></td>
                        <td className="text-end"><strong>{formatCurrency(calculateServiceTotal(selectedBill.serviceCharges))}</strong></td>
                      </tr>
                    </tbody>
                  </Table>
                </>
              )}

              {/* Bill Summary */}
              <Table bordered>
                <tbody>
                  <tr>
                    <td><strong>Room Charges Subtotal</strong></td>
                    <td className="text-end">{formatCurrency(selectedBill.roomCharges.subtotal)}</td>
                  </tr>
                  <tr>
                    <td><strong>Service Charges Subtotal</strong></td>
                    <td className="text-end">{formatCurrency(calculateServiceTotal(selectedBill.serviceCharges))}</td>
                  </tr>
                  <tr>
                    <td>Service Tax (6%)</td>
                    <td className="text-end">{formatCurrency(selectedBill.taxes.serviceTax)}</td>
                  </tr>
                  <tr>
                    <td>Government Tax (10%)</td>
                    <td className="text-end">{formatCurrency(selectedBill.taxes.governmentTax)}</td>
                  </tr>
                  <tr className="table-warning">
                    <td><strong>Total Amount</strong></td>
                    <td className="text-end"><strong>{formatCurrency(selectedBill.totalAmount)}</strong></td>
                  </tr>
                  <tr className="table-success">
                    <td><strong>Amount Paid</strong></td>
                    <td className="text-end"><strong>{formatCurrency(selectedBill.paidAmount)}</strong></td>
                  </tr>
                  <tr className={getOutstandingAmount(selectedBill) > 0 ? 'table-danger' : 'table-success'}>
                    <td><strong>Outstanding Balance</strong></td>
                    <td className="text-end"><strong>{formatCurrency(getOutstandingAmount(selectedBill))}</strong></td>
                  </tr>
                </tbody>
              </Table>

              {/* Payment History */}
              {selectedBill.paymentHistory.length > 0 && (
                <>
                  <h6>Payment History</h6>
                  <ListGroup>
                    {selectedBill.paymentHistory.map((payment, index) => (
                      <ListGroup.Item key={index} className="d-flex justify-content-between align-items-center">
                        <div>
                          <strong>{payment.type}</strong>
                          <br />
                          <small className="text-muted">
                            {new Date(payment.date).toLocaleDateString()} • {payment.method}
                          </small>
                        </div>
                        <Badge bg="success" pill>
                          {formatCurrency(payment.amount)}
                        </Badge>
                      </ListGroup.Item>
                    ))}
                  </ListGroup>
                </>
              )}
            </div>
          ) : modalType === 'payment' && selectedBill ? (
            <Form>
              <Alert variant="info">
                <strong>Outstanding Balance:</strong> {formatCurrency(getOutstandingAmount(selectedBill))}
              </Alert>
              
              <Form.Group className="mb-3">
                <Form.Label>Payment Amount</Form.Label>
                <Form.Control
                  type="number"
                  max={getOutstandingAmount(selectedBill)}
                  placeholder="Enter payment amount"
                />
              </Form.Group>
              
              <Form.Group className="mb-3">
                <Form.Label>Payment Method</Form.Label>
                <Form.Select>
                  <option value="">Select payment method</option>
                  <option value="Cash">Cash</option>
                  <option value="Credit Card">Credit Card</option>
                  <option value="Bank Transfer">Bank Transfer</option>
                  <option value="Online Payment">Online Payment</option>
                </Form.Select>
              </Form.Group>
              
              <Form.Group className="mb-3">
                <Form.Label>Payment Date</Form.Label>
                <Form.Control
                  type="date"
                  defaultValue={new Date().toISOString().split('T')[0]}
                />
              </Form.Group>
              
              <Form.Group className="mb-3">
                <Form.Label>Notes</Form.Label>
                <Form.Control
                  as="textarea"
                  rows={2}
                  placeholder="Payment notes (optional)"
                />
              </Form.Group>
            </Form>
          ) : (
            <p>Generate new bill functionality would be implemented here.</p>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal}>
            Close
          </Button>
          {modalType === 'view' && (
            <Button variant="primary" onClick={() => window.print()}>
              <FaPrint className="me-2" />
              Print Bill
            </Button>
          )}
          {modalType === 'payment' && (
            <Button variant="success">
              <FaMoneyBillWave className="me-2" />
              Record Payment
            </Button>
          )}
        </Modal.Footer>
      </Modal>
    </Container>
  );
};

export default Billing;