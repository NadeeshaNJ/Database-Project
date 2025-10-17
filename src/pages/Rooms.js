import React, { useState, useEffect } from 'react';
import { Container, Row, Col, Card, Button, Table, Badge, Modal, Form, Spinner, Alert } from 'react-bootstrap';
import { FaBed, FaPlus, FaEdit, FaEye, FaWifi, FaTv, FaSnowflake, FaCoffee, FaSwimmingPool } from 'react-icons/fa';
import { apiUrl } from '../utils/api';

const Rooms = () => {
  const [rooms, setRooms] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [selectedRoom, setSelectedRoom] = useState(null);
  const [modalType, setModalType] = useState('add');
  const [filterHotel, setFilterHotel] = useState('All');
  const [filterStatus, setFilterStatus] = useState('All');
  const [filterType, setFilterType] = useState('All');

  // Fetch rooms from backend
  useEffect(() => {
    const fetchRooms = async () => {
      try {
        setLoading(true);
        setError('');
        
        // Request all rooms with a high limit (or implement pagination later)
        const response = await fetch(apiUrl('/api/rooms?limit=1000'));
        const data = await response.json();
        
        if (data.success && data.data && data.data.rooms) {
          // Transform backend data to match frontend format
          const transformedRooms = data.data.rooms.map(room => ({
            id: room.room_id,
            roomNumber: room.room_number,
            roomType: room.room_type_name,
            capacity: room.capacity,
            dailyRate: parseFloat(room.daily_rate),
            status: room.status,
            isAvailable: room.is_available,
            // Parse amenities from database (comma-separated string to array)
            amenities: room.amenities ? room.amenities.split(',').map(a => a.trim()) : [],
            // Use actual branch name from database
            hotelBranch: room.branch_name ? `SkyNest ${room.branch_name}` : 'SkyNest Hotels',
            branchCode: room.branch_code,
            floor: Math.floor(parseInt(room.room_number) / 100),
            description: `${room.room_type_name} room with ${room.capacity} guest${room.capacity > 1 ? 's' : ''} capacity`,
            bedType: room.room_type_name === 'Standard Single' ? 'Single' : 
                     room.room_type_name === 'Standard Double' ? 'Queen' : 
                     room.room_type_name === 'Deluxe King' ? 'King' :
                     room.room_type_name === 'Suite' ? 'King + Sofa Bed' : 'Standard',
            size: room.room_type_name === 'Standard Single' ? 25 : 
                  room.room_type_name === 'Standard Double' ? 35 : 
                  room.room_type_name === 'Deluxe King' ? 50 :
                  room.room_type_name === 'Suite' ? 70 : 30,
            view: room.amenities && room.amenities.includes('Sea View') ? 'Sea View' :
                  room.amenities && room.amenities.includes('Balcony') ? 'City View' : 'Standard View'
          }));
          
          setRooms(transformedRooms);
        } else {
          setError(data.error || 'Failed to fetch rooms');
        }
      } catch (err) {
        console.error('Error fetching rooms:', err);
        setError('Failed to connect to server. Please ensure the backend is running.');
      } finally {
        setLoading(false);
      }
    };

    fetchRooms();
  }, []);

  const handleShowModal = (type, room = null) => {
    setModalType(type);
    setSelectedRoom(room);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedRoom(null);
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'Available': return 'success';
      case 'Occupied': return 'primary';
      case 'Maintenance': return 'warning';
      case 'Out of Order': return 'danger';
      case 'Cleaning': return 'info';
      default: return 'secondary';
    }
  };

  const getRoomTypeColor = (type) => {
    switch (type) {
      case 'Single': return 'info';
      case 'Double': return 'primary';
      case 'Suite': return 'warning';
      default: return 'secondary';
    }
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-LK', {
      style: 'currency',
      currency: 'LKR'
    }).format(amount);
  };

  const getAmenityIcon = (amenity) => {
    switch (amenity) {
      case 'WiFi': return <FaWifi />;
      case 'AC': return <FaSnowflake />;
      case 'TV': return <FaTv />;
      case 'Mini Bar': return <FaCoffee />;
      case 'Balcony': return <FaBed />;
      case 'Safe': return <FaBed />;
      case 'Living Area': return <FaBed />;
      case 'Kitchenette': return <FaCoffee />;
      case 'Beach Access': return <FaSwimmingPool />;
      default: return <FaBed />;
    }
  };

  // Filter rooms
  let filteredRooms = rooms;
  if (filterHotel !== 'All') {
    filteredRooms = filteredRooms.filter(room => room.hotelBranch === filterHotel);
  }
  if (filterStatus !== 'All') {
    filteredRooms = filteredRooms.filter(room => room.status === filterStatus);
  }
  if (filterType !== 'All') {
    filteredRooms = filteredRooms.filter(room => room.roomType === filterType);
  }

  // Statistics
  const totalRooms = rooms.length;
  const availableRooms = rooms.filter(room => room.status === 'Available').length;
  const occupiedRooms = rooms.filter(room => room.status === 'Occupied').length;
  const maintenanceRooms = rooms.filter(room => room.status === 'Maintenance').length;
  const occupancyRate = Math.round((occupiedRooms / totalRooms) * 100);

  return (
    <Container fluid className="py-4">
      {loading && (
        <div className="text-center py-5">
          <Spinner animation="border" role="status" variant="primary">
            <span className="visually-hidden">Loading rooms...</span>
          </Spinner>
          <p className="mt-3 text-muted">Loading rooms...</p>
        </div>
      )}

      {error && (
        <Alert variant="danger" dismissible onClose={() => setError('')}>
          <Alert.Heading>Error Loading Rooms</Alert.Heading>
          <p>{error}</p>
        </Alert>
      )}

      {!loading && !error && (
        <>
      <Row className="mb-4">
        <Col>
          <div className="d-flex justify-content-between align-items-center">
            <div>
              <h2 className="mb-1">Room Management</h2>
              <p className="text-muted">Manage room inventory across all SkyNest Hotel branches</p>
            </div>
            <Button 
              variant="primary" 
              onClick={() => handleShowModal('add')}
              className="d-flex align-items-center"
            >
              <FaPlus className="me-2" />
              Add New Room
            </Button>
          </div>
        </Col>
      </Row>

      {/* Room Statistics */}
      <Row className="mb-4">
        <Col md={3}>
          <Card className="text-center h-100 border-primary">
            <Card.Body>
              <FaBed className="text-primary mb-2" size={24} />
              <h3 className="text-primary">{totalRooms}</h3>
              <p className="mb-0 text-muted">Total Rooms</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center h-100 border-success">
            <Card.Body>
              <h3 className="text-success">{availableRooms}</h3>
              <p className="mb-0 text-muted">Available</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center h-100 border-info">
            <Card.Body>
              <h3 className="text-info">{occupiedRooms}</h3>
              <p className="mb-0 text-muted">Occupied</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center h-100 border-warning">
            <Card.Body>
              <h3 className="text-warning">{occupancyRate}%</h3>
              <p className="mb-0 text-muted">Occupancy Rate</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Filters */}
      <Row className="mb-4">
        <Col md={3}>
          <Form.Group>
            <Form.Label>Filter by Hotel</Form.Label>
            <Form.Select value={filterHotel} onChange={(e) => setFilterHotel(e.target.value)}>
              <option value="All">All Hotels</option>
              <option value="SkyNest Colombo">SkyNest Colombo</option>
              <option value="SkyNest Kandy">SkyNest Kandy</option>
              <option value="SkyNest Galle">SkyNest Galle</option>
            </Form.Select>
          </Form.Group>
        </Col>
        <Col md={3}>
          <Form.Group>
            <Form.Label>Filter by Status</Form.Label>
            <Form.Select value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}>
              <option value="All">All Status</option>
              <option value="Available">Available</option>
              <option value="Occupied">Occupied</option>
              <option value="Maintenance">Maintenance</option>
              <option value="Cleaning">Cleaning</option>
            </Form.Select>
          </Form.Group>
        </Col>
        <Col md={3}>
          <Form.Group>
            <Form.Label>Filter by Type</Form.Label>
            <Form.Select value={filterType} onChange={(e) => setFilterType(e.target.value)}>
              <option value="All">All Types</option>
              <option value="Single">Single</option>
              <option value="Double">Double</option>
              <option value="Suite">Suite</option>
            </Form.Select>
          </Form.Group>
        </Col>
      </Row>

      {/* Rooms Grid View */}
      <Row className="mb-4">
        {filteredRooms.map((room) => (
          <Col lg={4} md={6} key={room.id} className="mb-3">
            <Card className="h-100 shadow-sm">
              <Card.Header className="d-flex justify-content-between align-items-center">
                <div>
                  <h6 className="mb-0">Room {room.roomNumber}</h6>
                  <small className="text-muted">{room.hotelBranch}</small>
                </div>
                <div className="d-flex gap-1">
                  <Badge bg={getRoomTypeColor(room.roomType)}>
                    {room.roomType}
                  </Badge>
                  <Badge bg={getStatusColor(room.status)}>
                    {room.status}
                  </Badge>
                </div>
              </Card.Header>
              <Card.Body>
                <Row className="mb-2">
                  <Col><strong>Floor:</strong> {room.floor}</Col>
                  <Col><strong>Capacity:</strong> {room.capacity}</Col>
                </Row>
                <Row className="mb-2">
                  <Col><strong>Size:</strong> {room.size} m²</Col>
                  <Col><strong>View:</strong> {room.view}</Col>
                </Row>
                <Row className="mb-3">
                  <Col><strong>Bed:</strong> {room.bedType}</Col>
                  <Col><strong>Rate:</strong> {formatCurrency(room.dailyRate)}</Col>
                </Row>
                
                <div className="mb-3">
                  <small className="text-muted">Amenities:</small>
                  <div className="mt-1">
                    {room.amenities.slice(0, 4).map((amenity, index) => (
                      <Badge key={index} bg="light" text="dark" className="me-1 mb-1">
                        {getAmenityIcon(amenity)} {amenity}
                      </Badge>
                    ))}
                    {room.amenities.length > 4 && (
                      <Badge bg="light" text="dark">
                        +{room.amenities.length - 4} more
                      </Badge>
                    )}
                  </div>
                </div>
                
                <p className="text-muted small">{room.description}</p>
              </Card.Body>
              <Card.Footer className="bg-light">
                <div className="d-flex justify-content-between">
                  <Button 
                    variant="outline-primary" 
                    size="sm"
                    onClick={() => handleShowModal('view', room)}
                  >
                    <FaEye className="me-1" />
                    View
                  </Button>
                  <Button 
                    variant="outline-secondary" 
                    size="sm"
                    onClick={() => handleShowModal('edit', room)}
                  >
                    <FaEdit className="me-1" />
                    Edit
                  </Button>
                </div>
              </Card.Footer>
            </Card>
          </Col>
        ))}
      </Row>

      {/* Rooms Table */}
      <Row>
        <Col>
          <Card>
            <Card.Header>
              <h5 className="mb-0">Rooms Summary ({filteredRooms.length} rooms)</h5>
            </Card.Header>
            <Card.Body>
              <Table responsive striped hover>
                <thead>
                  <tr>
                    <th>Room</th>
                    <th>Hotel</th>
                    <th>Type</th>
                    <th>Floor</th>
                    <th>Capacity</th>
                    <th>Rate/Night</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredRooms.map((room) => (
                    <tr key={room.id}>
                      <td>
                        <strong>{room.roomNumber}</strong>
                      </td>
                      <td>{room.hotelBranch}</td>
                      <td>
                        <Badge bg={getRoomTypeColor(room.roomType)}>
                          {room.roomType}
                        </Badge>
                      </td>
                      <td>{room.floor}</td>
                      <td>{room.capacity} guests</td>
                      <td>{formatCurrency(room.dailyRate)}</td>
                      <td>
                        <Badge bg={getStatusColor(room.status)}>
                          {room.status}
                        </Badge>
                      </td>
                      <td>
                        <div className="d-flex gap-2">
                          <Button
                            variant="outline-primary"
                            size="sm"
                            onClick={() => handleShowModal('view', room)}
                          >
                            <FaEye />
                          </Button>
                          <Button
                            variant="outline-secondary"
                            size="sm"
                            onClick={() => handleShowModal('edit', room)}
                          >
                            <FaEdit />
                          </Button>
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

      {/* Modal for Add/Edit/View Room */}
      <Modal show={showModal} onHide={handleCloseModal} size="lg">
        <Modal.Header closeButton>
          <Modal.Title>
            {modalType === 'add' && 'Add New Room'}
            {modalType === 'edit' && 'Edit Room'}
            {modalType === 'view' && 'Room Details'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {selectedRoom && modalType === 'view' ? (
            <Row>
              <Col md={6}>
                <h6>Room Information</h6>
                <p><strong>Room Number:</strong> {selectedRoom.roomNumber}</p>
                <p><strong>Hotel:</strong> {selectedRoom.hotelBranch}</p>
                <p><strong>Type:</strong> {selectedRoom.roomType}</p>
                <p><strong>Floor:</strong> {selectedRoom.floor}</p>
                <p><strong>Capacity:</strong> {selectedRoom.capacity} guests</p>
                <p><strong>Status:</strong> 
                  <Badge bg={getStatusColor(selectedRoom.status)} className="ms-2">
                    {selectedRoom.status}
                  </Badge>
                </p>
              </Col>
              <Col md={6}>
                <h6>Room Details</h6>
                <p><strong>Size:</strong> {selectedRoom.size} square meters</p>
                <p><strong>Bed Type:</strong> {selectedRoom.bedType}</p>
                <p><strong>View:</strong> {selectedRoom.view}</p>
                <p><strong>Daily Rate:</strong> {formatCurrency(selectedRoom.dailyRate)}</p>
                
                <h6 className="mt-4">Amenities</h6>
                <div>
                  {selectedRoom.amenities.map((amenity, index) => (
                    <Badge key={index} bg="primary" className="me-1 mb-1">
                      {getAmenityIcon(amenity)} {amenity}
                    </Badge>
                  ))}
                </div>
                
                <h6 className="mt-4">Description</h6>
                <p>{selectedRoom.description}</p>
              </Col>
            </Row>
          ) : (
            <Form>
              <Row>
                <Col md={6}>
                  <Form.Group className="mb-3">
                    <Form.Label>Room Number</Form.Label>
                    <Form.Control
                      type="text"
                      defaultValue={selectedRoom?.roomNumber || ''}
                      placeholder="Enter room number"
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Hotel Branch</Form.Label>
                    <Form.Select defaultValue={selectedRoom?.hotelBranch || ''}>
                      <option value="">Select hotel branch</option>
                      <option value="SkyNest Colombo">SkyNest Colombo</option>
                      <option value="SkyNest Kandy">SkyNest Kandy</option>
                      <option value="SkyNest Galle">SkyNest Galle</option>
                    </Form.Select>
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Room Type</Form.Label>
                    <Form.Select defaultValue={selectedRoom?.roomType || ''}>
                      <option value="">Select room type</option>
                      <option value="Single">Single</option>
                      <option value="Double">Double</option>
                      <option value="Suite">Suite</option>
                    </Form.Select>
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Floor</Form.Label>
                    <Form.Control
                      type="number"
                      defaultValue={selectedRoom?.floor || ''}
                      placeholder="Enter floor number"
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Capacity</Form.Label>
                    <Form.Control
                      type="number"
                      defaultValue={selectedRoom?.capacity || ''}
                      placeholder="Enter guest capacity"
                    />
                  </Form.Group>
                </Col>
                <Col md={6}>
                  <Form.Group className="mb-3">
                    <Form.Label>Daily Rate (LKR)</Form.Label>
                    <Form.Control
                      type="number"
                      defaultValue={selectedRoom?.dailyRate || ''}
                      placeholder="Enter daily rate"
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Status</Form.Label>
                    <Form.Select defaultValue={selectedRoom?.status || 'Available'}>
                      <option value="Available">Available</option>
                      <option value="Occupied">Occupied</option>
                      <option value="Maintenance">Maintenance</option>
                      <option value="Cleaning">Cleaning</option>
                      <option value="Out of Order">Out of Order</option>
                    </Form.Select>
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Bed Type</Form.Label>
                    <Form.Control
                      type="text"
                      defaultValue={selectedRoom?.bedType || ''}
                      placeholder="e.g., King, Queen, Single"
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Size (sq meters)</Form.Label>
                    <Form.Control
                      type="number"
                      defaultValue={selectedRoom?.size || ''}
                      placeholder="Enter room size"
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>View</Form.Label>
                    <Form.Control
                      type="text"
                      defaultValue={selectedRoom?.view || ''}
                      placeholder="e.g., Ocean View, City View"
                    />
                  </Form.Group>
                </Col>
              </Row>
              <Form.Group className="mb-3">
                <Form.Label>Description</Form.Label>
                <Form.Control
                  as="textarea"
                  rows={3}
                  defaultValue={selectedRoom?.description || ''}
                  placeholder="Enter room description"
                />
              </Form.Group>
            </Form>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal}>
            Close
          </Button>
          {modalType !== 'view' && (
            <Button variant="primary">
              {modalType === 'add' ? 'Add Room' : 'Save Changes'}
            </Button>
          )}
        </Modal.Footer>
      </Modal>
        </>
      )}
    </Container>
  );
};

export default Rooms;