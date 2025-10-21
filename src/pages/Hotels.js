import React, { useState, useEffect } from 'react';
import { Container, Row, Col, Card, Button, Table, Badge, Modal, Form, Spinner, Alert } from 'react-bootstrap';
import { FaBuilding, FaMapMarkerAlt, FaPhone, FaPlus, FaEdit, FaEye } from 'react-icons/fa';
import { apiUrl } from '../utils/api';

const Hotels = () => {
  const [hotels, setHotels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [selectedHotel, setSelectedHotel] = useState(null);
  const [modalType, setModalType] = useState('add'); // 'add', 'edit', 'view'

  // Fetch branches from backend
  useEffect(() => {
    const fetchBranches = async () => {
      try {
        setLoading(true);
        setError('');
        
        const response = await fetch(apiUrl('/api/branches'));
        const data = await response.json();
        
        if (data.success && data.data && data.data.branches) {
          // Transform backend data to match frontend format
          const transformedBranches = data.data.branches.map(branch => ({
            id: branch.branch_id,
            name: `SkyNest ${branch.branch_name}`,
            location: branch.branch_name,
            address: branch.address,
            phone: branch.contact_number,
            email: `${branch.branch_code.toLowerCase()}@skynest.lk`,
            manager: branch.manager_name,
            branchCode: branch.branch_code,
            totalRooms: parseInt(branch.total_rooms) || 0,
            availableRooms: parseInt(branch.available_rooms) || 0,
            status: 'Active',
            amenities: ['WiFi', 'Pool', 'Gym', 'Restaurant'],
            description: `${branch.branch_name} branch of SkyNest Hotels`
          }));
          
          setHotels(transformedBranches);
        } else {
          setError(data.error || 'Failed to fetch branches');
        }
      } catch (err) {
        console.error('Error fetching branches:', err);
        setError('Failed to connect to server. Please ensure the backend is running.');
      } finally {
        setLoading(false);
      }
    };

    fetchBranches();
  }, []);

  const handleShowModal = (type, hotel = null) => {
    setModalType(type);
    setSelectedHotel(hotel);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedHotel(null);
  };

  const getOccupancyRate = (hotel) => {
    const occupied = hotel.totalRooms - hotel.availableRooms;
    return Math.round((occupied / hotel.totalRooms) * 100);
  };

  const getOccupancyColor = (rate) => {
    if (rate >= 80) return 'danger';
    if (rate >= 60) return 'warning';
    return 'success';
  };

  return (
    <Container fluid className="py-4">
      {loading && (
        <div className="text-center py-5">
          <Spinner animation="border" role="status" variant="primary">
            <span className="visually-hidden">Loading branches...</span>
          </Spinner>
          <p className="mt-3 text-muted">Loading hotel branches...</p>
        </div>
      )}

      {error && (
        <Alert variant="danger" dismissible onClose={() => setError('')}>
          <Alert.Heading>Error Loading Branches</Alert.Heading>
          <p>{error}</p>
        </Alert>
      )}

      {!loading && !error && (
        <>
      <Row className="mb-4">
        <Col>
          <div className="d-flex justify-content-between align-items-center">
            <div>
              <h2 className="mb-1" style={{ color: '#2c3e50' }}>Hotel Branches</h2>
              <p className="mb-2" style={{ color: '#2c3e50' }}>Manage SkyNest Hotels locations across Sri Lanka</p>
            </div>
            <Button 
              variant="primary" 
              onClick={() => handleShowModal('add')}
              className="d-flex align-items-center"
            >
              <FaPlus className="me-2" />
              Add New Branch
            </Button>
          </div>
        </Col>
      </Row>

      {/* Hotels Overview Cards */}
      <Row className="mb-4">
        {hotels.map((hotel) => (
          <Col md={4} key={hotel.id} className="mb-3">
            <Card className="h-100 shadow-sm">
              <Card.Header className="bg-primary text-white">
                <div className="d-flex justify-content-between align-items-center">
                  <h5 className="mb-0">
                    <FaBuilding className="me-2" />
                    {hotel.name}
                  </h5>
                  <Badge bg={hotel.status === 'Active' ? 'success' : 'secondary'}>
                    {hotel.status}
                  </Badge>
                </div>
              </Card.Header>
              <Card.Body>
                <div className="mb-3">
                  <p className="mb-2">
                    <FaMapMarkerAlt className="text-muted me-2" />
                    {hotel.location}
                  </p>
                  <p className="mb-2">
                    <FaPhone className="text-muted me-2" />
                    {hotel.phone}
                  </p>
                  <p className="text-muted small">{hotel.description}</p>
                </div>
                
                <div className="mb-3">
                  <div className="d-flex justify-content-between mb-2">
                    <span>Total Rooms:</span>
                    <strong>{hotel.totalRooms}</strong>
                  </div>
                  <div className="d-flex justify-content-between mb-2">
                    <span>Available:</span>
                    <strong className="text-success">{hotel.availableRooms}</strong>
                  </div>
                  <div className="d-flex justify-content-between mb-2">
                    <span>Occupancy:</span>
                    <Badge bg={getOccupancyColor(getOccupancyRate(hotel))}>
                      {getOccupancyRate(hotel)}%
                    </Badge>
                  </div>
                </div>

                <div className="mb-3">
                  <small className="text-muted">Amenities:</small>
                  <div className="mt-1">
                    {hotel.amenities.slice(0, 3).map((amenity, index) => (
                      <Badge key={index} bg="light" text="dark" className="me-1 mb-1">
                        {amenity}
                      </Badge>
                    ))}
                    {hotel.amenities.length > 3 && (
                      <Badge bg="light" text="dark">
                        +{hotel.amenities.length - 3} more
                      </Badge>
                    )}
                  </div>
                </div>
              </Card.Body>
              <Card.Footer className="bg-light">
                <div className="d-flex justify-content-between">
                  <Button 
                    variant="outline-primary" 
                    size="sm"
                    onClick={() => handleShowModal('view', hotel)}
                  >
                    <FaEye className="me-1" />
                    View Details
                  </Button>
                  <Button 
                    variant="outline-secondary" 
                    size="sm"
                    onClick={() => handleShowModal('edit', hotel)}
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

      {/* Hotels Table */}
      <Row>
        <Col>
          <Card>
            <Card.Header>
              <h5 className="mb-0">Hotel Branches Summary</h5>
            </Card.Header>
            <Card.Body>
              <Table responsive striped hover>
                <thead>
                  <tr>
                    <th>Hotel Name</th>
                    <th>Location</th>
                    <th>Manager</th>
                    <th>Total Rooms</th>
                    <th>Available</th>
                    <th>Occupancy</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {hotels.map((hotel) => (
                    <tr key={hotel.id}>
                      <td>
                        <strong>{hotel.name}</strong>
                      </td>
                      <td>{hotel.location}</td>
                      <td>{hotel.manager}</td>
                      <td>{hotel.totalRooms}</td>
                      <td className="text-success">{hotel.availableRooms}</td>
                      <td>
                        <Badge bg={getOccupancyColor(getOccupancyRate(hotel))}>
                          {getOccupancyRate(hotel)}%
                        </Badge>
                      </td>
                      <td>
                        <Badge bg={hotel.status === 'Active' ? 'success' : 'secondary'}>
                          {hotel.status}
                        </Badge>
                      </td>
                      <td>
                        <div className="d-flex gap-2">
                          <Button
                            variant="outline-primary"
                            size="sm"
                            onClick={() => handleShowModal('view', hotel)}
                          >
                            <FaEye />
                          </Button>
                          <Button
                            variant="outline-secondary"
                            size="sm"
                            onClick={() => handleShowModal('edit', hotel)}
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

      {/* Modal for Add/Edit/View Hotel */}
      <Modal show={showModal} onHide={handleCloseModal} size="lg">
        <Modal.Header closeButton>
          <Modal.Title>
            {modalType === 'add' && 'Add New Hotel Branch'}
            {modalType === 'edit' && 'Edit Hotel Branch'}
            {modalType === 'view' && 'Hotel Branch Details'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {selectedHotel && modalType === 'view' ? (
            <Row>
              <Col md={6}>
                <h6>Basic Information</h6>
                <p><strong>Name:</strong> {selectedHotel.name}</p>
                <p><strong>Location:</strong> {selectedHotel.location}</p>
                <p><strong>Address:</strong> {selectedHotel.address}</p>
                <p><strong>Phone:</strong> {selectedHotel.phone}</p>
                <p><strong>Email:</strong> {selectedHotel.email}</p>
                <p><strong>Manager:</strong> {selectedHotel.manager}</p>
              </Col>
              <Col md={6}>
                <h6>Room Information</h6>
                <p><strong>Total Rooms:</strong> {selectedHotel.totalRooms}</p>
                <p><strong>Available Rooms:</strong> {selectedHotel.availableRooms}</p>
                <p><strong>Occupancy Rate:</strong> {getOccupancyRate(selectedHotel)}%</p>
                <p><strong>Status:</strong> {selectedHotel.status}</p>
                
                <h6 className="mt-3">Amenities</h6>
                <div>
                  {selectedHotel.amenities.map((amenity, index) => (
                    <Badge key={index} bg="primary" className="me-1 mb-1">
                      {amenity}
                    </Badge>
                  ))}
                </div>
                
                <h6 className="mt-3">Description</h6>
                <p>{selectedHotel.description}</p>
              </Col>
            </Row>
          ) : (
            <Form>
              <Row>
                <Col md={6}>
                  <Form.Group className="mb-3">
                    <Form.Label>Hotel Name</Form.Label>
                    <Form.Control
                      type="text"
                      defaultValue={selectedHotel?.name || ''}
                      placeholder="Enter hotel name"
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Location</Form.Label>
                    <Form.Select defaultValue={selectedHotel?.location || ''}>
                      <option value="">Select location</option>
                      <option value="Colombo">Colombo</option>
                      <option value="Kandy">Kandy</option>
                      <option value="Galle">Galle</option>
                      <option value="Negombo">Negombo</option>
                      <option value="Nuwara Eliya">Nuwara Eliya</option>
                    </Form.Select>
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Address</Form.Label>
                    <Form.Control
                      as="textarea"
                      rows={2}
                      defaultValue={selectedHotel?.address || ''}
                      placeholder="Enter complete address"
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Phone</Form.Label>
                    <Form.Control
                      type="tel"
                      defaultValue={selectedHotel?.phone || ''}
                      placeholder="+94-XX-XXXXXXX"
                    />
                  </Form.Group>
                </Col>
                <Col md={6}>
                  <Form.Group className="mb-3">
                    <Form.Label>Email</Form.Label>
                    <Form.Control
                      type="email"
                      defaultValue={selectedHotel?.email || ''}
                      placeholder="Enter email address"
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Manager</Form.Label>
                    <Form.Control
                      type="text"
                      defaultValue={selectedHotel?.manager || ''}
                      placeholder="Enter manager name"
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Total Rooms</Form.Label>
                    <Form.Control
                      type="number"
                      defaultValue={selectedHotel?.totalRooms || ''}
                      placeholder="Enter total number of rooms"
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Status</Form.Label>
                    <Form.Select defaultValue={selectedHotel?.status || 'Active'}>
                      <option value="Active">Active</option>
                      <option value="Maintenance">Maintenance</option>
                      <option value="Closed">Closed</option>
                    </Form.Select>
                  </Form.Group>
                </Col>
              </Row>
              <Form.Group className="mb-3">
                <Form.Label>Description</Form.Label>
                <Form.Control
                  as="textarea"
                  rows={3}
                  defaultValue={selectedHotel?.description || ''}
                  placeholder="Enter hotel description"
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
              {modalType === 'add' ? 'Add Hotel' : 'Save Changes'}
            </Button>
          )}
        </Modal.Footer>
      </Modal>
        </>
      )}
    </Container>
  );
};

export default Hotels;