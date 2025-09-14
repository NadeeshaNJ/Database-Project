import React, { useState } from 'react';
import { Row, Col, Card, Button, Modal, Form, Badge } from 'react-bootstrap';
import { FaPlus, FaEdit, FaBed, FaWifi, FaTv, FaSnowflake } from 'react-icons/fa';

const Rooms = () => {
  const [showModal, setShowModal] = useState(false);
  const [selectedRoom, setSelectedRoom] = useState(null);
  const [filterStatus, setFilterStatus] = useState('All');

  // Sample room data
  const [rooms, setRooms] = useState([
    {
      id: 1,
      number: '101',
      type: 'Single',
      floor: 1,
      price: 150,
      status: 'Available',
      amenities: ['WiFi', 'TV', 'AC'],
      description: 'Comfortable single room with modern amenities'
    },
    {
      id: 2,
      number: '102',
      type: 'Single',
      floor: 1,
      price: 150,
      status: 'Occupied',
      amenities: ['WiFi', 'TV', 'AC'],
      description: 'Comfortable single room with modern amenities'
    },
    {
      id: 3,
      number: '205',
      type: 'Double',
      floor: 2,
      price: 200,
      status: 'Available',
      amenities: ['WiFi', 'TV', 'AC', 'Mini Bar'],
      description: 'Spacious double room with city view'
    },
    {
      id: 4,
      number: '206',
      type: 'Double',
      floor: 2,
      price: 200,
      status: 'Maintenance',
      amenities: ['WiFi', 'TV', 'AC', 'Mini Bar'],
      description: 'Spacious double room with city view'
    },
    {
      id: 5,
      number: '308',
      type: 'Suite',
      floor: 3,
      price: 350,
      status: 'Available',
      amenities: ['WiFi', 'TV', 'AC', 'Mini Bar', 'Balcony', 'Jacuzzi'],
      description: 'Luxury suite with premium amenities and ocean view'
    },
    {
      id: 6,
      number: '309',
      type: 'Suite',
      floor: 3,
      price: 350,
      status: 'Reserved',
      amenities: ['WiFi', 'TV', 'AC', 'Mini Bar', 'Balcony', 'Jacuzzi'],
      description: 'Luxury suite with premium amenities and ocean view'
    }
  ]);

  const handleShowModal = (room = null) => {
    setSelectedRoom(room);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedRoom(null);
  };

  const getStatusBadge = (status) => {
    const statusClasses = {
      'Available': 'bg-success',
      'Occupied': 'bg-primary',
      'Reserved': 'bg-warning',
      'Maintenance': 'bg-danger',
      'Cleaning': 'bg-info'
    };
    return <Badge className={statusClasses[status]}>{status}</Badge>;
  };

  const getAmenityIcon = (amenity) => {
    const icons = {
      'WiFi': <FaWifi />,
      'TV': <FaTv />,
      'AC': <FaSnowflake />
    };
    return icons[amenity] || <span>{amenity}</span>;
  };

  const filteredRooms = rooms.filter(room => 
    filterStatus === 'All' || room.status === filterStatus
  );

  const statusCounts = {
    Available: rooms.filter(r => r.status === 'Available').length,
    Occupied: rooms.filter(r => r.status === 'Occupied').length,
    Reserved: rooms.filter(r => r.status === 'Reserved').length,
    Maintenance: rooms.filter(r => r.status === 'Maintenance').length
  };

  return (
    <div>
      <Row className="mb-4">
        <Col>
          <h2>Room Management</h2>
        </Col>
        <Col xs="auto">
          <Button 
            variant="primary" 
            onClick={() => handleShowModal()}
            className="btn-primary-custom"
          >
            <FaPlus className="me-2" />
            Add New Room
          </Button>
        </Col>
      </Row>

      {/* Room Status Overview */}
      <Row className="mb-4">
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-success">{statusCounts.Available}</h4>
              <p className="mb-0">Available</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-primary">{statusCounts.Occupied}</h4>
              <p className="mb-0">Occupied</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-warning">{statusCounts.Reserved}</h4>
              <p className="mb-0">Reserved</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-danger">{statusCounts.Maintenance}</h4>
              <p className="mb-0">Maintenance</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Filter Controls */}
      <Row className="mb-4">
        <Col>
          <Card className="card-custom">
            <Card.Body>
              <Form.Label>Filter by Status:</Form.Label>
              <Form.Select 
                value={filterStatus} 
                onChange={(e) => setFilterStatus(e.target.value)}
                style={{width: '200px'}}
              >
                <option value="All">All Rooms</option>
                <option value="Available">Available</option>
                <option value="Occupied">Occupied</option>
                <option value="Reserved">Reserved</option>
                <option value="Maintenance">Maintenance</option>
              </Form.Select>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Room Grid */}
      <Row>
        {filteredRooms.map((room) => (
          <Col md={4} lg={3} key={room.id} className="mb-4">
            <Card className="card-custom h-100">
              <Card.Header className="d-flex justify-content-between align-items-center">
                <div className="d-flex align-items-center">
                  <FaBed className="me-2 text-primary" />
                  <strong>Room {room.number}</strong>
                </div>
                {getStatusBadge(room.status)}
              </Card.Header>
              <Card.Body>
                <h6 className="text-muted">{room.type} - Floor {room.floor}</h6>
                <h5 className="text-primary">${room.price}/night</h5>
                <p className="small text-muted mb-3">{room.description}</p>
                
                <div className="mb-3">
                  <small className="text-muted">Amenities:</small>
                  <div className="mt-1">
                    {room.amenities.map((amenity, index) => (
                      <Badge key={index} bg="light" text="dark" className="me-1 mb-1">
                        {getAmenityIcon(amenity)} {amenity}
                      </Badge>
                    ))}
                  </div>
                </div>
                
                <div className="d-grid gap-2">
                  <Button
                    variant="outline-primary"
                    size="sm"
                    onClick={() => handleShowModal(room)}
                  >
                    <FaEdit className="me-1" />
                    Edit Room
                  </Button>
                  {room.status === 'Available' && (
                    <Button variant="success" size="sm">
                      Book Room
                    </Button>
                  )}
                </div>
              </Card.Body>
            </Card>
          </Col>
        ))}
      </Row>

      {/* Add/Edit Room Modal */}
      <Modal show={showModal} onHide={handleCloseModal} size="lg">
        <Modal.Header closeButton>
          <Modal.Title>
            {selectedRoom ? 'Edit Room' : 'Add New Room'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Room Number</Form.Label>
                  <Form.Control
                    type="text"
                    placeholder="Enter room number"
                    defaultValue={selectedRoom?.number || ''}
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Room Type</Form.Label>
                  <Form.Select defaultValue={selectedRoom?.type || ''}>
                    <option value="">Select Type</option>
                    <option value="Single">Single</option>
                    <option value="Double">Double</option>
                    <option value="Suite">Suite</option>
                    <option value="Deluxe">Deluxe</option>
                  </Form.Select>
                </Form.Group>
              </Col>
            </Row>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Floor</Form.Label>
                  <Form.Control
                    type="number"
                    placeholder="Enter floor number"
                    defaultValue={selectedRoom?.floor || ''}
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Price per Night</Form.Label>
                  <Form.Control
                    type="number"
                    placeholder="Enter price"
                    defaultValue={selectedRoom?.price || ''}
                  />
                </Form.Group>
              </Col>
            </Row>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Status</Form.Label>
                  <Form.Select defaultValue={selectedRoom?.status || ''}>
                    <option value="Available">Available</option>
                    <option value="Occupied">Occupied</option>
                    <option value="Reserved">Reserved</option>
                    <option value="Maintenance">Maintenance</option>
                    <option value="Cleaning">Cleaning</option>
                  </Form.Select>
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Amenities</Form.Label>
                  <div>
                    {['WiFi', 'TV', 'AC', 'Mini Bar', 'Balcony', 'Jacuzzi'].map((amenity) => (
                      <Form.Check
                        key={amenity}
                        type="checkbox"
                        label={amenity}
                        defaultChecked={selectedRoom?.amenities.includes(amenity)}
                        inline
                      />
                    ))}
                  </div>
                </Form.Group>
              </Col>
            </Row>
            <Form.Group className="mb-3">
              <Form.Label>Description</Form.Label>
              <Form.Control
                as="textarea"
                rows={3}
                placeholder="Enter room description"
                defaultValue={selectedRoom?.description || ''}
              />
            </Form.Group>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal}>
            Cancel
          </Button>
          <Button variant="primary" className="btn-primary-custom">
            {selectedRoom ? 'Update Room' : 'Add Room'}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default Rooms;