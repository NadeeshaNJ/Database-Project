const { ValidationError, UniqueConstraintError, ForeignKeyConstraintError } = require('sequelize');

const errorHandler = (error, req, res, next) => {
  console.error('Error details:', error);

  // Sequelize Validation Error
  if (error instanceof ValidationError) {
    return res.status(400).json({
      success: false,
      error: 'Validation Error',
      details: error.errors.map(err => ({
        field: err.path,
        message: err.message
      }))
    });
  }

  // Sequelize Unique Constraint Error
  if (error instanceof UniqueConstraintError) {
    return res.status(409).json({
      success: false,
      error: 'Duplicate Entry',
      details: error.errors.map(err => ({
        field: err.path,
        message: `${err.value} already exists`
      }))
    });
  }

  // Sequelize Foreign Key Constraint Error
  if (error instanceof ForeignKeyConstraintError) {
    return res.status(400).json({
      success: false,
      error: 'Reference Error',
      message: 'The referenced record does not exist'
    });
  }

  // JWT Errors
  if (error.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      error: 'Invalid Token'
    });
  }

  if (error.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      error: 'Token Expired'
    });
  }

  // Default error
  const statusCode = error.statusCode || error.status || 500;
  const message = error.message || 'Internal Server Error';

  res.status(statusCode).json({
    success: false,
    error: message,
    ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
  });
};

const notFoundHandler = (req, res, next) => {
  const error = new Error(`Not found - ${req.originalUrl}`);
  error.statusCode = 404;
  next(error);
};

const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = {
  errorHandler,
  notFoundHandler,
  asyncHandler
};