import React, { useState, useEffect } from 'react';
import { Modal, Table, Badge, Spinner, Form, Row, Col } from 'react-bootstrap';
import { apiUrl } from '../../utils/api';
import { useBranch } from '../../context/BranchContext';

const RoomStatusModal = ({ show, onHide }) => {
  const { selectedBranchId } = useBranch();
  const [rooms, setRooms] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState('All');
  const [filterType, setFilterType] = useState('All');

  useEffect(() => {
    if (show) {
      fetchRooms();
    }
  }, [show, selectedBranchId]);

  const fetchRooms = async () => {
    try {
      setLoading(true);
      let url = '/api/rooms?limit=1000';
      if (selectedBranchId !== 'All') {
        url += `&branch_id=${selectedBranchId}`;
      }
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      
      if (data.success && data.data && data.data.rooms) {
        setRooms(data.data.rooms);
      }
    } catch (err) {
      console.error('Error fetching rooms:', err);
    } finally {
      setLoading(false);
    }
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

  // Filter rooms
  let filteredRooms = rooms;
  if (filterStatus !== 'All') {
    filteredRooms = filteredRooms.filter(room => room.status === filterStatus);
  }
  if (filterType !== 'All') {
    filteredRooms = filteredRooms.filter(room => room.room_type_name === filterType);
  }

  // Statistics
  const totalRooms = rooms.length;
  const availableRooms = rooms.filter(room => room.status === 'Available').length;
  const occupiedRooms = rooms.filter(room => room.status === 'Occupied').length;
  const occupancyRate = totalRooms > 0 ? Math.round((occupiedRooms / totalRooms) * 100) : 0;

  return (
    <Modal show={show} onHide={onHide} size="xl">
      <Modal.Header closeButton>
        <Modal.Title>Room Status Overview</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        {loading ? (
          <div className="text-center py-5">
            <Spinner animation="border" />
            <p className="mt-3">Loading room status...</p>
          </div>
        ) : (
          <>
            {/* Statistics */}
            <Row className="mb-4">
              <Col md={3}>
                <div className="text-center p-3 bg-light rounded">
                  <h4 className="text-primary mb-0">{totalRooms}</h4>
                  <small className="text-muted">Total Rooms</small>
                </div>
              </Col>
              <Col md={3}>
                <div className="text-center p-3 bg-light rounded">
                  <h4 className="text-success mb-0">{availableRooms}</h4>
                  <small className="text-muted">Available</small>
                </div>
              </Col>
              <Col md={3}>
                <div className="text-center p-3 bg-light rounded">
                  <h4 className="text-info mb-0">{occupiedRooms}</h4>
                  <small className="text-muted">Occupied</small>
                </div>
              </Col>
              <Col md={3}>
                <div className="text-center p-3 bg-light rounded">
                  <h4 className="text-warning mb-0">{occupancyRate}%</h4>
                  <small className="text-muted">Occupancy Rate</small>
                </div>
              </Col>
            </Row>

            {/* Filters */}
            <Row className="mb-3">
              <Col md={6}>
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
              <Col md={6}>
                <Form.Group>
                  <Form.Label>Filter by Type</Form.Label>
                  <Form.Select value={filterType} onChange={(e) => setFilterType(e.target.value)}>
                    <option value="All">All Types</option>
                    <option value="Standard Single">Standard Single</option>
                    <option value="Standard Double">Standard Double</option>
                    <option value="Deluxe King">Deluxe King</option>
                    <option value="Suite">Suite</option>
                  </Form.Select>
                </Form.Group>
              </Col>
            </Row>

            {/* Room Table */}
            <div style={{ maxHeight: '400px', overflowY: 'auto' }}>
              <Table striped hover responsive>
                <thead className="table-light" style={{ position: 'sticky', top: 0, zIndex: 1 }}>
                  <tr>
                    <th>Room #</th>
                    <th>Type</th>
                    <th>Branch</th>
                    <th>Capacity</th>
                    <th>Rate/Night</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredRooms.map((room) => (
                    <tr key={room.room_id}>
                      <td><strong>{room.room_number}</strong></td>
                      <td>{room.room_type_name}</td>
                      <td>{room.branch_name}</td>
                      <td>{room.capacity}</td>
                      <td>Rs {parseFloat(room.daily_rate).toLocaleString()}</td>
                      <td>
                        <Badge bg={getStatusColor(room.status)}>
                          {room.status}
                        </Badge>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </Table>
              {filteredRooms.length === 0 && (
                <div className="text-center py-4 text-muted">
                  No rooms match the selected filters
                </div>
              )}
            </div>

            <div className="mt-3 text-muted text-center">
              Showing {filteredRooms.length} of {totalRooms} rooms
            </div>
          </>
        )}
      </Modal.Body>
    </Modal>
  );
};

export default RoomStatusModal;
