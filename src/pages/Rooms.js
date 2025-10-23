import React, { useState, useEffect } from 'react';
import { Container, Row, Col, Card, Button, Table, Badge, Modal, Form, Spinner, Alert } from 'react-bootstrap';
import { FaBed, FaEye, FaWifi, FaTv, FaSnowflake, FaCoffee, FaSwimmingPool } from 'react-icons/fa';
import { apiUrl } from '../utils/api';
import { useBranch } from '../context/BranchContext';
import './Rooms.css';

const Rooms = () => {
  const { selectedBranchId } = useBranch();
  const [rooms, setRooms] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [selectedRoom, setSelectedRoom] = useState(null);
  const [filterStatus, setFilterStatus] = useState('All');
  const [filterType, setFilterType] = useState('All');

  // Fetch rooms from backend whenever branch changes
  useEffect(() => {
    const fetchRooms = async () => {
      try {
        setLoading(true);
        setError('');
        
        // Add branch filter to API call
        const branchParam = selectedBranchId !== 'All' ? `&branch_id=${selectedBranchId}` : '';
        const response = await fetch(apiUrl(`/api/rooms?limit=1000${branchParam}`));
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
  }, [selectedBranchId]); // Re-fetch when global branch filter changes

  const handleShowModal = (room) => {
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

  // Filter rooms (client-side filtering for status and type)
  let filteredRooms = rooms;
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
    <div className="rooms-container">
      <Container fluid className="py-4">
        {loading && (
          <div className="text-center loading-container" style={{ padding: '60px', margin: '2rem auto', maxWidth: '500px' }}>
            <Spinner animation="border" role="status" style={{ color: '#1a237e' }}>
              <span className="visually-hidden">Loading rooms...</span>
            </Spinner>
            <p className="mt-3" style={{ color: '#1a237e', fontWeight: '600' }}>Loading rooms...</p>
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
      {/* Header */}
      <Row className="mb-4">
        <Col>
          <div className="page-header">
            <div className="d-flex justify-content-between align-items-center">
              <div>
                <h2 className="mb-1">Room Status Overview</h2>
                <p style={{ marginBottom: 0 }}>
                  View room status and information across all SkyNest Hotel branches
                </p>
              </div>
            </div>
          </div>
        </Col>
      </Row>

      {/* Room Statistics */}
      <Row className="mb-4">
        <Col md={3}>
          <Card className="stat-card text-center h-100">
            <Card.Body style={{ padding: '24px' }}>
              <FaBed style={{ color: 'white', marginBottom: '12px' }} size={32} />
              <h3 style={{ color: 'white', fontWeight: 'bold', fontSize: '2rem', marginBottom: '8px' }}>
                {totalRooms}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0 }}>Total Rooms</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="stat-card text-center h-100">
            <Card.Body style={{ padding: '24px' }}>
              <h3 style={{ color: 'white', fontWeight: 'bold', fontSize: '2rem', marginBottom: '8px' }}>
                {availableRooms}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0 }}>Available</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="stat-card text-center h-100">
            <Card.Body style={{ padding: '24px' }}>
              <h3 style={{ color: 'white', fontWeight: 'bold', fontSize: '2rem', marginBottom: '8px' }}>
                {occupiedRooms}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0 }}>Occupied</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="stat-card text-center h-100">
            <Card.Body style={{ padding: '24px' }}>
              <h3 style={{ color: 'white', fontWeight: 'bold', fontSize: '2rem', marginBottom: '8px' }}>
                {occupancyRate}%
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0 }}>Occupancy Rate</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Filters */}
      <Row className="mb-4">
        <Col>
          <div className="filter-section">
            <Row>
              <Col md={4}>
                <Form.Group>
                  <Form.Label>Filter by Status</Form.Label>
                  <Form.Select 
                    value={filterStatus} 
                    onChange={(e) => setFilterStatus(e.target.value)}
                  >
                    <option value="All">All Status</option>
                    <option value="Available">Available</option>
                    <option value="Occupied">Occupied</option>
                    <option value="Maintenance">Maintenance</option>
                    <option value="Cleaning">Cleaning</option>
                  </Form.Select>
                </Form.Group>
              </Col>
              <Col md={4}>
                <Form.Group>
                  <Form.Label>Filter by Type</Form.Label>
                  <Form.Select 
                    value={filterType} 
                    onChange={(e) => setFilterType(e.target.value)}
                  >
                    <option value="All">All Types</option>
                    <option value="Standard Single">Single</option>
                    <option value="Standard Double">Double</option>
                    <option value="Suite">Suite</option>
                  </Form.Select>
                </Form.Group>
              </Col>
              <Col md={4}>
                <Form.Group>
                  <Form.Label>Quick Stats</Form.Label>
                  <div className="mt-2">
                    <Badge bg="success" className="me-2">{availableRooms} Available</Badge>
                    <Badge bg="primary">{occupiedRooms} Occupied</Badge>
                  </div>
                </Form.Group>
              </Col>
            </Row>
          </div>
        </Col>
      </Row>

      {/* Rooms Grid View */}
      <Row className="mb-4">
        {filteredRooms.map((room) => (
          <Col lg={4} md={6} key={room.id} className="mb-3">
            <Card className="h-100 room-card">
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
                      <span key={index} className="amenity-badge">
                        {getAmenityIcon(amenity)} {amenity}
                      </span>
                    ))}
                    {room.amenities.length > 4 && (
                      <span className="amenity-badge">
                        +{room.amenities.length - 4} more
                      </span>
                    )}
                  </div>
                </div>
                
                <p className="text-muted small">{room.description}</p>
              </Card.Body>
              <Card.Footer className="bg-light">
                <div className="d-flex justify-content-center">
                  <Button 
                    variant="outline-primary" 
                    size="sm"
                    onClick={() => handleShowModal(room)}
                  >
                    <FaEye className="me-1" />
                    View Details
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
          <Card className="rooms-table">
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
                        <Button
                          variant="outline-primary"
                          size="sm"
                          onClick={() => handleShowModal(room)}
                        >
                          <FaEye />
                        </Button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Modal for View Room Details */}
      <Modal show={showModal} onHide={handleCloseModal} size="lg">
        <Modal.Header closeButton>
          <Modal.Title>Room Details</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {selectedRoom && (
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
                    <span key={index} className="amenity-badge me-1 mb-1">
                      {getAmenityIcon(amenity)} {amenity}
                    </span>
                  ))}
                </div>
                
                <h6 className="mt-4">Description</h6>
                <p>{selectedRoom.description}</p>
              </Col>
            </Row>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal}>
            Close
          </Button>
        </Modal.Footer>
      </Modal>
        </>
      )}
      </Container>
    </div>
  );
};

export default Rooms;
