import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Table, Badge, Tabs, Tab, Spinner, Form } from 'react-bootstrap';
import { FaConciergeBell, FaChartLine, FaDollarSign } from 'react-icons/fa';
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
      {/* Page Header */}
      <div className="mb-4 p-4 rounded-3" style={{
        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
        color: 'white',
        boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
      }}>
        <Row className="align-items-center">
          <Col>
            <div className="d-flex align-items-center">
              <FaConciergeBell size={32} className="me-3" />
              <div>
                <h2 className="mb-0">Service Management</h2>
                <p className="mb-0 opacity-75">Manage hotel services and track usage across all bookings</p>
              </div>
            </div>
          </Col>
        </Row>
      </div>

      {/* Service Statistics */}
      <Row className="mb-4">
        <Col md={4}>
          <Card className="text-center border-0 shadow-sm" style={{
            borderRadius: '12px',
            transition: 'transform 0.3s ease, box-shadow 0.3s ease',
            cursor: 'pointer'
          }}
          onMouseOver={(e) => {
            e.currentTarget.style.transform = 'translateY(-5px)';
            e.currentTarget.style.boxShadow = '0 8px 16px rgba(0,0,0,0.1)';
          }}
          onMouseOut={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
          }}>
            <Card.Body style={{
              background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
              borderRadius: '12px',
              padding: '24px',
              color: 'white'
            }}>
              <FaConciergeBell size={32} className="mb-3" />
              <h4 style={{ fontSize: '2.5rem', fontWeight: '700', marginBottom: '8px' }}>{serviceCatalog.length}</h4>
              <p className="mb-0" style={{ fontSize: '0.95rem', opacity: 0.9 }}>Available Services</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card className="text-center border-0 shadow-sm" style={{
            borderRadius: '12px',
            transition: 'transform 0.3s ease, box-shadow 0.3s ease',
            cursor: 'pointer'
          }}
          onMouseOver={(e) => {
            e.currentTarget.style.transform = 'translateY(-5px)';
            e.currentTarget.style.boxShadow = '0 8px 16px rgba(0,0,0,0.1)';
          }}
          onMouseOut={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
          }}>
            <Card.Body style={{
              background: 'linear-gradient(135deg, #0288d1 0%, #03a9f4 100%)',
              borderRadius: '12px',
              padding: '24px',
              color: 'white'
            }}>
              <FaChartLine size={32} className="mb-3" />
              <h4 style={{ fontSize: '2.5rem', fontWeight: '700', marginBottom: '8px' }}>{serviceUsage.length}</h4>
              <p className="mb-0" style={{ fontSize: '0.95rem', opacity: 0.9 }}>Total Usage Records</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card className="text-center border-0 shadow-sm" style={{
            borderRadius: '12px',
            transition: 'transform 0.3s ease, box-shadow 0.3s ease',
            cursor: 'pointer'
          }}
          onMouseOver={(e) => {
            e.currentTarget.style.transform = 'translateY(-5px)';
            e.currentTarget.style.boxShadow = '0 8px 16px rgba(0,0,0,0.1)';
          }}
          onMouseOut={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
          }}>
            <Card.Body style={{
              background: 'linear-gradient(135deg, #388e3c 0%, #4caf50 100%)',
              borderRadius: '12px',
              padding: '24px',
              color: 'white'
            }}>
              <FaDollarSign size={32} className="mb-3" />
              <h4 style={{ fontSize: '2.5rem', fontWeight: '700', marginBottom: '8px' }}>
                Rs {serviceUsage.reduce((sum, u) => sum + parseFloat(u.total_price || 0), 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </h4>
              <p className="mb-0" style={{ fontSize: '0.95rem', opacity: 0.9 }}>Total Revenue</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Tabs for Catalog and Usage */}
      <Card className="border-0 shadow-sm" style={{ borderRadius: '12px' }}>
        <Card.Body>
          <Tabs 
            activeKey={activeTab} 
            onSelect={(k) => setActiveTab(k)} 
            className="mb-3"
            style={{
              borderBottom: '2px solid #e9ecef'
            }}
          >
            
            {/* Service Catalog Tab */}
            <Tab eventKey="catalog" title="Service Catalog">
              {loadingCatalog ? (
                <div className="text-center py-5">
                  <Spinner animation="border" role="status" style={{ color: '#1a237e' }}>
                    <span className="visually-hidden">Loading...</span>
                  </Spinner>
                  <p className="mt-3" style={{ color: '#1a237e', fontWeight: '500' }}>Loading service catalog...</p>
                </div>
              ) : (
                <div className="table-container">
                  <Table responsive hover className="mb-0">
                    <thead style={{
                      background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                      color: 'white'
                    }}>
                      <tr>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Code</th>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Service Name</th>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Category</th>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Unit Price (Rs)</th>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Tax Rate (%)</th>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Status</th>
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
                  <Spinner animation="border" role="status" style={{ color: '#1a237e' }}>
                    <span className="visually-hidden">Loading...</span>
                  </Spinner>
                  <p className="mt-3" style={{ color: '#1a237e', fontWeight: '500' }}>Loading service usage...</p>
                </div>
              ) : (
                <div className="table-container">
                  <Table responsive hover className="mb-0">
                    <thead style={{
                      background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                      color: 'white'
                    }}>
                      <tr>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Date Used</th>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Service</th>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Category</th>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Guest Name</th>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Room</th>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Qty</th>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Unit Price (Rs)</th>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Total (Rs)</th>
                        <th style={{ borderBottom: 'none', padding: '16px' }}>Booking Status</th>
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
