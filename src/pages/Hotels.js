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
          <Spinner animation="border" role="status" style={{ color: '#1976d2', width: '3rem', height: '3rem' }}>
            <span className="visually-hidden">Loading branches...</span>
          </Spinner>
          <p className="mt-3" style={{ color: '#1976d2', fontSize: '1.1rem' }}>Loading hotel branches...</p>
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
            <div className="page-header" style={{
              background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
              padding: '2rem',
              borderRadius: '1rem',
              boxShadow: '0 4px 15px rgba(0,0,0,0.1)',
              color: 'white',
              flex: 1,
              marginRight: '1rem'
            }}>
              <h2 style={{ color: 'white', fontWeight: '700', marginBottom: '0.5rem' }}>
                <FaBuilding className="me-2" />
                Hotel Branches
              </h2>
              <p style={{ marginBottom: 0, color: 'rgba(255, 255, 255, 0.9)' }}>Manage SkyNest Hotels locations across Sri Lanka</p>
            </div>
            <Button 
              onClick={() => handleShowModal('add')}
              className="d-flex align-items-center"
              style={{
                background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                border: 'none',
                fontWeight: '600',
                padding: '0.75rem 1.5rem',
                boxShadow: '0 4px 15px rgba(26, 35, 126, 0.4)',
                transition: 'all 0.3s ease',
                whiteSpace: 'nowrap'
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.transform = 'translateY(-2px)';
                e.currentTarget.style.boxShadow = '0 6px 20px rgba(25, 118, 210, 0.5)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = '0 4px 15px rgba(26, 35, 126, 0.4)';
              }}
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
            <Card className="h-100" style={{
              border: 'none',
              borderRadius: '1rem',
              boxShadow: '0 4px 15px rgba(0,0,0,0.1)',
              transition: 'transform 0.3s ease, box-shadow 0.3s ease'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-5px)';
              e.currentTarget.style.boxShadow = '0 8px 25px rgba(26, 35, 126, 0.2)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = '0 4px 15px rgba(0,0,0,0.1)';
            }}>
              <Card.Header style={{
                background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                color: 'white',
                border: 'none',
                borderRadius: '1rem 1rem 0 0',
                padding: '1.5rem'
              }}>
                <div className="d-flex justify-content-between align-items-center">
                  <h5 className="mb-0" style={{ color: 'white', fontWeight: '600' }}>
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
              <Card.Footer style={{ 
                background: '#f8f9fa', 
                borderTop: '1px solid #e0e6ed',
                borderRadius: '0 0 1rem 1rem',
                padding: '1rem 1.5rem'
              }}>
                <div className="d-flex justify-content-between">
                  <Button 
                    variant="outline-primary" 
                    size="sm"
                    onClick={() => handleShowModal('view', hotel)}
                    style={{
                      borderColor: '#1976d2',
                      color: '#1976d2',
                      fontWeight: '600'
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.background = '#1976d2';
                      e.currentTarget.style.color = 'white';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.background = 'transparent';
                      e.currentTarget.style.color = '#1976d2';
                    }}
                  >
                    <FaEye className="me-1" />
                    View Details
                  </Button>
                  <Button 
                    variant="outline-secondary" 
                    size="sm"
                    onClick={() => handleShowModal('edit', hotel)}
                    style={{
                      fontWeight: '600'
                    }}
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
          <Card style={{ border: 'none', borderRadius: '1rem', boxShadow: '0 4px 15px rgba(0,0,0,0.1)' }}>
            <Card.Header style={{
              background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
              borderBottom: 'none',
              borderRadius: '1rem 1rem 0 0',
              padding: '1.5rem'
            }}>
              <h5 className="mb-0" style={{ color: 'white', fontWeight: '700' }}>Hotel Branches Summary</h5>
            </Card.Header>
            <Card.Body>
              <Table responsive striped hover>
                <thead style={{
                  background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                  borderBottom: '2px solid #0d47a1'
                }}>
                  <tr>
                    <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Hotel Name</th>
                    <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Location</th>
                    <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Manager</th>
                    <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Total Rooms</th>
                    <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Available</th>
                    <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Occupancy</th>
                    <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Status</th>
                    <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {hotels.map((hotel) => (
                    <tr key={hotel.id} style={{ borderBottom: '1px solid #e0e6ed' }}>
                      <td style={{ padding: '16px', color: '#2c3e50', fontWeight: '500' }}>
                        <strong>{hotel.name}</strong>
                      </td>
                      <td style={{ padding: '16px', color: '#2c3e50', fontWeight: '500' }}>{hotel.location}</td>
                      <td style={{ padding: '16px', color: '#2c3e50', fontWeight: '500' }}>{hotel.manager}</td>
                      <td style={{ padding: '16px', color: '#2c3e50', fontWeight: '500' }}>{hotel.totalRooms}</td>
                      <td style={{ padding: '16px', fontWeight: '500' }} className="text-success">{hotel.availableRooms}</td>
                      <td style={{ padding: '16px' }}>
                        <Badge bg={getOccupancyColor(getOccupancyRate(hotel))}>
                          {getOccupancyRate(hotel)}%
                        </Badge>
                      </td>
                      <td style={{ padding: '16px' }}>
                        <Badge bg={hotel.status === 'Active' ? 'success' : 'secondary'}>
                          {hotel.status}
                        </Badge>
                      </td>
                      <td style={{ padding: '16px' }}>
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
        <Modal.Header closeButton style={{
          background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
          color: 'white',
          border: 'none'
        }}>
          <Modal.Title style={{ color: 'white', fontWeight: '600' }}>
            {modalType === 'add' && 'Add New Hotel Branch'}
            {modalType === 'edit' && 'Edit Hotel Branch'}
            {modalType === 'view' && 'Hotel Branch Details'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {selectedHotel && modalType === 'view' ? (
            <Row>
              <Col md={6}>
                <h6 style={{ 
                  color: '#1a237e', 
                  fontWeight: '600',
                  borderBottom: '2px solid #1976d2',
                  paddingBottom: '0.5rem',
                  marginBottom: '1rem'
                }}>Basic Information</h6>
                <p><strong>Name:</strong> {selectedHotel.name}</p>
                <p><strong>Location:</strong> {selectedHotel.location}</p>
                <p><strong>Address:</strong> {selectedHotel.address}</p>
                <p><strong>Phone:</strong> {selectedHotel.phone}</p>
                <p><strong>Email:</strong> {selectedHotel.email}</p>
                <p><strong>Manager:</strong> {selectedHotel.manager}</p>
              </Col>
              <Col md={6}>
                <h6 style={{ 
                  color: '#1a237e', 
                  fontWeight: '600',
                  borderBottom: '2px solid #1976d2',
                  paddingBottom: '0.5rem',
                  marginBottom: '1rem'
                }}>Room Information</h6>
                <p><strong>Total Rooms:</strong> {selectedHotel.totalRooms}</p>
                <p><strong>Available Rooms:</strong> {selectedHotel.availableRooms}</p>
                <p><strong>Occupancy Rate:</strong> {getOccupancyRate(selectedHotel)}%</p>
                <p><strong>Status:</strong> {selectedHotel.status}</p>
                
                <h6 className="mt-3" style={{ 
                  color: '#1a237e', 
                  fontWeight: '600',
                  borderBottom: '2px solid #1976d2',
                  paddingBottom: '0.5rem',
                  marginBottom: '1rem'
                }}>Amenities</h6>
                <div>
                  {selectedHotel.amenities.map((amenity, index) => (
                    <Badge key={index} className="me-1 mb-1" style={{
                      background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)'
                    }}>
                      {amenity}
                    </Badge>
                  ))}
                </div>
                
                <h6 className="mt-3" style={{ 
                  color: '#1a237e', 
                  fontWeight: '600',
                  borderBottom: '2px solid #1976d2',
                  paddingBottom: '0.5rem',
                  marginBottom: '1rem'
                }}>Description</h6>
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
        <Modal.Footer style={{ borderTop: '1px solid #e0e6ed', padding: '1.5rem' }}>
          <Button 
            variant="secondary" 
            onClick={handleCloseModal}
            style={{
              padding: '0.5rem 1.5rem',
              fontWeight: '600'
            }}
          >
            Close
          </Button>
          {modalType !== 'view' && (
            <Button 
              style={{
                background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                border: 'none',
                padding: '0.5rem 1.5rem',
                fontWeight: '600',
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