import React from 'react';
import { Container, Row, Col, Card, Button, Carousel } from 'react-bootstrap';
import { useNavigate } from 'react-router-dom';
import { FaHotel, FaMapMarkerAlt, FaPhone, FaStar, FaConciergeBell, FaWifi, FaParking, FaSwimmingPool } from 'react-icons/fa';

const Landing = () => {
  const navigate = useNavigate();

  const branches = [
    {
      name: 'Colombo',
      address: '123, Galle Road, Colombo 03',
      phone: '011-234-5678',
      image: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
      description: 'Our flagship property in the heart of Colombo, offering luxury and convenience.'
    },
    {
      name: 'Kandy',
      address: '58, Temple Street, Kandy',
      phone: '081-223-4567',
      image: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800',
      description: 'Experience tranquility and cultural heritage in the hill capital of Sri Lanka.'
    },
    {
      name: 'Galle',
      address: '45, Fort Road, Galle',
      phone: '091-223-4567',
      image: 'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800',
      description: 'Beachfront luxury with stunning ocean views and colonial charm.'
    }
  ];

  const features = [
    { icon: <FaWifi size={40} />, title: 'Free WiFi', description: 'High-speed internet throughout' },
    { icon: <FaConciergeBell size={40} />, title: '24/7 Service', description: 'Round-the-clock concierge' },
    { icon: <FaParking size={40} />, title: 'Free Parking', description: 'Complimentary valet parking' },
    { icon: <FaSwimmingPool size={40} />, title: 'Pool & Spa', description: 'Luxury wellness facilities' }
  ];

  return (
    <div style={{ backgroundColor: '#f8f9fa' }}>
      {/* Hero Section */}
      <div style={{
        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
        color: 'white',
        padding: '100px 0',
        textAlign: 'center',
        position: 'relative',
        overflow: 'hidden'
      }}>
        <div style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundImage: 'url(https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=1920)',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          opacity: 0.2
        }}></div>
        
        <Container style={{ position: 'relative', zIndex: 1 }}>
          <FaHotel size={80} style={{ marginBottom: '20px' }} />
          <h1 style={{ fontSize: '4rem', fontWeight: 'bold', marginBottom: '20px' }}>
            SkyNest Hotels
          </h1>
          <p style={{ fontSize: '1.5rem', marginBottom: '30px' }}>
            Experience Luxury, Comfort & Hospitality Across Sri Lanka
          </p>
          <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center', marginTop: '40px' }}>
            <Button 
              size="lg" 
              variant="light" 
              onClick={() => navigate('/register')}
              style={{ 
                padding: '15px 40px', 
                fontSize: '1.2rem',
                fontWeight: 'bold'
              }}
            >
              Register Now
            </Button>
            <Button 
              size="lg" 
              variant="outline-light" 
              onClick={() => navigate('/login')}
              style={{ 
                padding: '15px 40px', 
                fontSize: '1.2rem',
                fontWeight: 'bold'
              }}
            >
              Login
            </Button>
          </div>
        </Container>
      </div>

      {/* Features Section */}
      <Container style={{ padding: '60px 0' }}>
        <h2 style={{ textAlign: 'center', marginBottom: '50px', fontSize: '2.5rem', fontWeight: 'bold' }}>
          Why Choose SkyNest?
        </h2>
        <Row>
          {features.map((feature, index) => (
            <Col md={3} sm={6} key={index} className="text-center mb-4">
              <div style={{ color: '#1976d2', marginBottom: '15px' }}>
                {feature.icon}
              </div>
              <h4 style={{ fontWeight: 'bold', marginBottom: '10px' }}>{feature.title}</h4>
              <p style={{ color: '#666' }}>{feature.description}</p>
            </Col>
          ))}
        </Row>
      </Container>

      {/* Branches Section */}
      <div style={{ backgroundColor: 'white', padding: '60px 0' }}>
        <Container>
          <h2 style={{ textAlign: 'center', marginBottom: '50px', fontSize: '2.5rem', fontWeight: 'bold' }}>
            Our Locations
          </h2>
          <Row>
            {branches.map((branch, index) => (
              <Col md={4} key={index} className="mb-4">
                <Card style={{ 
                  border: 'none', 
                  boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
                  height: '100%',
                  transition: 'transform 0.3s',
                  cursor: 'pointer'
                }}
                onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-10px)'}
                onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
                >
                  <div style={{ 
                    height: '250px', 
                    overflow: 'hidden',
                    borderTopLeftRadius: '0.25rem',
                    borderTopRightRadius: '0.25rem'
                  }}>
                    <img 
                      src={branch.image} 
                      alt={branch.name}
                      style={{ 
                        width: '100%', 
                        height: '100%', 
                        objectFit: 'cover' 
                      }}
                    />
                  </div>
                  <Card.Body>
                    <Card.Title style={{ fontSize: '1.8rem', fontWeight: 'bold', marginBottom: '15px' }}>
                      <FaMapMarkerAlt style={{ color: '#1976d2', marginRight: '10px' }} />
                      {branch.name}
                    </Card.Title>
                    <Card.Text style={{ color: '#666', marginBottom: '10px' }}>
                      {branch.description}
                    </Card.Text>
                    <p style={{ marginBottom: '5px' }}>
                      <strong>Address:</strong> {branch.address}
                    </p>
                    <p style={{ marginBottom: '0' }}>
                      <FaPhone style={{ marginRight: '5px' }} />
                      {branch.phone}
                    </p>
                  </Card.Body>
                </Card>
              </Col>
            ))}
          </Row>
        </Container>
      </div>

      {/* Testimonials Section */}
      <Container style={{ padding: '60px 0' }}>
        <h2 style={{ textAlign: 'center', marginBottom: '50px', fontSize: '2.5rem', fontWeight: 'bold' }}>
          What Our Guests Say
        </h2>
        <Carousel style={{ maxWidth: '800px', margin: '0 auto' }}>
          <Carousel.Item>
            <div style={{ padding: '40px', textAlign: 'center' }}>
              <div style={{ marginBottom: '20px', color: '#ffc107' }}>
                <FaStar /><FaStar /><FaStar /><FaStar /><FaStar />
              </div>
              <p style={{ fontSize: '1.2rem', fontStyle: 'italic', marginBottom: '20px' }}>
                "Absolutely wonderful experience! The staff was incredibly helpful and the rooms were spotless. 
                Will definitely come back!"
              </p>
              <strong>- Sarah Johnson</strong>
            </div>
          </Carousel.Item>
          <Carousel.Item>
            <div style={{ padding: '40px', textAlign: 'center' }}>
              <div style={{ marginBottom: '20px', color: '#ffc107' }}>
                <FaStar /><FaStar /><FaStar /><FaStar /><FaStar />
              </div>
              <p style={{ fontSize: '1.2rem', fontStyle: 'italic', marginBottom: '20px' }}>
                "Best hotel in Sri Lanka! Amazing location, great amenities, and exceptional service. 
                Highly recommended!"
              </p>
              <strong>- Michael Chen</strong>
            </div>
          </Carousel.Item>
          <Carousel.Item>
            <div style={{ padding: '40px', textAlign: 'center' }}>
              <div style={{ marginBottom: '20px', color: '#ffc107' }}>
                <FaStar /><FaStar /><FaStar /><FaStar /><FaStar />
              </div>
              <p style={{ fontSize: '1.2rem', fontStyle: 'italic', marginBottom: '20px' }}>
                "Perfect vacation spot! The Galle branch has stunning ocean views. 
                Can't wait to visit the other locations!"
              </p>
              <strong>- Priya Patel</strong>
            </div>
          </Carousel.Item>
        </Carousel>
      </Container>

      {/* Call to Action */}
      <div style={{
        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
        color: 'white',
        padding: '60px 0',
        textAlign: 'center'
      }}>
        <Container>
          <h2 style={{ fontSize: '2.5rem', fontWeight: 'bold', marginBottom: '20px' }}>
            Ready to Experience SkyNest?
          </h2>
          <p style={{ fontSize: '1.3rem', marginBottom: '30px' }}>
            Join thousands of satisfied guests and book your stay today!
          </p>
          <Button 
            size="lg" 
            variant="light" 
            onClick={() => navigate('/register')}
            style={{ 
              padding: '15px 50px', 
              fontSize: '1.2rem',
              fontWeight: 'bold'
            }}
          >
            Get Started
          </Button>
        </Container>
      </div>

      {/* Footer */}
      <div style={{ backgroundColor: '#1a237e', color: 'white', padding: '30px 0', textAlign: 'center' }}>
        <Container>
          <p style={{ marginBottom: '10px', fontSize: '1.1rem' }}>
            &copy; 2025 SkyNest Hotels. All rights reserved.
          </p>
          <p style={{ marginBottom: 0, color: '#90caf9' }}>
            Luxury Hospitality Across Sri Lanka
          </p>
        </Container>
      </div>
    </div>
  );
};

export default Landing;
