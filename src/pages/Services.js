import React, { useState } from 'react';
import { Row, Col, Card, Button, Modal, Form, Table, Badge } from 'react-bootstrap';
import { FaPlus, FaEdit, FaConciergeBell, FaUtensils, FaCar, FaSpa, FaCheck, FaTimes } from 'react-icons/fa';

const Services = () => {
  const [showModal, setShowModal] = useState(false);
  const [selectedService, setSelectedService] = useState(null);
  const [filterStatus, setFilterStatus] = useState('All');

  // Sample service data
  const [services, setServices] = useState([
    {
      id: 1,
      guestName: 'John Doe',
      roomNumber: '101',
      serviceType: 'Room Service',
      description: 'Breakfast delivery',
      requestTime: '2025-09-14 08:30',
      status: 'Pending',
      priority: 'Normal',
      assignedTo: 'Staff 1'
    },
    {
      id: 2,
      guestName: 'Jane Smith',
      roomNumber: '205',
      serviceType: 'Housekeeping',
      description: 'Extra towels and cleaning',
      requestTime: '2025-09-14 10:15',
      status: 'In Progress',
      priority: 'High',
      assignedTo: 'Staff 2'
    },
    {
      id: 3,
      guestName: 'Mike Johnson',
      roomNumber: '308',
      serviceType: 'Concierge',
      description: 'Restaurant reservation assistance',
      requestTime: '2025-09-14 14:20',
      status: 'Completed',
      priority: 'Normal',
      assignedTo: 'Staff 3'
    },
    {
      id: 4,
      guestName: 'Sarah Wilson',
      roomNumber: '102',
      serviceType: 'Transportation',
      description: 'Airport shuttle service',
      requestTime: '2025-09-14 16:00',
      status: 'Pending',
      priority: 'High',
      assignedTo: 'Driver 1'
    }
  ]);

  const handleShowModal = (service = null) => {
    setSelectedService(service);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedService(null);
  };

  const getStatusBadge = (status) => {
    const statusClasses = {
      'Pending': 'bg-warning',
      'In Progress': 'bg-primary',
      'Completed': 'bg-success',
      'Cancelled': 'bg-danger'
    };
    return <Badge className={statusClasses[status]}>{status}</Badge>;
  };

  const getPriorityBadge = (priority) => {
    const priorityClasses = {
      'Low': 'bg-secondary',
      'Normal': 'bg-info',
      'High': 'bg-warning',
      'Urgent': 'bg-danger'
    };
    return <Badge className={priorityClasses[priority]}>{priority}</Badge>;
  };

  const getServiceIcon = (serviceType) => {
    const icons = {
      'Room Service': <FaUtensils />,
      'Housekeeping': <FaConciergeBell />,
      'Concierge': <FaConciergeBell />,
      'Transportation': <FaCar />,
      'Spa': <FaSpa />
    };
    return icons[serviceType] || <FaConciergeBell />;
  };

  const filteredServices = services.filter(service => 
    filterStatus === 'All' || service.status === filterStatus
  );

  const serviceStats = {
    total: services.length,
    pending: services.filter(s => s.status === 'Pending').length,
    inProgress: services.filter(s => s.status === 'In Progress').length,
    completed: services.filter(s => s.status === 'Completed').length
  };

  return (
    <div>
      <Row className="mb-4">
        <Col>
          <h2>Service Management</h2>
        </Col>
        <Col xs="auto">
          <Button 
            variant="primary" 
            onClick={() => handleShowModal()}
            className="btn-primary-custom"
          >
            <FaPlus className="me-2" />
            New Service Request
          </Button>
        </Col>
      </Row>

      {/* Service Statistics */}
      <Row className="mb-4">
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-primary">{serviceStats.total}</h4>
              <p className="mb-0">Total Requests</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-warning">{serviceStats.pending}</h4>
              <p className="mb-0">Pending</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-info">{serviceStats.inProgress}</h4>
              <p className="mb-0">In Progress</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="card-custom text-center">
            <Card.Body>
              <h4 className="text-success">{serviceStats.completed}</h4>
              <p className="mb-0">Completed</p>
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
                <option value="All">All Services</option>
                <option value="Pending">Pending</option>
                <option value="In Progress">In Progress</option>
                <option value="Completed">Completed</option>
                <option value="Cancelled">Cancelled</option>
              </Form.Select>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Service List */}
      <Card className="card-custom">
        <Card.Header>
          <h5 className="mb-0">Service Requests</h5>
        </Card.Header>
        <Card.Body className="p-0">
          <div className="table-container">
            <Table responsive hover className="mb-0">
              <thead className="table-light">
                <tr>
                  <th>Service Type</th>
                  <th>Guest</th>
                  <th>Room</th>
                  <th>Description</th>
                  <th>Request Time</th>
                  <th>Priority</th>
                  <th>Assigned To</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredServices.map((service) => (
                  <tr key={service.id}>
                    <td>
                      <div className="d-flex align-items-center">
                        {getServiceIcon(service.serviceType)}
                        <span className="ms-2">{service.serviceType}</span>
                      </div>
                    </td>
                    <td>{service.guestName}</td>
                    <td>{service.roomNumber}</td>
                    <td>{service.description}</td>
                    <td>{service.requestTime}</td>
                    <td>{getPriorityBadge(service.priority)}</td>
                    <td>{service.assignedTo}</td>
                    <td>{getStatusBadge(service.status)}</td>
                    <td>
                      <Button
                        variant="outline-primary"
                        size="sm"
                        className="me-2"
                        onClick={() => handleShowModal(service)}
                      >
                        <FaEdit />
                      </Button>
                      {service.status !== 'Completed' && (
                        <>
                          <Button variant="outline-success" size="sm" className="me-1">
                            <FaCheck />
                          </Button>
                          <Button variant="outline-danger" size="sm">
                            <FaTimes />
                          </Button>
                        </>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </Table>
          </div>
        </Card.Body>
      </Card>

      {/* Add/Edit Service Modal */}
      <Modal show={showModal} onHide={handleCloseModal} size="lg">
        <Modal.Header closeButton>
          <Modal.Title>
            {selectedService ? 'Edit Service Request' : 'New Service Request'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Guest Name</Form.Label>
                  <Form.Select defaultValue={selectedService?.guestName || ''}>
                    <option value="">Select Guest</option>
                    <option value="John Doe">John Doe</option>
                    <option value="Jane Smith">Jane Smith</option>
                    <option value="Mike Johnson">Mike Johnson</option>
                    <option value="Sarah Wilson">Sarah Wilson</option>
                  </Form.Select>
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Room Number</Form.Label>
                  <Form.Select defaultValue={selectedService?.roomNumber || ''}>
                    <option value="">Select Room</option>
                    <option value="101">101</option>
                    <option value="102">102</option>
                    <option value="205">205</option>
                    <option value="308">308</option>
                  </Form.Select>
                </Form.Group>
              </Col>
            </Row>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Service Type</Form.Label>
                  <Form.Select defaultValue={selectedService?.serviceType || ''}>
                    <option value="">Select Service Type</option>
                    <option value="Room Service">Room Service</option>
                    <option value="Housekeeping">Housekeeping</option>
                    <option value="Concierge">Concierge</option>
                    <option value="Transportation">Transportation</option>
                    <option value="Spa">Spa</option>
                    <option value="Maintenance">Maintenance</option>
                  </Form.Select>
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Priority</Form.Label>
                  <Form.Select defaultValue={selectedService?.priority || ''}>
                    <option value="Low">Low</option>
                    <option value="Normal">Normal</option>
                    <option value="High">High</option>
                    <option value="Urgent">Urgent</option>
                  </Form.Select>
                </Form.Group>
              </Col>
            </Row>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Assigned To</Form.Label>
                  <Form.Select defaultValue={selectedService?.assignedTo || ''}>
                    <option value="">Select Staff Member</option>
                    <option value="Staff 1">Staff 1</option>
                    <option value="Staff 2">Staff 2</option>
                    <option value="Staff 3">Staff 3</option>
                    <option value="Driver 1">Driver 1</option>
                  </Form.Select>
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Status</Form.Label>
                  <Form.Select defaultValue={selectedService?.status || ''}>
                    <option value="Pending">Pending</option>
                    <option value="In Progress">In Progress</option>
                    <option value="Completed">Completed</option>
                    <option value="Cancelled">Cancelled</option>
                  </Form.Select>
                </Form.Group>
              </Col>
            </Row>
            <Form.Group className="mb-3">
              <Form.Label>Description</Form.Label>
              <Form.Control
                as="textarea"
                rows={3}
                placeholder="Enter service description"
                defaultValue={selectedService?.description || ''}
              />
            </Form.Group>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal}>
            Cancel
          </Button>
          <Button variant="primary" className="btn-primary-custom">
            {selectedService ? 'Update Service' : 'Create Service Request'}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default Services;