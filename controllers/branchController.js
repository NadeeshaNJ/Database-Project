const { executeQuery } = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');

/**
 * Get all branches
 */
const getAllBranches = asyncHandler(async (req, res) => {
    const query = `
        SELECT 
            branch_id,
            branch_name,
            branch_code,
            address,
            contact_number,
            manager_name,
            (SELECT COUNT(*) FROM room WHERE room.branch_id = branch.branch_id) as total_rooms,
            (SELECT COUNT(*) FROM room WHERE room.branch_id = branch.branch_id AND room.status = 'Available') as available_rooms
        FROM branch
        ORDER BY branch_id
    `;

    const result = await executeQuery(query);

    res.json({
        success: true,
        data: {
            branches: result.rows,
            total: result.rows.length
        }
    });
});

/**
 * Get branch by ID
 */
const getBranchById = asyncHandler(async (req, res) => {
    const { id } = req.params;

    const query = `
        SELECT 
            b.branch_id,
            b.branch_name,
            b.branch_code,
            b.address,
            b.contact_number,
            b.manager_name,
            (SELECT COUNT(*) FROM room WHERE room.branch_id = b.branch_id) as total_rooms,
            (SELECT COUNT(*) FROM room WHERE room.branch_id = b.branch_id AND room.status = 'Available') as available_rooms
        FROM branch b
        WHERE b.branch_id = $1
    `;

    const result = await executeQuery(query, [id]);

    if (result.rows.length === 0) {
        return res.status(404).json({
            success: false,
            error: 'Branch not found'
        });
    }

    res.json({
        success: true,
        data: {
            branch: result.rows[0]
        }
    });
});

module.exports = {
    getAllBranches,
    getBranchById
};
