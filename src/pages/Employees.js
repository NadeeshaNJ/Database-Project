import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Button, Modal, Form, Table, Badge, Spinner, Alert } from 'react-bootstrap';
import { FaPlus, FaEdit, FaTrash, FaUserTie } from 'react-icons/fa';
import { useBranch } from '../context/BranchContext';
import { apiUrl } from '../utils/api';

const Employees = () => {
  const { selectedBranchId } = useBranch();
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showModal, setShowModal] = useState(false);
  const [selectedEmployee, setSelectedEmployee] = useState(null);

  useEffect(() => {
    fetchEmployees();
  }, [selectedBranchId]);

  const fetchEmployees = async () => {
    try {
      setLoading(true);
      setError(null);
      
      let url = '/api/employees?limit=1000';
      if (selectedBranchId !== 'All') {
        url += `&branch_id=${selectedBranchId}`;
      }
      
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      
      if (data.success && data.data && data.data.employees) {
        setEmployees(data.data.employees);
      } else {
        setError('No employees found');
      }
    } catch (err) {
      console.error('Error fetching employees:', err);
      setError('Failed to load employees. Please check backend connection.');
    } finally {
      setLoading(false);
    }
  };

  const handleShowModal = (employee = null) => {
    setSelectedEmployee(employee);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedEmployee(null);
  };

  const getRoleBadgeColor = (role) => {
    const roleColors = {
      'Admin': 'danger',
      'Manager': 'primary',
      'Receptionist': 'info',
      'Accountant': 'success',
      'Housekeeping': 'warning'
    };
    return roleColors[role] || 'secondary';
  };

  const getEmployeeStats = () => {
    const stats = {
      total: employees.length,
      managers: employees.filter(e => e.role === 'Manager').length,
      receptionists: employees.filter(e => e.role === 'Receptionist').length,
      accountants: employees.filter(e => e.role === 'Accountant').length,
      housekeeping: employees.filter(e => e.role === 'Housekeeping').length
    };
    return stats;
  };

  const stats = getEmployeeStats();

  return (
    <div>
      {/* Page Header */}
      <Row className="mb-4">
        <Col>
          <div className="page-header">
            <div className="d-flex justify-content-between align-items-center">
              <div>
                <h2>Employee Management</h2>
                <p style={{ marginBottom: 0 }}>
                  Manage employees working at {selectedBranchId === 'All' ? 'all branches' : `Branch ${selectedBranchId}`}
                </p>
              </div>
              <Button variant="primary" onClick={() => handleShowModal()}>
                <FaPlus className="me-2" />
                Add New Employee
              </Button>
            </div>
          </div>
        </Col>
      </Row>

      {error && <Alert variant="warning">{error}</Alert>}

      {/* Employee Statistics */}
      <Row className="mb-4">
        <Col md={2}>
          <Card className="stat-card text-center h-100">
            <Card.Body style={{ padding: '24px' }}>
              <FaUserTie style={{ color: 'white', marginBottom: '12px' }} size={32} />
              <h3 style={{ color: 'white', fontWeight: 'bold', fontSize: '2rem', marginBottom: '8px' }}>
                {stats.total}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0 }}>Total Employees</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={2}>
          <Card className="stat-card text-center h-100">
            <Card.Body style={{ padding: '24px' }}>
              <h3 style={{ color: 'white', fontWeight: 'bold', fontSize: '2rem', marginBottom: '8px' }}>
                {stats.managers}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0 }}>Managers</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={2}>
          <Card className="stat-card text-center h-100">
            <Card.Body style={{ padding: '24px' }}>
              <h3 style={{ color: 'white', fontWeight: 'bold', fontSize: '2rem', marginBottom: '8px' }}>
                {stats.receptionists}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0 }}>Receptionists</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={2}>
          <Card className="stat-card text-center h-100">
            <Card.Body style={{ padding: '24px' }}>
              <h3 style={{ color: 'white', fontWeight: 'bold', fontSize: '2rem', marginBottom: '8px' }}>
                {stats.accountants}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0 }}>Accountants</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={2}>
          <Card className="stat-card text-center h-100">
            <Card.Body style={{ padding: '24px' }}>
              <h3 style={{ color: 'white', fontWeight: 'bold', fontSize: '2rem', marginBottom: '8px' }}>
                {stats.housekeeping}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0 }}>Housekeeping</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Employee List */}
      <Card>
        <Card.Header style={{ background: '#f8f9fa', borderBottom: '1px solid #e0e6ed' }}>
          <h5 className="mb-0" style={{ fontWeight: '700', color: '#2c3e50' }}>
            Employee List ({employees.length})
          </h5>
        </Card.Header>
        <Card.Body className="p-0">
          {loading ? (
            <div className="text-center py-5">
              <Spinner animation="border" variant="primary" />
              <p className="mt-2 text-muted">Loading employees...</p>
            </div>
          ) : (
            <Table responsive hover className="mb-0">
              <thead style={{ backgroundColor: '#f8f9fa', borderBottom: '2px solid #e0e6ed' }}>
                <tr>
                  <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>ID</th>
                  <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Name</th>
                  <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Email</th>
                  <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Phone</th>
                  <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Branch</th>
                  <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Role</th>
                  <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Hire Date</th>
                  <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {employees.map((employee) => (
                  <tr key={employee.employee_id} style={{ borderBottom: '1px solid #e0e6ed' }}>
                    <td style={{ padding: '16px', color: '#2c3e50', fontWeight: '500' }}>
                      EMP{String(employee.employee_id).padStart(3, '0')}
                    </td>
                    <td style={{ padding: '16px', color: '#2c3e50', fontWeight: '500' }}>{employee.name}</td>
                    <td style={{ padding: '16px', color: '#2c3e50', fontWeight: '500' }}>{employee.email || 'N/A'}</td>
                    <td style={{ padding: '16px', color: '#2c3e50', fontWeight: '500' }}>{employee.contact_no || 'N/A'}</td>
                    <td style={{ padding: '16px', color: '#2c3e50', fontWeight: '500' }}>
                      {employee.branch_name || `Branch ${employee.branch_id}`}
                    </td>
                    <td style={{ padding: '16px' }}>
                      <Badge bg={getRoleBadgeColor(employee.role || 'Staff')}>
                        {employee.role || 'Staff'}
                      </Badge>
                    </td>
                    <td style={{ padding: '16px', color: '#2c3e50', fontWeight: '500' }}>
                      {employee.hire_date ? new Date(employee.hire_date).toLocaleDateString() : 'N/A'}
                    </td>
                    <td style={{ padding: '16px' }}>
                      <Button
                        variant="outline-primary"
                        size="sm"
                        onClick={() => handleShowModal(employee)}
                        className="me-2"
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
          )}
        </Card.Body>
      </Card>

      {/* Add/Edit Employee Modal */}
      <Modal show={showModal} onHide={handleCloseModal} size="lg">
        <Modal.Header closeButton>
          <Modal.Title>{selectedEmployee ? 'Edit Employee' : 'Add New Employee'}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Full Name</Form.Label>
                  <Form.Control type="text" placeholder="Enter full name" />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Email</Form.Label>
                  <Form.Control type="email" placeholder="Enter email" />
                </Form.Group>
              </Col>
            </Row>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Phone Number</Form.Label>
                  <Form.Control type="tel" placeholder="Enter phone number" />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Branch</Form.Label>
                  <Form.Select>
                    <option value="">Select Branch</option>
                    <option value="1">Colombo</option>
                    <option value="2">Kandy</option>
                    <option value="3">Galle</option>
                  </Form.Select>
                </Form.Group>
              </Col>
            </Row>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Role</Form.Label>
                  <Form.Select>
                    <option value="">Select Role</option>
                    <option value="Manager">Manager</option>
                    <option value="Receptionist">Receptionist</option>
                    <option value="Accountant">Accountant</option>
                    <option value="Housekeeping">Housekeeping</option>
                  </Form.Select>
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Hire Date</Form.Label>
                  <Form.Control type="date" />
                </Form.Group>
              </Col>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal}>
            Cancel
          </Button>
          <Button variant="primary">
            {selectedEmployee ? 'Update Employee' : 'Add Employee'}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default Employees;
