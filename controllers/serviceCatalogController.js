const { executeQuery } = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');

/**
 * Get all services from the catalog
 */
const getAllServices = asyncHandler(async (req, res) => {
    const {
        category,
        active,
        page = 1,
        limit = 100
    } = req.query;

    const offset = (page - 1) * limit;
    const params = [];
    let paramIndex = 0;

    let query = `
        SELECT 
            service_id,
            code,
            name,
            category,
            unit_price,
            tax_rate_percent,
            active
        FROM service_catalog
        WHERE 1=1
    `;

    // Category filter
    if (category) {
        query += ` AND category = $${++paramIndex}`;
        params.push(category);
    }

    // Active filter
    if (active !== undefined) {
        query += ` AND active = $${++paramIndex}`;
        params.push(active === 'true');
    }

    // Order by category and name
    query += ` ORDER BY category, name`;

    // Pagination
    query += ` LIMIT $${++paramIndex} OFFSET $${++paramIndex}`;
    params.push(parseInt(limit), parseInt(offset));

    // Count query for pagination
    let countQuery = `
        SELECT COUNT(*) as count
        FROM service_catalog
        WHERE 1=1
    `;

    const countParams = [];
    let countParamIndex = 0;

    if (category) {
        countQuery += ` AND category = $${++countParamIndex}`;
        countParams.push(category);
    }

    if (active !== undefined) {
        countQuery += ` AND active = $${++countParamIndex}`;
        countParams.push(active === 'true');
    }

    const [results, countResult] = await Promise.all([
        executeQuery(query, params),
        executeQuery(countQuery, countParams)
    ]);

    const total = parseInt(countResult.rows[0].count);
    const totalPages = Math.ceil(total / limit);

    res.json({
        success: true,
        data: {
            services: results.rows,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages,
                hasNext: page < totalPages,
                hasPrev: page > 1
            }
        }
    });
});

/**
 * Get service by ID
 */
const getServiceById = asyncHandler(async (req, res) => {
    const { id } = req.params;

    const query = `
        SELECT 
            service_id,
            code,
            name,
            category,
            unit_price,
            tax_rate_percent,
            active
        FROM service_catalog
        WHERE service_id = $1
    `;

    const result = await executeQuery(query, [id]);

    if (result.rows.length === 0) {
        return res.status(404).json({
            success: false,
            error: 'Service not found'
        });
    }

    res.json({
        success: true,
        data: result.rows[0]
    });
});

module.exports = {
    getAllServices,
    getServiceById
};
