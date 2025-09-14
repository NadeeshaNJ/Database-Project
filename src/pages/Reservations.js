import React, { useState } from 'react';
import { Row, Col, Card, Button, Modal, Form, Table, InputGroup } from 'react-bootstrap';
import { FaPlus, FaEdit, FaTrash, FaSearch, FaCalendarAlt } from 'react-icons/fa';

const Reservations = () => {
  const [showModal, setShowModal] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedReservation, setSelectedReservation] = useState(null);

  // Sample reservation data
  const [reservations, setReservations] = useState([
    {
      id: 1,
      guestName: 'John Doe',
      roomNumber: '101',
      roomType: 'Single',
      checkIn: '2025-09-15',
      checkOut: '2025-09-18',
      nights: 3,
      totalAmount: '$450',
      status: 'Confirmed'
    },
    {
      id: 2,
      guestName: 'Jane Smith',
      roomNumber: '205',
      roomType: 'Double',
      checkIn: '2025-09-14',
      checkOut: '2025-09-16',
      nights: 2,
      totalAmount: '$320',
      status: 'Checked In'
    },
    {
      id: 3,
      guestName: 'Mike Johnson',
      roomNumber: '308',
      roomType: 'Suite',
      checkIn: '2025-09-16',
      checkOut: '2025-09-20',
      nights: 4,
      totalAmount: '$800',
      status: 'Pending'
    }
  ]);

  const handleShowModal = (reservation = null) => {
    setSelectedReservation(reservation);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedReservation(null);
  };

  const filteredReservations = reservations.filter(reservation =>
    reservation.guestName.toLowerCase().includes(searchTerm.toLowerCase()) ||
    reservation.roomNumber.includes(searchTerm) ||
    reservation.roomType.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getStatusBadge = (status) => {
    const statusClasses = {
      'Confirmed': 'bg-success',
      'Checked In': 'bg-primary',
      'Checked Out': 'bg-secondary',
      'Pending': 'bg-warning',
      'Cancelled': 'bg-danger'
    };
    return <span className={`badge ${statusClasses[status]}`}>{status}</span>;
  };

  return (
    <div>
      <Row className="mb-4">
        <Col>
          <h2>Reservation Management</h2>
        </Col>
        <Col xs="auto">
          <Button 
            variant="primary" 
            onClick={() => handleShowModal()}
            className="btn-primary-custom"
          >
            <FaPlus className="me-2" />
            New Reservation
          </Button>
        </Col>
      </Row>

      <Row className="mb-4">
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-primary">24</h4>
              <p className="mb-0">Total Reservations</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-success">18</h4>
              <p className="mb-0">Confirmed</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-warning">4</h4>
              <p className="mb-0">Pending</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-info">2</h4>
              <p className="mb-0">Check-ins Today</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      <Card className="card-custom">
        <Card.Header>
          <Row className="align-items-center">
            <Col>
              <h5 className="mb-0">Reservation List</h5>
            </Col>
            <Col xs="auto">
              <InputGroup>
                <InputGroup.Text>
                  <FaSearch />
                </InputGroup.Text>
                <Form.Control
                  type="text"
                  placeholder="Search reservations..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="search-box"
                />
              </InputGroup>
            </Col>
          </Row>
        </Card.Header>
        <Card.Body className="p-0">
          <div className="table-container">
            <Table responsive hover className="mb-0">
              <thead className="table-light">
                <tr>
                  <th>Guest Name</th>
                  <th>Room</th>
                  <th>Room Type</th>
                  <th>Check-in</th>
                  <th>Check-out</th>
                  <th>Nights</th>
                  <th>Total Amount</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredReservations.map((reservation) => (
                  <tr key={reservation.id}>
                    <td>{reservation.guestName}</td>
                    <td>{reservation.roomNumber}</td>
                    <td>{reservation.roomType}</td>
                    <td>{reservation.checkIn}</td>
                    <td>{reservation.checkOut}</td>
                    <td>{reservation.nights}</td>
                    <td>{reservation.totalAmount}</td>
                    <td>{getStatusBadge(reservation.status)}</td>
                    <td>
                      <Button
                        variant="outline-primary"
                        size="sm"
                        className="me-2"
                        onClick={() => handleShowModal(reservation)}
                      >
                        <FaEdit />
                      </Button>
                      <Button variant="outline-danger" size="sm">
                        <FaTrash />
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </Table>
          </div>
        </Card.Body>
      </Card>

      {/* Add/Edit Reservation Modal */}
      <Modal show={showModal} onHide={handleCloseModal} size="lg">
        <Modal.Header closeButton>
          <Modal.Title>
            {selectedReservation ? 'Edit Reservation' : 'New Reservation'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Guest Name</Form.Label>
                  <Form.Select defaultValue={selectedReservation?.guestName || ''}>
                    <option value="">Select Guest</option>
                    <option value="John Doe">John Doe</option>
                    <option value="Jane Smith">Jane Smith</option>
                    <option value="Mike Johnson">Mike Johnson</option>
                  </Form.Select>
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Room Number</Form.Label>
                  <Form.Select defaultValue={selectedReservation?.roomNumber || ''}>
                    <option value="">Select Room</option>
                    <option value="101">101 - Single</option>
                    <option value="205">205 - Double</option>
                    <option value="308">308 - Suite</option>
                  </Form.Select>
                </Form.Group>
              </Col>
            </Row>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Check-in Date</Form.Label>
                  <Form.Control
                    type="date"
                    defaultValue={selectedReservation?.checkIn || ''}
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Check-out Date</Form.Label>
                  <Form.Control
                    type="date"
                    defaultValue={selectedReservation?.checkOut || ''}
                  />
                </Form.Group>
              </Col>
            </Row>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Status</Form.Label>
                  <Form.Select defaultValue={selectedReservation?.status || ''}>
                    <option value="Pending">Pending</option>
                    <option value="Confirmed">Confirmed</option>
                    <option value="Checked In">Checked In</option>
                    <option value="Checked Out">Checked Out</option>
                    <option value="Cancelled">Cancelled</option>
                  </Form.Select>
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Total Amount</Form.Label>
                  <Form.Control
                    type="text"
                    placeholder="Enter total amount"
                    defaultValue={selectedReservation?.totalAmount || ''}
                  />
                </Form.Group>
              </Col>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal}>
            Cancel
          </Button>
          <Button variant="primary" className="btn-primary-custom">
            {selectedReservation ? 'Update Reservation' : 'Create Reservation'}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default Reservations;