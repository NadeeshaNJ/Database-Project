import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Table, Badge, Tabs, Tab, Spinner, Form } from 'react-bootstrap';
import { apiUrl } from '../utils/api';
import { useBranch } from '../context/BranchContext';

const Services = () => {
  const { selectedBranchId } = useBranch();
  const [activeTab, setActiveTab] = useState('catalog');
  
  // Service Catalog state
  const [serviceCatalog, setServiceCatalog] = useState([]);
  const [loadingCatalog, setLoadingCatalog] = useState(true);
  
  // Service Usage state
  const [serviceUsage, setServiceUsage] = useState([]);
  const [loadingUsage, setLoadingUsage] = useState(true);

  // Fetch service catalog from backend
  useEffect(() => {
    fetchServiceCatalog();
  }, []);

  // Fetch service usage from backend
  useEffect(() => {
    fetchServiceUsage();
  }, [selectedBranchId]);

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

  return (
    <div>
      <Row className="mb-4">
        <Col>
          <h2>Service Management</h2>
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
                            <strong>{parseFloat(usage.total_price).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</strong>
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

          </Tabs>
        </Card.Body>
      </Card>
    </div>
  );
};

export default Services;
