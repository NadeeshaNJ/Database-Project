import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Button, Modal, Form, Table, Badge, Spinner, Alert } from 'react-bootstrap';
import { FaPlus, FaEdit, FaTrash, FaUserTie } from 'react-icons/fa';
import { useBranch } from '../context/BranchContext';
import { employeeAPI } from '../services/api';

const Employees = () => {
  const { selectedBranchId } = useBranch();
  const [employees, setEmployees] = useState([]);
  const [branches, setBranches] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [showModal, setShowModal] = useState(false);
  const [selectedEmployee, setSelectedEmployee] = useState(null);
  const [formData, setFormData] = useState({
    user_id: '',
    branch_id: '',
    name: '',
    email: '',
    contact_no: ''
  });

  useEffect(() => {
    fetchEmployees();
    fetchBranches();
  }, [selectedBranchId]);

  const fetchEmployees = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const params = { limit: 1000 };
      if (selectedBranchId && selectedBranchId !== 'All') {
        params.branch_id = selectedBranchId;
      }
      
      const response = await employeeAPI.getAllEmployees(params);
      
      if (response.data.success && response.data.data && response.data.data.employees) {
        setEmployees(response.data.data.employees);
      } else {
        setError('No employees found');
        setEmployees([]);
      }
    } catch (err) {
      console.error('Error fetching employees:', err);
      setError(err.response?.data?.error || 'Failed to load employees. Please check backend connection.');
      setEmployees([]);
    } finally {
      setLoading(false);
    }
  };

  const fetchBranches = async () => {
    try {
      const apiClient = (await import('../services/apiClient')).default;
      const response = await apiClient.get('/branches');
      if (response.data.success && response.data.data) {
        setBranches(response.data.data.branches || []);
      }
    } catch (err) {
      console.error('Error fetching branches:', err);
    }
  };

  const handleShowModal = (employee = null) => {
    if (employee) {
      setSelectedEmployee(employee);
      setFormData({
        user_id: employee.user_id || '',
        branch_id: employee.branch_id || '',
        name: employee.name || '',
        email: employee.email || '',
        contact_no: employee.contact_no || ''
      });
    } else {
      setSelectedEmployee(null);
      setFormData({
        user_id: '',
        branch_id: '',
        name: '',
        email: '',
        contact_no: ''
      });
    }
    setShowModal(true);
    setError(null);
    setSuccess(null);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedEmployee(null);
    setFormData({
      user_id: '',
      branch_id: '',
      name: '',
      email: '',
      contact_no: ''
    });
    setError(null);
    setSuccess(null);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);

    try {
      if (selectedEmployee) {
        // Update existing employee
        await employeeAPI.updateEmployee(selectedEmployee.employee_id, formData);
        setSuccess('Employee updated successfully!');
      } else {
        // Create new employee
        await employeeAPI.createEmployee(formData);
        setSuccess('Employee created successfully!');
      }
      
      // Refresh the employee list
      await fetchEmployees();
      
      // Close modal after a short delay
      setTimeout(() => {
        handleCloseModal();
      }, 1500);
    } catch (err) {
      console.error('Error saving employee:', err);
      setError(err.response?.data?.error || 'Failed to save employee');
    }
  };

  const handleDelete = async (employeeId) => {
    if (!window.confirm('Are you sure you want to delete this employee?')) {
      return;
    }

    try {
      await employeeAPI.deleteEmployee(employeeId);
      setSuccess('Employee deleted successfully!');
      await fetchEmployees();
      setTimeout(() => setSuccess(null), 3000);
    } catch (err) {
      console.error('Error deleting employee:', err);
      setError(err.response?.data?.error || 'Failed to delete employee');
      setTimeout(() => setError(null), 3000);
    }
  };

  const getRoleBadgeColor = (role) => {
    const roleColors = {
      'Admin': 'danger',
      'Manager': 'primary',
      'Receptionist': 'info',
      'Accountant': 'success',
      'Housekeeping': 'warning',
      'Customer': 'secondary'
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
          <div className="page-header" style={{
            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
            padding: '2rem',
            borderRadius: '1rem',
            boxShadow: '0 4px 15px rgba(0,0,0,0.1)',
            color: 'white'
          }}>
            <div className="d-flex justify-content-between align-items-center">
              <div>
                <h1 style={{ fontSize: '2.5rem', fontWeight: 'bold', marginBottom: '8px' }}>
                  <FaUserTie className="me-2" />
                  Employee Management
                </h1>
                <p style={{ marginBottom: 0, color: 'rgba(255, 255, 255, 0.9)' }}>
                  Manage employees working at {selectedBranchId === 'All' ? 'all branches' : `Branch ${selectedBranchId}`}
                </p>
              </div>
              <Button 
                onClick={() => handleShowModal()}
                style={{
                  background: 'white',
                  color: '#1a237e',
                  border: 'none',
                  fontWeight: '600',
                  padding: '0.75rem 1.5rem',
                  boxShadow: '0 4px 10px rgba(0,0,0,0.2)',
                  transition: 'all 0.3s ease'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.transform = 'translateY(-2px)';
                  e.currentTarget.style.boxShadow = '0 6px 15px rgba(0,0,0,0.3)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.transform = 'translateY(0)';
                  e.currentTarget.style.boxShadow = '0 4px 10px rgba(0,0,0,0.2)';
                }}
              >
                <FaPlus className="me-2" />
                Add New Employee
              </Button>
            </div>
          </div>
        </Col>
      </Row>

      {error && !showModal && <Alert variant="danger" dismissible onClose={() => setError(null)}>{error}</Alert>}
      {success && !showModal && <Alert variant="success" dismissible onClose={() => setSuccess(null)}>{success}</Alert>}

      {/* Employee Statistics */}
      <Row className="mb-4">
        <Col md={2}>
          <Card className="text-center h-100" style={{
            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
            border: 'none',
            borderRadius: '1rem',
            boxShadow: '0 4px 15px rgba(26, 35, 126, 0.3)',
            transition: 'transform 0.3s ease, box-shadow 0.3s ease'
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'translateY(-5px)';
            e.currentTarget.style.boxShadow = '0 8px 25px rgba(26, 35, 126, 0.4)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 4px 15px rgba(26, 35, 126, 0.3)';
          }}>
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
          <Card className="text-center h-100" style={{
            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
            border: 'none',
            borderRadius: '1rem',
            boxShadow: '0 4px 15px rgba(26, 35, 126, 0.3)',
            transition: 'transform 0.3s ease, box-shadow 0.3s ease'
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'translateY(-5px)';
            e.currentTarget.style.boxShadow = '0 8px 25px rgba(26, 35, 126, 0.4)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 4px 15px rgba(26, 35, 126, 0.3)';
          }}>
            <Card.Body style={{ padding: '24px' }}>
              <h3 style={{ color: 'white', fontWeight: 'bold', fontSize: '2rem', marginBottom: '8px' }}>
                {stats.managers}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0 }}>Managers</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={2}>
          <Card className="text-center h-100" style={{
            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
            border: 'none',
            borderRadius: '1rem',
            boxShadow: '0 4px 15px rgba(26, 35, 126, 0.3)',
            transition: 'transform 0.3s ease, box-shadow 0.3s ease'
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'translateY(-5px)';
            e.currentTarget.style.boxShadow = '0 8px 25px rgba(26, 35, 126, 0.4)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 4px 15px rgba(26, 35, 126, 0.3)';
          }}>
            <Card.Body style={{ padding: '24px' }}>
              <h3 style={{ color: 'white', fontWeight: 'bold', fontSize: '2rem', marginBottom: '8px' }}>
                {stats.receptionists}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0 }}>Receptionists</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={2}>
          <Card className="text-center h-100" style={{
            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
            border: 'none',
            borderRadius: '1rem',
            boxShadow: '0 4px 15px rgba(26, 35, 126, 0.3)',
            transition: 'transform 0.3s ease, box-shadow 0.3s ease'
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'translateY(-5px)';
            e.currentTarget.style.boxShadow = '0 8px 25px rgba(26, 35, 126, 0.4)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 4px 15px rgba(26, 35, 126, 0.3)';
          }}>
            <Card.Body style={{ padding: '24px' }}>
              <h3 style={{ color: 'white', fontWeight: 'bold', fontSize: '2rem', marginBottom: '8px' }}>
                {stats.accountants}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0 }}>Accountants</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={2}>
          <Card className="text-center h-100" style={{
            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
            border: 'none',
            borderRadius: '1rem',
            boxShadow: '0 4px 15px rgba(26, 35, 126, 0.3)',
            transition: 'transform 0.3s ease, box-shadow 0.3s ease'
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'translateY(-5px)';
            e.currentTarget.style.boxShadow = '0 8px 25px rgba(26, 35, 126, 0.4)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 4px 15px rgba(26, 35, 126, 0.3)';
          }}>
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
      <Card style={{ border: 'none', borderRadius: '1rem', boxShadow: '0 4px 15px rgba(0,0,0,0.1)' }}>
        <Card.Header style={{ 
          background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)', 
          borderBottom: 'none',
          borderRadius: '1rem 1rem 0 0',
          padding: '1.5rem'
        }}>
          <h5 className="mb-0" style={{ fontWeight: '700', color: 'white' }}>
            Employee List ({employees.length})
          </h5>
        </Card.Header>
        <Card.Body className="p-0">
          {loading ? (
            <div className="text-center py-5">
              <Spinner animation="border" style={{ color: '#1976d2', width: '3rem', height: '3rem' }} />
              <p className="mt-2" style={{ color: '#1976d2' }}>Loading employees...</p>
            </div>
          ) : employees.length === 0 ? (
            <div className="text-center py-5">
              <p className="text-muted">No employees found</p>
            </div>
          ) : (
            <Table responsive hover className="mb-0">
              <thead style={{ 
                background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                borderBottom: '2px solid #0d47a1' 
              }}>
                <tr>
                  <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>ID</th>
                  <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Name</th>
                  <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Email</th>
                  <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Phone</th>
                  <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Branch</th>
                  <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Role</th>
                  <th style={{ padding: '16px', fontWeight: '600', color: 'white', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Actions</th>
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
                    <td style={{ padding: '16px' }}>
                      <Button
                        variant="outline-primary"
                        size="sm"
                        onClick={() => handleShowModal(employee)}
                        className="me-2"
                      >
                        <FaEdit />
                      </Button>
                      <Button 
                        variant="outline-danger" 
                        size="sm"
                        onClick={() => handleDelete(employee.employee_id)}
                      >
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
        <Modal.Header closeButton style={{
          background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
          color: 'white',
          border: 'none'
        }}>
          <Modal.Title style={{ color: 'white', fontWeight: '600' }}>
            {selectedEmployee ? 'Edit Employee' : 'Add New Employee'}
          </Modal.Title>
        </Modal.Header>
        <Form onSubmit={handleSubmit}>
          <Modal.Body>
            {error && <Alert variant="danger">{error}</Alert>}
            {success && <Alert variant="success">{success}</Alert>}
            
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Full Name <span className="text-danger">*</span></Form.Label>
                  <Form.Control 
                    type="text" 
                    name="name"
                    placeholder="Enter full name" 
                    value={formData.name}
                    onChange={handleInputChange}
                    required
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Email</Form.Label>
                  <Form.Control 
                    type="email" 
                    name="email"
                    placeholder="Enter email" 
                    value={formData.email}
                    onChange={handleInputChange}
                  />
                </Form.Group>
              </Col>
            </Row>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Phone Number</Form.Label>
                  <Form.Control 
                    type="tel" 
                    name="contact_no"
                    placeholder="Enter phone number" 
                    value={formData.contact_no}
                    onChange={handleInputChange}
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Branch <span className="text-danger">*</span></Form.Label>
                  <Form.Select 
                    name="branch_id"
                    value={formData.branch_id}
                    onChange={handleInputChange}
                    required
                  >
                    <option value="">Select Branch</option>
                    {branches.map(branch => (
                      <option key={branch.branch_id} value={branch.branch_id}>
                        {branch.branch_name}
                      </option>
                    ))}
                  </Form.Select>
                </Form.Group>
              </Col>
            </Row>
            {!selectedEmployee && (
              <Row>
                <Col md={12}>
                  <Form.Group className="mb-3">
                    <Form.Label>User ID <span className="text-danger">*</span></Form.Label>
                    <Form.Control 
                      type="number" 
                      name="user_id"
                      placeholder="Enter user account ID" 
                      value={formData.user_id}
                      onChange={handleInputChange}
                      required
                    />
                    <Form.Text className="text-muted">
                      The user account must be created first in the system
                    </Form.Text>
                  </Form.Group>
                </Col>
              </Row>
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
              Cancel
            </Button>
            <Button 
              type="submit"
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
              {selectedEmployee ? 'Update Employee' : 'Add Employee'}
            </Button>
          </Modal.Footer>
        </Form>
      </Modal>
    </div>
  );
};

export default Employees;
