import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Table, Badge, Tabs, Tab, Spinner, Form, Button, Alert } from 'react-bootstrap';
import { apiUrl } from '../utils/api';
import { useBranch } from '../context/BranchContext';
import { useAuth } from '../context/AuthContext';

const Services = () => {
  const { selectedBranchId } = useBranch();
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState('catalog');
  
  // Service Catalog state
  const [serviceCatalog, setServiceCatalog] = useState([]);
  const [loadingCatalog, setLoadingCatalog] = useState(true);
  
  // Service Usage state
  const [serviceUsage, setServiceUsage] = useState([]);
  const [loadingUsage, setLoadingUsage] = useState(true);
  
  // Add Service Form state
  const [bookings, setBookings] = useState([]);
  const [loadingBookings, setLoadingBookings] = useState(false);
  const [addServiceForm, setAddServiceForm] = useState({
    booking_id: '',
    service_id: '',
    quantity: 1,
    used_on: new Date().toISOString().split('T')[0]
  });
  const [addingService, setAddingService] = useState(false);
  const [addServiceMessage, setAddServiceMessage] = useState({ type: '', text: '' });

  // Fetch service catalog from backend
  useEffect(() => {
    fetchServiceCatalog();
  }, []);

  // Fetch service usage from backend
  useEffect(() => {
    fetchServiceUsage();
  }, [selectedBranchId]);
  
  // Fetch active bookings when Add Service tab is selected
  useEffect(() => {
    if (activeTab === 'add') {
      fetchActiveBookings();
    }
  }, [activeTab, selectedBranchId]);

  const fetchServiceCatalog = async () => {
    try {
      setLoadingCatalog(true);
      const response = await fetch(apiUrl('/api/services?limit=1000'));
      const data = await response.json();
      
      if (data.success && data.data && data.data.services) {
        setServiceCatalog(data.data.services);
      }
    } catch (error) {
      console.error('Error fetching service catalog:', error);
    } finally {
      setLoadingCatalog(false);
    }
  };

  const fetchServiceUsage = async () => {
    try {
      setLoadingUsage(true);
      let url = '/api/service-usage?limit=1000';
      if (selectedBranchId !== 'All') {
        url += `&branch_id=${selectedBranchId}`;
      }
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      
      if (data.success && data.data && data.data.serviceUsages) {
        setServiceUsage(data.data.serviceUsages);
      }
    } catch (error) {
      console.error('Error fetching service usage:', error);
    } finally {
      setLoadingUsage(false);
    }
  };
  
  const fetchActiveBookings = async () => {
    try {
      setLoadingBookings(true);
      let url = '/api/bookings?limit=1000&status=Checked-In';
      if (selectedBranchId !== 'All') {
        url += `&branch_id=${selectedBranchId}`;
      }
      
      const token = user?.token;
      const response = await fetch(apiUrl(url), {
        headers: token ? { 'Authorization': `Bearer ${token}` } : {}
      });
      const data = await response.json();
      
      if (data.success && data.data && data.data.bookings) {
        setBookings(data.data.bookings);
      }
    } catch (error) {
      console.error('Error fetching bookings:', error);
    } finally {
      setLoadingBookings(false);
    }
  };
  
  const handleAddServiceSubmit = async (e) => {
    e.preventDefault();
    setAddingService(true);
    setAddServiceMessage({ type: '', text: '' });
    
    try {
      const token = user?.token;
      const response = await fetch(apiUrl('/api/service-usage'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          booking_id: parseInt(addServiceForm.booking_id),
          service_id: parseInt(addServiceForm.service_id),
          quantity: parseInt(addServiceForm.quantity),
          used_on: addServiceForm.used_on
        })
      });
      
      const data = await response.json();
      
      if (data.success) {
        setAddServiceMessage({ type: 'success', text: 'Service added successfully!' });
        // Reset form
        setAddServiceForm({
          booking_id: '',
          service_id: '',
          quantity: 1,
          used_on: new Date().toISOString().split('T')[0]
        });
        // Refresh service usage list
        fetchServiceUsage();
      } else {
        setAddServiceMessage({ type: 'danger', text: data.error || 'Failed to add service' });
      }
    } catch (error) {
      console.error('Error adding service:', error);
      setAddServiceMessage({ type: 'danger', text: 'Error adding service to booking' });
    } finally {
      setAddingService(false);
    }
  };

  return (
    <div>
      {/* Page Header */}
      <Row className="mb-4">
        <Col>
          <div className="page-header">
            <h2>Service Management</h2>
            <p style={{ marginBottom: 0 }}>Manage hotel services and track usage across all bookings</p>
          </div>
        </Col>
      </Row>

      {/* Service Statistics */}
      <Row className="mb-4">
        <Col md={4}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-primary">{serviceCatalog.length}</h4>
              <p className="mb-0">Available Services</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-info">{serviceUsage.length}</h4>
              <p className="mb-0">Total Usage Records</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-success">
                Rs {serviceUsage.reduce((sum, u) => sum + parseFloat(u.total_price || 0), 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </h4>
              <p className="mb-0">Total Revenue</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Tabs for Catalog and Usage */}
      <Card className="card-custom">
        <Card.Body>
          <Tabs activeKey={activeTab} onSelect={(k) => setActiveTab(k)} className="mb-3">
            
            {/* Service Catalog Tab */}
            <Tab eventKey="catalog" title="Service Catalog">
              {loadingCatalog ? (
                <div className="text-center py-5">
                  <Spinner animation="border" role="status">
                    <span className="visually-hidden">Loading...</span>
                  </Spinner>
                </div>
              ) : (
                <div className="table-container">
                  <Table responsive hover className="mb-0">
                    <thead className="table-light">
                      <tr>
                        <th>Code</th>
                        <th>Service Name</th>
                        <th>Category</th>
                        <th>Unit Price (Rs)</th>
                        <th>Tax Rate (%)</th>
                        <th>Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {serviceCatalog.map((service) => (
                        <tr key={service.service_id}>
                          <td><strong>{service.code}</strong></td>
                          <td>{service.name}</td>
                          <td>
                            <Badge bg="info">{service.category}</Badge>
                          </td>
                          <td className="text-end">
                            {parseFloat(service.unit_price).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                          </td>
                          <td className="text-center">
                            {parseFloat(service.tax_rate_percent).toFixed(2)}%
                          </td>
                          <td>
                            {service.active ? (
                              <Badge bg="success">Active</Badge>
                            ) : (
                              <Badge bg="secondary">Inactive</Badge>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </Table>
                  {serviceCatalog.length === 0 && (
                    <div className="text-center py-4 text-muted">
                      No services in catalog
                    </div>
                  )}
                </div>
              )}
            </Tab>

            {/* Service Usage Tab */}
            <Tab eventKey="usage" title="Service Usage History">
              {loadingUsage ? (
                <div className="text-center py-5">
                  <Spinner animation="border" role="status">
                    <span className="visually-hidden">Loading...</span>
                  </Spinner>
                </div>
              ) : (
                <div className="table-container">
                  <Table responsive hover className="mb-0">
                    <thead className="table-light">
                      <tr>
                        <th>Date Used</th>
                        <th>Service</th>
                        <th>Category</th>
                        <th>Guest Name</th>
                        <th>Room</th>
                        <th>Qty</th>
                        <th>Unit Price (Rs)</th>
                        <th>Total (Rs)</th>
                        <th>Booking Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {serviceUsage.map((usage) => (
                        <tr key={usage.service_usage_id}>
                          <td>{new Date(usage.used_on).toLocaleDateString()}</td>
                          <td><strong>{usage.service_name}</strong></td>
                          <td>
                            <Badge bg="secondary">{usage.service_category}</Badge>
                          </td>
                          <td>{usage.guest_name}</td>
                          <td>{usage.room_number}</td>
                          <td className="text-center">{usage.qty}</td>
                          <td className="text-end">
                            {parseFloat(usage.unit_price_at_use).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                          </td>
                          <td className="text-end">
                            <strong>{parseFloat(usage.total_price_billed || usage.total_price).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</strong>
                          </td>
                          <td>
                            <Badge bg={
                              usage.booking_status === 'Checked-In' ? 'success' :
                              usage.booking_status === 'Checked-Out' ? 'secondary' :
                              usage.booking_status === 'Cancelled' ? 'danger' :
                              'primary'
                            }>
                              {usage.booking_status}
                            </Badge>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </Table>
                  {serviceUsage.length === 0 && (
                    <div className="text-center py-4 text-muted">
                      No service usage records
                    </div>
                  )}
                </div>
              )}
            </Tab>
            
            {/* Add Service Tab */}
            <Tab eventKey="add" title="Add Service to Booking">
              <Row>
                <Col md={8} className="mx-auto">
                  {addServiceMessage.text && (
                    <Alert variant={addServiceMessage.type} onClose={() => setAddServiceMessage({ type: '', text: '' })} dismissible>
                      {addServiceMessage.text}
                    </Alert>
                  )}
                  
                  <Form onSubmit={handleAddServiceSubmit}>
                    <Form.Group className="mb-3">
                      <Form.Label>Select Booking (Checked-In Only)</Form.Label>
                      <Form.Select
                        value={addServiceForm.booking_id}
                        onChange={(e) => setAddServiceForm({ ...addServiceForm, booking_id: e.target.value })}
                        required
                        disabled={loadingBookings}
                      >
                        <option value="">-- Select a booking --</option>
                        {bookings.map((booking) => (
                          <option key={booking.booking_id} value={booking.booking_id}>
                            Booking #{booking.booking_id} - {booking.guest_name} - Room {booking.room_number} ({new Date(booking.check_in_date).toLocaleDateString()} - {new Date(booking.check_out_date).toLocaleDateString()})
                          </option>
                        ))}
                      </Form.Select>
                      {loadingBookings && <Form.Text className="text-muted">Loading bookings...</Form.Text>}
                      {!loadingBookings && bookings.length === 0 && (
                        <Form.Text className="text-warning">No checked-in bookings available</Form.Text>
                      )}
                    </Form.Group>
                    
                    <Form.Group className="mb-3">
                      <Form.Label>Select Service</Form.Label>
                      <Form.Select
                        value={addServiceForm.service_id}
                        onChange={(e) => setAddServiceForm({ ...addServiceForm, service_id: e.target.value })}
                        required
                      >
                        <option value="">-- Select a service --</option>
                        {serviceCatalog.filter(s => s.active).map((service) => (
                          <option key={service.service_id} value={service.service_id}>
                            {service.name} - Rs {parseFloat(service.unit_price).toFixed(2)} ({service.category})
                          </option>
                        ))}
                      </Form.Select>
                    </Form.Group>
                    
                    <Row>
                      <Col md={6}>
                        <Form.Group className="mb-3">
                          <Form.Label>Quantity</Form.Label>
                          <Form.Control
                            type="number"
                            min="1"
                            value={addServiceForm.quantity}
                            onChange={(e) => setAddServiceForm({ ...addServiceForm, quantity: e.target.value })}
                            required
                          />
                        </Form.Group>
                      </Col>
                      <Col md={6}>
                        <Form.Group className="mb-3">
                          <Form.Label>Date Used</Form.Label>
                          <Form.Control
                            type="date"
                            value={addServiceForm.used_on}
                            onChange={(e) => setAddServiceForm({ ...addServiceForm, used_on: e.target.value })}
                            required
                          />
                        </Form.Group>
                      </Col>
                    </Row>
                    
                    {addServiceForm.service_id && addServiceForm.quantity > 0 && (
                      <Alert variant="info">
                        <strong>Total Cost: Rs {(
                          parseFloat(serviceCatalog.find(s => s.service_id === parseInt(addServiceForm.service_id))?.unit_price || 0) * 
                          parseInt(addServiceForm.quantity)
                        ).toFixed(2)}</strong>
                      </Alert>
                    )}
                    
                    <div className="d-grid gap-2">
                      <Button 
                        variant="primary" 
                        type="submit" 
                        size="lg"
                        disabled={addingService || !addServiceForm.booking_id || !addServiceForm.service_id}
                      >
                        {addingService ? (
                          <>
                            <Spinner animation="border" size="sm" className="me-2" />
                            Adding Service...
                          </>
                        ) : (
                          'Add Service to Booking'
                        )}
                      </Button>
                    </div>
                  </Form>
                </Col>
              </Row>
            </Tab>

          </Tabs>
        </Card.Body>
      </Card>
    </div>
  );
};

export default Services;
