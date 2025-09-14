import React, { useState } from 'react';
import { Row, Col, Card, Button, Modal, Form, Table, InputGroup } from 'react-bootstrap';
import { FaPlus, FaEdit, FaTrash, FaSearch } from 'react-icons/fa';

const Guests = () => {
  const [showModal, setShowModal] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedGuest, setSelectedGuest] = useState(null);

  // Sample guest data
  const [guests, setGuests] = useState([
    {
      id: 1,
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@email.com',
      phone: '+1-555-0123',
      nationality: 'American',
      idNumber: 'P123456789',
      checkInDate: '2025-09-14',
      status: 'Checked In'
    },
    {
      id: 2,
      firstName: 'Jane',
      lastName: 'Smith',
      email: 'jane.smith@email.com',
      phone: '+1-555-0456',
      nationality: 'Canadian',
      idNumber: 'C987654321',
      checkInDate: '2025-09-13',
      status: 'Checked Out'
    },
    {
      id: 3,
      firstName: 'Mike',
      lastName: 'Johnson',
      email: 'mike.johnson@email.com',
      phone: '+1-555-0789',
      nationality: 'British',
      idNumber: 'B456789123',
      checkInDate: '2025-09-15',
      status: 'Reserved'
    }
  ]);

  const handleShowModal = (guest = null) => {
    setSelectedGuest(guest);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedGuest(null);
  };

  const filteredGuests = guests.filter(guest =>
    `${guest.firstName} ${guest.lastName}`.toLowerCase().includes(searchTerm.toLowerCase()) ||
    guest.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    guest.phone.includes(searchTerm)
  );

  const getStatusBadge = (status) => {
    const statusClasses = {
      'Checked In': 'bg-success',
      'Checked Out': 'bg-secondary',
      'Reserved': 'bg-primary'
    };
    return <span className={`badge ${statusClasses[status]}`}>{status}</span>;
  };

  return (
    <div>
      <Row className="mb-4">
        <Col>
          <h2>Guest Management</h2>
        </Col>
        <Col xs="auto">
          <Button 
            variant="primary" 
            onClick={() => handleShowModal()}
            className="btn-primary-custom"
          >
            <FaPlus className="me-2" />
            Add New Guest
          </Button>
        </Col>
      </Row>

      <Card className="card-custom">
        <Card.Header>
          <Row className="align-items-center">
            <Col>
              <h5 className="mb-0">Guest List</h5>
            </Col>
            <Col xs="auto">
              <InputGroup>
                <InputGroup.Text>
                  <FaSearch />
                </InputGroup.Text>
                <Form.Control
                  type="text"
                  placeholder="Search guests..."
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
                  <th>Name</th>
                  <th>Email</th>
                  <th>Phone</th>
                  <th>Nationality</th>
                  <th>ID Number</th>
                  <th>Check-in Date</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredGuests.map((guest) => (
                  <tr key={guest.id}>
                    <td>{`${guest.firstName} ${guest.lastName}`}</td>
                    <td>{guest.email}</td>
                    <td>{guest.phone}</td>
                    <td>{guest.nationality}</td>
                    <td>{guest.idNumber}</td>
                    <td>{guest.checkInDate}</td>
                    <td>{getStatusBadge(guest.status)}</td>
                    <td>
                      <Button
                        variant="outline-primary"
                        size="sm"
                        className="me-2"
                        onClick={() => handleShowModal(guest)}
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

      {/* Add/Edit Guest Modal */}
      <Modal show={showModal} onHide={handleCloseModal} size="lg">
        <Modal.Header closeButton>
          <Modal.Title>
            {selectedGuest ? 'Edit Guest' : 'Add New Guest'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>First Name</Form.Label>
                  <Form.Control
                    type="text"
                    placeholder="Enter first name"
                    defaultValue={selectedGuest?.firstName || ''}
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Last Name</Form.Label>
                  <Form.Control
                    type="text"
                    placeholder="Enter last name"
                    defaultValue={selectedGuest?.lastName || ''}
                  />
                </Form.Group>
              </Col>
            </Row>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Email</Form.Label>
                  <Form.Control
                    type="email"
                    placeholder="Enter email"
                    defaultValue={selectedGuest?.email || ''}
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Phone</Form.Label>
                  <Form.Control
                    type="tel"
                    placeholder="Enter phone number"
                    defaultValue={selectedGuest?.phone || ''}
                  />
                </Form.Group>
              </Col>
            </Row>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Nationality</Form.Label>
                  <Form.Control
                    type="text"
                    placeholder="Enter nationality"
                    defaultValue={selectedGuest?.nationality || ''}
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>ID Number</Form.Label>
                  <Form.Control
                    type="text"
                    placeholder="Enter ID number"
                    defaultValue={selectedGuest?.idNumber || ''}
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
            {selectedGuest ? 'Update Guest' : 'Add Guest'}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default Guests;