// const { executeQuery, executeTransaction } = require('../config/database');
// const { asyncHandler } = require('../middleware/errorHandler');

// /**
//  * Get all service usages with filters
//  */
// const getAllServiceUsages = asyncHandler(async (req, res) => {
//     const {
//         booking_id,
//         service_id,
//         guest_name,
//         room_number,
//         start_date,
//         end_date,
//         page = 1,
//         limit = 10
//     } = req.query;

//     const offset = (page - 1) * limit;
//     let whereClause = 'WHERE 1=1';
//     const filterParams = [];
//     let filterParamIndex = 0;

//     // Build WHERE clause with filters
//     if (booking_id) {
//         whereClause += ` AND su.booking_id = $${++filterParamIndex}`;
//         filterParams.push(booking_id);
//     }

//     if (service_id) {
//         whereClause += ` AND su.service_id = $${++filterParamIndex}`;
//         filterParams.push(service_id);
//     }

//     if (guest_name) {
//         whereClause += ` AND g.full_name ILIKE $${++filterParamIndex}`;
//         filterParams.push(`%${guest_name}%`);
//     }

//     if (room_number) {
//         whereClause += ` AND r.room_number = $${++filterParamIndex}`;
//         filterParams.push(room_number);
//     }

//     if (start_date && end_date) {
//         whereClause += ` AND su.used_on BETWEEN $${++filterParamIndex} AND $${++filterParamIndex}`;
//         filterParams.push(start_date, end_date);
//     }

//     const query = `
//         SELECT 
//             su.service_usage_id,
//             su.booking_id,
//             su.service_id,
//             su.used_on,
//             su.qty,              -- FIXED: Column name
//             su.unit_price_at_use AS total_price, -- FIXED: Using unit_price_at_use for unit cost at time of usage
//             sc.name AS service_name, -- FIXED: Table and Column name
//             sc.unit_price AS service_price,  -- FIXED: Column name
//             sc.category AS service_category,
//             b.booking_id,
//             b.check_in_date,
//             b.check_out_date,
//             b.status AS booking_status,
//             g.guest_id,
//             g.full_name AS guest_name,
//             g.email AS guest_email,
//             g.phone AS guest_phone,
//             r.room_id,
//             r.room_number,
//             rt.name AS room_type
//         FROM public.service_usage su
//         JOIN public.service_catalog sc ON su.service_id = sc.service_id -- FIXED: Table name
//         JOIN public.booking b ON su.booking_id = b.booking_id
//         JOIN public.guest g ON b.guest_id = g.guest_id
//         JOIN public.room r ON b.room_id = r.room_id
//         JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
//         ${whereClause}
//         ORDER BY su.used_on DESC
//         LIMIT $${filterParamIndex + 1} 
//         OFFSET $${filterParamIndex + 2}
//     `;

//     const countQuery = `
//         SELECT COUNT(*) as count
//         FROM public.service_usage su
//         JOIN public.service_catalog sc ON su.service_id = sc.service_id -- FIXED: Table name
//         JOIN public.booking b ON su.booking_id = b.booking_id
//         JOIN public.guest g ON b.guest_id = g.guest_id
//         JOIN public.room r ON b.room_id = r.room_id
//         JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
//         ${whereClause}
//     `;

//     try {
//         const [results, countResult] = await Promise.all([
//             executeQuery(query, [...filterParams, parseInt(limit), parseInt(offset)]),
//             executeQuery(countQuery, filterParams)
//         ]);

//         const total = parseInt(countResult.rows[0].count);
//         const totalPages = Math.ceil(total / limit);

//         res.json({
//             success: true,
//             data: {
//                 serviceUsages: results.rows,
//                 pagination: {
//                     total,
//                     page: parseInt(page),
//                     totalPages,
//                     hasNext: page < totalPages,
//                     hasPrev: page > 1
//                 }
//             }
//         });
//     } catch (error) {
//         console.error('Error in getAllServiceUsages:', error);
//         res.status(500).json({
//             success: false,
//             error: 'Internal server error',
//             details: error.message
//         });
//     }
// });

// /**
//  * Get service usage by ID
//  */
// const getServiceUsageById = asyncHandler(async (req, res) => {
//     const { id } = req.params;

//     const query = `
//         SELECT 
//             su.service_usage_id,
//             su.booking_id,
//             su.service_id,
//             su.used_on,
//             su.qty, -- FIXED
//             su.unit_price_at_use, -- FIXED
//             sc.name AS service_name, -- FIXED
//             sc.unit_price AS service_price, -- FIXED
//             sc.category AS service_category,
//             -- sc.description is NOT in the service_catalog schema
//             b.booking_id,
//             b.check_in_date,
//             b.check_out_date,
//             b.status AS booking_status,
//             g.guest_id,
//             g.full_name AS guest_name,
//             g.email AS guest_email,
//             g.phone AS guest_phone,
//             r.room_id,
//             r.room_number,
//             rt.name AS room_type
//         FROM public.service_usage su
//         JOIN public.service_catalog sc ON su.service_id = sc.service_id -- FIXED
//         JOIN public.booking b ON su.booking_id = b.booking_id
//         JOIN public.guest g ON b.guest_id = g.guest_id
//         JOIN public.room r ON b.room_id = r.room_id
//         JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
//         WHERE su.service_usage_id = $1
//     `;

//     const result = await executeQuery(query, [id]);

//     if (result.rows.length === 0) {
//         return res.status(404).json({
//             success: false,
//             error: 'Service usage not found'
//         });
//     }

//     res.json({
//         success: true,
//         data: result.rows[0]
//     });
// });

// /**
//  * Get service usages by booking ID
//  */
// const getServiceUsagesByBooking = asyncHandler(async (req, res) => {
//     const { bookingId } = req.params;

//     const query = `
//         SELECT 
//             su.service_usage_id,
//             su.booking_id,
//             su.service_id,
//             su.used_on,
//             su.qty, -- FIXED
//             (su.qty * su.unit_price_at_use) AS total_price, -- Recalculate total_price explicitly
//             sc.name AS service_name, -- FIXED
//             sc.unit_price AS service_price, -- FIXED
//             sc.category AS service_category
//             -- sc.description is NOT in the service_catalog schema
//         FROM public.service_usage su
//         JOIN public.service_catalog sc ON su.service_id = sc.service_id -- FIXED
//         WHERE su.booking_id = $1
//         ORDER BY su.used_on DESC
//     `;

//     const result = await executeQuery(query, [bookingId]);

//     // Calculate total service charges
//     const totalCharges = result.rows.reduce((sum, usage) => {
//         // Use the calculated total_price column
//         return sum + parseFloat(usage.total_price || 0); 
//     }, 0);

//     res.json({
//         success: true,
//         data: {
//             serviceUsages: result.rows,
//             summary: {
//                 totalServices: result.rows.length,
//                 totalCharges: totalCharges.toFixed(2)
//             }
//         }
//     });
// });

// /**
//  * Create new service usage
//  */
// const createServiceUsage = asyncHandler(async (req, res) => {
//     const {
//         booking_id,
//         service_id,
//         quantity = 1,
//         used_on
//     } = req.body;

//     if (!booking_id || !service_id) {
//         return res.status(400).json({ success: false, error: 'Booking ID and Service ID are required.' });
//     }

//     const qty = parseInt(quantity);
//     if (isNaN(qty) || qty <= 0) {
//         return res.status(400).json({ success: false, error: 'Quantity must be a positive number.' });
//     }

//     // 1. Validate booking exists and is active
//     const bookingCheck = `
//         SELECT status FROM public.booking WHERE booking_id = $1
//     `;
//     const bookingResult = await executeQuery(bookingCheck, [booking_id]);

//     if (bookingResult.rows.length === 0) {
//         return res.status(404).json({
//             success: false,
//             error: 'Booking not found.'
//         });
//     }

//     const bookingStatus = bookingResult.rows[0].status;

//     if (bookingStatus === 'Checked-Out' || bookingStatus === 'Cancelled') {
//         return res.status(400).json({
//             success: false,
//             error: `Cannot add services to a ${bookingStatus} booking.`
//         });
//     }

//     // 2. Get service details (unit_price)
//     const serviceCheck = `
//         SELECT unit_price FROM public.service_catalog WHERE service_id = $1
//     `;
//     const serviceResult = await executeQuery(serviceCheck, [service_id]);

//     if (serviceResult.rows.length === 0) {
//         return res.status(404).json({
//             success: false,
//             error: 'Service not found.'
//         });
//     }

//     const serviceUnitPrice = parseFloat(serviceResult.rows[0].unit_price);
    
//     // 3. Prepare Insertion Query
//     const insertQuery = `
//         INSERT INTO public.service_usage (
//             booking_id,
//             service_id,
//             qty, 
//             unit_price_at_use, 
//             used_on
//         )
//         VALUES ($1, $2, $3, $4, $5)
//         RETURNING *
//     `;

//     const values = [
//         booking_id,
//         service_id,
//         qty,
//         serviceUnitPrice, // Store the unit price at the time of usage
//         used_on || new Date()
//     ];

//     try {
//         const result = await executeQuery(insertQuery, values);

//         res.status(201).json({
//             success: true,
//             message: '✅ Service usage recorded successfully.',
//             data: result.rows[0]
//         });
//     } catch (error) {
//         console.error('Create Service Usage Error:', error);
//         res.status(500).json({
//             success: false,
//             error: `Internal server error while recording service usage: ${error.message}`
//         });
//     }
// });


// /**
//  * Update service usage
//  */
// const updateServiceUsage = asyncHandler(async (req, res) => {
//     const { id } = req.params;
//     const { quantity, used_on } = req.body;

//     // Get current service usage details
//     const currentQuery = `
//         SELECT su.*, sc.unit_price -- FIXED: Table and Column
//         FROM public.service_usage su
//         JOIN public.service_catalog sc ON su.service_id = sc.service_id -- FIXED
//         WHERE su.service_usage_id = $1
//     `;
//     const currentResult = await executeQuery(currentQuery, [id]);

//     if (currentResult.rows.length === 0) {
//         return res.status(404).json({
//             success: false,
//             error: 'Service usage not found'
//         });
//     }

//     const servicePrice = parseFloat(currentResult.rows[0].unit_price); // FIXED: Column name
//     const newQuantity = quantity || currentResult.rows[0].qty; // FIXED: Column name
//     const newTotalPrice = servicePrice * newQuantity; // Recalculate total

//     const updateQuery = `
//         UPDATE public.service_usage
//         SET 
//             qty = $1, -- FIXED: Column name
//             -- NOTE: We do NOT update unit_price_at_use unless explicitly needed for historical accuracy
//             used_on = COALESCE($2, used_on)
//         WHERE service_usage_id = $3
//         RETURNING *
//     `;

//     const result = await executeQuery(updateQuery, [
//         newQuantity,
//         used_on,
//         id
//     ]);

//     res.json({
//         success: true,
//         message: 'Service usage updated successfully',
//         data: result.rows[0]
//     });
// });

// /**
//  * Delete service usage
//  */
// const deleteServiceUsage = asyncHandler(async (req, res) => {
//     const { id } = req.params;

//     const deleteQuery = `
//         DELETE FROM public.service_usage
//         WHERE service_usage_id = $1
//         RETURNING *
//     `;

//     const result = await executeQuery(deleteQuery, [id]);

//     if (result.rows.length === 0) {
//         return res.status(404).json({
//             success: false,
//             error: 'Service usage not found'
//         });
//     }

//     res.json({
//         success: true,
//         message: 'Service usage deleted successfully',
//         data: result.rows[0]
//     });
// });

// /**
//  * Get service usage summary by date range
//  */
// // const getServiceUsageSummary = asyncHandler(async (req, res) => {
// //     const { start_date, end_date, group_by = 'service' } = req.query;

// //     // FIXED: Using sc.name and sc.category
// //     let groupByClause = 'sc.name, sc.service_id, sc.category';
// //     let selectClause = `
// //         sc.service_id,
// //         sc.name AS service_name,
// //         sc.category,
// //         COUNT(su.service_usage_id) AS usage_count,
// //         SUM(su.qty) AS total_quantity, -- FIXED: Column name
// //         SUM(su.qty * su.unit_price_at_use) AS total_revenue -- FIXED: Calculation
// //     `;

// //     if (group_by === 'date') {
// //         groupByClause = 'DATE(su.used_on)';
// //         selectClause = `
// //             DATE(su.used_on) AS usage_date,
// //             COUNT(su.service_usage_id) AS usage_count,
// //             SUM(su.qty) AS total_quantity, -- FIXED
// //             SUM(su.qty * su.unit_price_at_use) AS total_revenue -- FIXED
// //         `;
// //     } else if (group_by === 'category') {
// //         groupByClause = 'sc.category';
// //         selectClause = `
// //             sc.category,
// //             COUNT(su.service_usage_id) AS usage_count,
// //             SUM(su.qty) AS total_quantity, -- FIXED
// //             SUM(su.qty * su.unit_price_at_use) AS total_revenue -- FIXED
// //         `;
// //     }

// //     let whereClause = 'WHERE 1=1';
// //     const params = [];
// //     let paramIndex = 0;

// //     if (start_date && end_date) {
// //         whereClause += ` AND su.used_on BETWEEN $${++paramIndex} AND $${++paramIndex}`;
// //         params.push(start_date, end_date);
// //     }

// //     const query = `
// //         SELECT ${selectClause}
// //         FROM public.service_usage su
// //         JOIN public.service_catalog sc ON su.service_id = sc.service_id -- FIXED
// //         ${whereClause}
// //         GROUP BY ${groupByClause}
// //         ORDER BY total_revenue DESC
// //     `;

// //     const result = await executeQuery(query, params);

// //     res.json({
// //         success: true,
// //         data: result.rows
// //     });
// // });

// const { executeQuery, executeTransaction } = require('../config/database');
// const { asyncHandler } = require('../middleware/errorHandler');

// /**
//  * Get all service usages with filters
//  */
// const getAllServiceUsages = asyncHandler(async (req, res) => {
//     const {
//         booking_id,
//         service_id,
//         guest_name,
//         room_number,
//         start_date,
//         end_date,
//         page = 1,
//         limit = 10
//     } = req.query;

//     const offset = (page - 1) * limit;
//     let whereClause = 'WHERE 1=1';
//     const filterParams = [];
//     let filterParamIndex = 0;

//     // Build WHERE clause with filters
//     if (booking_id) {
//         whereClause += ` AND su.booking_id = $${++filterParamIndex}`;
//         filterParams.push(booking_id);
//     }

//     if (service_id) {
//         whereClause += ` AND su.service_id = $${++filterParamIndex}`;
//         filterParams.push(service_id);
//     }

//     if (guest_name) {
//         whereClause += ` AND g.full_name ILIKE $${++filterParamIndex}`;
//         filterParams.push(`%${guest_name}%`);
//     }

//     if (room_number) {
//         whereClause += ` AND r.room_number = $${++filterParamIndex}`;
//         filterParams.push(room_number);
//     }

//     if (start_date && end_date) {
//         whereClause += ` AND su.used_on BETWEEN $${++filterParamIndex} AND $${++filterParamIndex}`;
//         filterParams.push(start_date, end_date);
//     }

//     const query = `
//         SELECT 
//             su.service_usage_id,
//             su.booking_id,
//             su.service_id,
//             su.used_on,
//             su.qty,
//             su.unit_price_at_use,
//             (su.qty * su.unit_price_at_use) AS total_price_billed,
//             sc.name AS service_name,
//             sc.unit_price AS service_price,
//             sc.category AS service_category,
//             b.booking_id,
//             b.check_in_date,
//             b.check_out_date,
//             b.status AS booking_status,
//             g.guest_id,
//             g.full_name AS guest_name,
//             g.email AS guest_email,
//             g.phone AS guest_phone,
//             r.room_id,
//             r.room_number,
//             rt.name AS room_type
//         FROM public.service_usage su
//         JOIN public.service_catalog sc ON su.service_id = sc.service_id
//         JOIN public.booking b ON su.booking_id = b.booking_id
//         JOIN public.guest g ON b.guest_id = g.guest_id
//         JOIN public.room r ON b.room_id = r.room_id
//         JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
//         ${whereClause}
//         ORDER BY su.used_on DESC
//         LIMIT $${filterParamIndex + 1} 
//         OFFSET $${filterParamIndex + 2}
//     `;

//     const countQuery = `
//         SELECT COUNT(*) AS count
//         FROM public.service_usage su
//         JOIN public.service_catalog sc ON su.service_id = sc.service_id
//         JOIN public.booking b ON su.booking_id = b.booking_id
//         JOIN public.guest g ON b.guest_id = g.guest_id
//         JOIN public.room r ON b.room_id = r.room_id
//         JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
//         ${whereClause}
//     `;

//     try {
//         const [results, countResult] = await Promise.all([
//             executeQuery(query, [...filterParams, parseInt(limit), parseInt(offset)]),
//             executeQuery(countQuery, filterParams)
//         ]);

//         const total = parseInt(countResult.rows[0].count);
//         const totalPages = Math.ceil(total / limit);

//         res.json({
//             success: true,
//             data: {
//                 serviceUsages: results.rows,
//                 pagination: {
//                     total,
//                     page: parseInt(page),
//                     totalPages,
//                     hasNext: page < totalPages,
//                     hasPrev: page > 1
//                 }
//             }
//         });
//     } catch (error) {
//         console.error('Error in getAllServiceUsages:', error);
//         res.status(500).json({
//             success: false,
//             error: 'Internal server error',
//             details: error.message
//         });
//     }
// });

// /**
//  * Get service usage by ID
//  */
// const getServiceUsageById = asyncHandler(async (req, res) => {
//     const { id } = req.params;

//     const query = `
//         SELECT 
//             su.service_usage_id,
//             su.booking_id,
//             su.service_id,
//             su.used_on,
//             su.qty,
//             su.unit_price_at_use,
//             (su.qty * su.unit_price_at_use) AS total_price_billed,
//             sc.name AS service_name,
//             sc.unit_price AS service_price,
//             sc.category AS service_category,
//             b.booking_id,
//             b.check_in_date,
//             b.check_out_date,
//             b.status AS booking_status,
//             g.guest_id,
//             g.full_name AS guest_name,
//             g.email AS guest_email,
//             g.phone AS guest_phone,
//             r.room_id,
//             r.room_number,
//             rt.name AS room_type
//         FROM public.service_usage su
//         JOIN public.service_catalog sc ON su.service_id = sc.service_id
//         JOIN public.booking b ON su.booking_id = b.booking_id
//         JOIN public.guest g ON b.guest_id = g.guest_id
//         JOIN public.room r ON b.room_id = r.room_id
//         JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
//         WHERE su.service_usage_id = $1
//     `;

//     const result = await executeQuery(query, [id]);

//     if (result.rows.length === 0) {
//         return res.status(404).json({
//             success: false,
//             error: 'Service usage not found'
//         });
//     }

//     res.json({
//         success: true,
//         data: result.rows[0]
//     });
// });

// /**
//  * Get service usages by booking ID
//  */
// const getServiceUsagesByBooking = asyncHandler(async (req, res) => {
//     const { bookingId } = req.params;

//     const query = `
//         SELECT 
//             su.service_usage_id,
//             su.booking_id,
//             su.service_id,
//             su.used_on,
//             su.qty,
//             su.unit_price_at_use,
//             (su.qty * su.unit_price_at_use) AS total_price_billed,
//             sc.name AS service_name,
//             sc.unit_price AS service_price,
//             sc.category AS service_category
//         FROM public.service_usage su
//         JOIN public.service_catalog sc ON su.service_id = sc.service_id
//         WHERE su.booking_id = $1
//         ORDER BY su.used_on DESC
//     `;

//     const result = await executeQuery(query, [bookingId]);

//     // Calculate total service charges
//     const totalCharges = result.rows.reduce((sum, usage) => {
//         return sum + parseFloat(usage.total_price_billed || 0);
//     }, 0);

//     res.json({
//         success: true,
//         data: {
//             serviceUsages: result.rows,
//             summary: {
//                 totalServices: result.rows.length,
//                 totalCharges: totalCharges.toFixed(2)
//             }
//         }
//     });
// });

// /**
//  * Create new service usage
//  */
// const createServiceUsage = asyncHandler(async (req, res) => {
//     const {
//         booking_id,
//         service_id,
//         quantity = 1,
//         used_on
//     } = req.body;

//     if (!booking_id || !service_id) {
//         return res.status(400).json({ success: false, error: 'Booking ID and Service ID are required.' });
//     }

//     const qty = parseInt(quantity);
//     if (isNaN(qty) || qty <= 0) {
//         return res.status(400).json({ success: false, error: 'Quantity must be a positive number.' });
//     }

//     // 1. Validate booking exists and is active
//     const bookingCheck = `
//         SELECT status FROM public.booking WHERE booking_id = $1
//     `;
//     const bookingResult = await executeQuery(bookingCheck, [booking_id]);

//     if (bookingResult.rows.length === 0) {
//         return res.status(404).json({
//             success: false,
//             error: 'Booking not found.'
//         });
//     }

//     const bookingStatus = bookingResult.rows[0].status;

//     if (bookingStatus === 'Checked-Out' || bookingStatus === 'Cancelled') {
//         return res.status(400).json({
//             success: false,
//             error: `Cannot add services to a ${bookingStatus} booking.`
//         });
//     }

//     // 2. Get service details (unit_price)
//     const serviceCheck = `
//         SELECT unit_price FROM public.service_catalog WHERE service_id = $1
//     `;
//     const serviceResult = await executeQuery(serviceCheck, [service_id]);

//     if (serviceResult.rows.length === 0) {
//         return res.status(404).json({
//             success: false,
//             error: 'Service not found.'
//         });
//     }

//     const serviceUnitPrice = parseFloat(serviceResult.rows[0].unit_price);
    
//     // 3. Prepare Insertion Query
//     const insertQuery = `
//         INSERT INTO public.service_usage (
//             booking_id,
//             service_id,
//             qty, 
//             unit_price_at_use, 
//             used_on
//         )
//         VALUES ($1, $2, $3, $4, $5)
//         RETURNING *
//     `;

//     const values = [
//         booking_id,
//         service_id,
//         qty,
//         serviceUnitPrice,
//         used_on || new Date()
//     ];

//     try {
//         const result = await executeQuery(insertQuery, values);

//         res.status(201).json({
//             success: true,
//             message: '✅ Service usage recorded successfully.',
//             data: result.rows[0]
//         });
//     } catch (error) {
//         console.error('Create Service Usage Error:', error);
//         res.status(500).json({
//             success: false,
//             error: `Internal server error while recording service usage: ${error.message}`
//         });
//     }
// });

// /**
//  * Update service usage
//  */


// /**
//  * Delete service usage
//  */
// const deleteServiceUsage = asyncHandler(async (req, res) => {
//     const { id } = req.params;

//     const deleteQuery = `
//         DELETE FROM public.service_usage
//         WHERE service_usage_id = $1
//         RETURNING *
//     `;

//     const result = await executeQuery(deleteQuery, [id]);

//     if (result.rows.length === 0) {
//         return res.status(404).json({
//             success: false,
//             error: 'Service usage not found'
//         });
//     }

//     res.json({
//         success: true,
//         message: 'Service usage deleted successfully',
//         data: result.rows[0]
//     });
// });

// /**
//  * Get service usage summary by date range
//  */
// const getServiceUsageSummary = asyncHandler(async (req, res) => {
//     const { start_date, end_date, group_by = 'service' } = req.query;

//     let groupByClause;
//     let selectClause;

//     // Base Calculation Metrics
//     const baseMetrics = `
//         COUNT(su.service_usage_id) AS usage_count,
//         SUM(su.qty) AS total_quantity,
//         SUM(su.qty * su.unit_price_at_use) AS total_revenue,
//         ROUND(AVG(su.unit_price_at_use), 2) AS avg_unit_price,
//         MAX(su.unit_price_at_use) AS max_unit_price_used
//     `;

//     // --- Dynamic SELECT and GROUP BY ---
//     if (group_by === 'date') {
//         groupByClause = 'DATE(su.used_on)';
//         selectClause = `
//             DATE(su.used_on) AS usage_date,
//             ${baseMetrics}
//         `;
//     } else if (group_by === 'category') {
//         groupByClause = 'sc.category';
//         selectClause = `
//             sc.category,
//             ${baseMetrics}
//         `;
//     } else { // default: group_by === 'service' (individual item)
//         groupByClause = 'sc.name, sc.service_id, sc.category';
//         // FIX: Ensure the three static fields are comma-separated from the baseMetrics
//         selectClause = `
//             sc.service_id,
//             sc.name AS service_name,
//             sc.category,
//             ${baseMetrics}
//         `;
//     }

//     let whereClause = 'WHERE 1=1';
//     const params = [];
//     let paramIndex = 0;

//     if (start_date && end_date) {
//         whereClause += ` AND su.used_on BETWEEN $${++paramIndex} AND $${++paramIndex}`;
//         params.push(start_date, end_date);
//     }

//     const query = `
//         SELECT ${selectClause}
//         FROM public.service_usage su
//         JOIN public.service_catalog sc ON su.service_id = sc.service_id
//         ${whereClause}
//         GROUP BY ${groupByClause}
//         ORDER BY total_revenue DESC
//     `;

//     try {
//         const result = await executeQuery(query, params);

//         res.json({
//             success: true,
//             data: result.rows
//         });
//     } catch (error) {
//         console.error('Error in getServiceUsageSummary:', error);
//         res.status(500).json({
//             success: false,
//             error: 'Internal server error',
//             details: error.message
//         });
//     }
// });


// module.exports = {
//     getAllServiceUsages,
//     getServiceUsageById,
//     getServiceUsagesByBooking,
//     createServiceUsage,
//     updateServiceUsage,
//     deleteServiceUsage,
//     getServiceUsageSummary
// };

const { executeQuery, executeTransaction } = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');

/**
 * Get all service usages with filters
 */
const getAllServiceUsages = asyncHandler(async (req, res) => {
    const {
        booking_id,
        service_id,
        guest_name,
        room_number,
        start_date,
        end_date,
        branch_id,
        page = 1,
        limit = 10
    } = req.query;

    const offset = (page - 1) * limit;
    let whereClause = 'WHERE 1=1';
    const filterParams = [];
    let filterParamIndex = 0;

    // Build WHERE clause with filters
    if (booking_id) {
        whereClause += ` AND su.booking_id = $${++filterParamIndex}`;
        filterParams.push(booking_id);
    }

    if (service_id) {
        whereClause += ` AND su.service_id = $${++filterParamIndex}`;
        filterParams.push(service_id);
    }

    if (guest_name) {
        whereClause += ` AND g.full_name ILIKE $${++filterParamIndex}`;
        filterParams.push(`%${guest_name}%`);
    }

    if (room_number) {
        whereClause += ` AND r.room_number = $${++filterParamIndex}`;
        filterParams.push(room_number);
    }

    if (start_date && end_date) {
        whereClause += ` AND su.used_on BETWEEN $${++filterParamIndex} AND $${++filterParamIndex}`;
        filterParams.push(start_date, end_date);
    }

    if (branch_id) {
        whereClause += ` AND r.branch_id = $${++filterParamIndex}`;
        filterParams.push(branch_id);
    }

    const query = `
        SELECT 
            su.service_usage_id,
            su.booking_id,
            su.service_id,
            su.used_on,
            su.qty,
            su.unit_price_at_use,
            (su.qty * su.unit_price_at_use) AS total_price_billed,
            sc.name AS service_name,
            sc.unit_price AS service_price,
            sc.category AS service_category,
            b.booking_id,
            b.check_in_date,
            b.check_out_date,
            b.status AS booking_status,
            g.guest_id,
            g.full_name AS guest_name,
            g.email AS guest_email,
            g.phone AS guest_phone,
            r.room_id,
            r.room_number,
            rt.name AS room_type
        FROM public.service_usage su
        JOIN public.service_catalog sc ON su.service_id = sc.service_id
        JOIN public.booking b ON su.booking_id = b.booking_id
        JOIN public.guest g ON b.guest_id = g.guest_id
        JOIN public.room r ON b.room_id = r.room_id
        JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
        ${whereClause}
        ORDER BY su.used_on DESC
        LIMIT $${filterParamIndex + 1} 
        OFFSET $${filterParamIndex + 2}
    `;

    const countQuery = `
        SELECT COUNT(*) AS count
        FROM public.service_usage su
        JOIN public.service_catalog sc ON su.service_id = sc.service_id
        JOIN public.booking b ON su.booking_id = b.booking_id
        JOIN public.guest g ON b.guest_id = g.guest_id
        JOIN public.room r ON b.room_id = r.room_id
        JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
        ${whereClause}
    `;

    try {
        const [results, countResult] = await Promise.all([
            executeQuery(query, [...filterParams, parseInt(limit), parseInt(offset)]),
            executeQuery(countQuery, filterParams)
        ]);

        const total = parseInt(countResult.rows[0].count);
        const totalPages = Math.ceil(total / limit);

        res.json({
            success: true,
            data: {
                serviceUsages: results.rows,
                pagination: {
                    total,
                    page: parseInt(page),
                    totalPages,
                    hasNext: page < totalPages,
                    hasPrev: page > 1
                }
            }
        });
    } catch (error) {
        console.error('Error in getAllServiceUsages:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error',
            details: error.message
        });
    }
});

/**
 * Get service usage by ID
 */
const getServiceUsageById = asyncHandler(async (req, res) => {
    const { id } = req.params;

    const query = `
        SELECT 
            su.service_usage_id,
            su.booking_id,
            su.service_id,
            su.used_on,
            su.qty,
            su.unit_price_at_use,
            (su.qty * su.unit_price_at_use) AS total_price_billed,
            sc.name AS service_name,
            sc.unit_price AS service_price,
            sc.category AS service_category,
            b.booking_id,
            b.check_in_date,
            b.check_out_date,
            b.status AS booking_status,
            g.guest_id,
            g.full_name AS guest_name,
            g.email AS guest_email,
            g.phone AS guest_phone,
            r.room_id,
            r.room_number,
            rt.name AS room_type
        FROM public.service_usage su
        JOIN public.service_catalog sc ON su.service_id = sc.service_id
        JOIN public.booking b ON su.booking_id = b.booking_id
        JOIN public.guest g ON b.guest_id = g.guest_id
        JOIN public.room r ON b.room_id = r.room_id
        JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
        WHERE su.service_usage_id = $1
    `;

    const result = await executeQuery(query, [id]);

    if (result.rows.length === 0) {
        return res.status(404).json({
            success: false,
            error: 'Service usage not found'
        });
    }

    res.json({
        success: true,
        data: result.rows[0]
    });
});

/**
 * Get service usages by booking ID
 */
const getServiceUsagesByBooking = asyncHandler(async (req, res) => {
    const { bookingId } = req.params;

    const query = `
        SELECT 
            su.service_usage_id,
            su.booking_id,
            su.service_id,
            su.used_on,
            su.qty,
            su.unit_price_at_use,
            (su.qty * su.unit_price_at_use) AS total_price_billed,
            sc.name AS service_name,
            sc.unit_price AS service_price,
            sc.category AS service_category
        FROM public.service_usage su
        JOIN public.service_catalog sc ON su.service_id = sc.service_id
        WHERE su.booking_id = $1
        ORDER BY su.used_on DESC
    `;

    const result = await executeQuery(query, [bookingId]);

    // Calculate total service charges
    const totalCharges = result.rows.reduce((sum, usage) => {
        return sum + parseFloat(usage.total_price_billed || 0);
    }, 0);

    res.json({
        success: true,
        data: {
            serviceUsages: result.rows,
            summary: {
                totalServices: result.rows.length,
                totalCharges: totalCharges.toFixed(2)
            }
        }
    });
});

/**
 * Create new service usage
 */
const createServiceUsage = asyncHandler(async (req, res) => {
    const {
        booking_id,
        service_id,
        quantity = 1,
        used_on
    } = req.body;

    if (!booking_id || !service_id) {
        return res.status(400).json({ success: false, error: 'Booking ID and Service ID are required.' });
    }

    const qty = parseInt(quantity);
    if (isNaN(qty) || qty <= 0) {
        return res.status(400).json({ success: false, error: 'Quantity must be a positive number.' });
    }

    // 1. Validate booking exists and is active
    const bookingCheck = `
        SELECT status FROM public.booking WHERE booking_id = $1
    `;
    const bookingResult = await executeQuery(bookingCheck, [booking_id]);

    if (bookingResult.rows.length === 0) {
        return res.status(404).json({
            success: false,
            error: 'Booking not found.'
        });
    }

    const bookingStatus = bookingResult.rows[0].status;

    if (bookingStatus === 'Checked-Out' || bookingStatus === 'Cancelled') {
        return res.status(400).json({
            success: false,
            error: `Cannot add services to a ${bookingStatus} booking.`
        });
    }

    // 2. Get service details (unit_price)
    const serviceCheck = `
        SELECT unit_price FROM public.service_catalog WHERE service_id = $1
    `;
    const serviceResult = await executeQuery(serviceCheck, [service_id]);

    if (serviceResult.rows.length === 0) {
        return res.status(404).json({
            success: false,
            error: 'Service not found.'
        });
    }

    const serviceUnitPrice = parseFloat(serviceResult.rows[0].unit_price);
    
    // 3. Prepare Insertion Query
    const insertQuery = `
        INSERT INTO public.service_usage (
            booking_id,
            service_id,
            qty, 
            unit_price_at_use, 
            used_on
        )
        VALUES ($1, $2, $3, $4, $5)
        RETURNING *
    `;

    const values = [
        booking_id,
        service_id,
        qty,
        serviceUnitPrice, // Store the unit price at the time of usage
        used_on || new Date()
    ];

    try {
        const result = await executeQuery(insertQuery, values);

        res.status(201).json({
            success: true,
            message: '✅ Service usage recorded successfully.',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Create Service Usage Error:', error);
        res.status(500).json({
            success: false,
            error: `Internal server error while recording service usage: ${error.message}`
        });
    }
});

// /**
//  * Update service usage
//  */
// const updateServiceUsage = asyncHandler(async (req, res) => {
//     const { id } = req.params;
//     const { quantity, used_on } = req.body;

//     // 1. Get current service usage details
//     const currentQuery = `
//         SELECT su.*, sc.unit_price
//         FROM public.service_usage su
//         JOIN public.service_catalog sc ON su.service_id = sc.service_id
//         WHERE su.service_usage_id = $1
//     `;
//     const currentResult = await executeQuery(currentQuery, [id]);

//     if (currentResult.rows.length === 0) {
//         return res.status(404).json({
//             success: false,
//             error: 'Service usage not found'
//         });
//     }

//     // 2. Prepare new values
//     const newQuantity = quantity || currentResult.rows[0].qty;
//     const newQtyInt = parseInt(newQuantity);

//     if (isNaN(newQtyInt) || newQtyInt <= 0) {
//         return res.status(400).json({ success: false, error: 'Quantity must be a positive number.' });
//     }

//     // 3. Update Query
//     const updateQuery = `
//         UPDATE public.service_usage
//         SET 
//             qty = $1,
//             used_on = COALESCE($2, used_on)
//         WHERE service_usage_id = $3
//         RETURNING *
//     `;

//     try {
//         const result = await executeQuery(updateQuery, [
//             newQtyInt,
//             used_on,
//             id
//         ]);

//         res.json({
//             success: true,
//             message: '✅ Service usage updated successfully',
//             data: result.rows[0]
//         });
//     } catch (error) {
//         console.error('Update Service Usage Error:', error);
//         res.status(500).json({
//             success: false,
//             error: `Internal server error during service usage update: ${error.message}`
//         });
//     }
// });

/**
 * Delete service usage
 */
// const deleteServiceUsage = asyncHandler(async (req, res) => {
//     const { id } = req.params;

//     const deleteQuery = `
//         DELETE FROM public.service_usage
//         WHERE service_usage_id = $1
//         RETURNING *
//     `;

//     const result = await executeQuery(deleteQuery, [id]);

//     if (result.rows.length === 0) {
//         return res.status(404).json({
//             success: false,
//             error: 'Service usage not found'
//         });
//     }

//     res.json({
//         success: true,
//         message: 'Service usage deleted successfully',
//         data: result.rows[0]
//     });
// });


const deleteMostRecentServiceUsage = asyncHandler(async (req, res) => {
    // Extract IDs from request (Assuming bookingId in params and serviceId in body/query)
    const { id: bookingId } = req.params; // Primary ID from URL parameter
    const { service_id } = req.body;        // Secondary ID from body

    if (!bookingId || !service_id) {
        return res.status(400).json({ 
            success: false, 
            error: 'Booking ID and Service ID are required.' 
        });
    }

    // 1. Delete the specified service usage, targeting the single MOST RECENT record
    // We use service_usage_id DESC as it is BIGSERIAL (higher ID means newer).
    const deleteQuery = `
        DELETE FROM public.service_usage
        WHERE service_usage_id = (
            SELECT service_usage_id
            FROM public.service_usage
            WHERE booking_id = $1 AND service_id = $2
            ORDER BY service_usage_id DESC 
            LIMIT 1
        )
        RETURNING booking_id, service_usage_id;
    `;

    const deleteResult = await executeQuery(deleteQuery, [bookingId, service_id]);

    if (deleteResult.rows.length === 0) {
        return res.status(404).json({
            success: false,
            error: 'No matching service usage record found to delete.'
        });
    }

    const deletedServiceUsageId = deleteResult.rows[0].service_usage_id;
    const deletedBookingId = deleteResult.rows[0].booking_id; // Should equal bookingId from params

    // 2. Query for ALL remaining services linked to the booking (Follow-up)
    const remainingServicesQuery = `
        SELECT 
            su.service_usage_id,
            su.qty,
            (su.qty * su.unit_price_at_use) AS total_price_billed,
            sc.name AS service_name,
            su.used_on
        FROM public.service_usage su
        JOIN public.service_catalog sc ON su.service_id = sc.service_id
        WHERE su.booking_id = $1
        ORDER BY su.used_on DESC
    `;

    const remainingServicesResult = await executeQuery(remainingServicesQuery, [deletedBookingId]);
    
    // Calculate the new total charges after deletion
    const newTotalCharges = remainingServicesResult.rows.reduce((sum, usage) => {
        return sum + parseFloat(usage.total_price_billed);
    }, 0).toFixed(2);

    // 3. Return success along with the list of remaining services
    res.json({
        success: true,
        message: `✅ Most recent service usage (ID ${deletedServiceUsageId}) deleted successfully for Booking ${deletedBookingId}.`,
        data: {
            deleted_id: deletedServiceUsageId,
            booking_id: deletedBookingId,
            new_service_list: remainingServicesResult.rows,
            new_total_charges: newTotalCharges
        }
    });
});

/**
 * Get service usage summary by date range
 */
// const getServiceUsageSummary = asyncHandler(async (req, res) => {
//     const { start_date, end_date, group_by = 'service' } = req.query;

//     let groupByClause;
//     let selectClause;

//     // Base Calculation Metrics
//     const baseMetrics = `
//         COUNT(su.service_usage_id) AS usage_count,
//         SUM(su.qty) AS total_quantity,
//         SUM(su.qty * su.unit_price_at_use) AS total_revenue,
//         ROUND(AVG(su.unit_price_at_use), 2) AS avg_unit_price,
//         MAX(su.unit_price_at_use) AS max_unit_price_used
//     `;

//     // --- Dynamic SELECT and GROUP BY ---
//     if (group_by === 'date') {
//         groupByClause = 'DATE(su.used_on)';
//         selectClause = `
//             DATE(su.used_on) AS usage_date,
//             ${baseMetrics}
//         `;
//     } else if (group_by === 'category') {
//         groupByClause = 'sc.category';
//         selectClause = `
//             sc.category,
//             ${baseMetrics}
//         `;
//     } else { // default: group_by === 'service' (individual item)
//         groupByClause = 'sc.name, sc.service_id, sc.category';
//         selectClause = `
//             sc.service_id,
//             sc.name AS service_name,
//             sc.category,
//             ${baseMetrics}
//         `;
//     }

//     let whereClause = 'WHERE 1=1';
//     const params = [];
//     let paramIndex = 0;

//     if (start_date && end_date) {
//         whereClause += ` AND su.used_on BETWEEN $${++paramIndex} AND $${++paramIndex}`;
//         params.push(start_date, end_date);
//     }

//     const query = `
//         SELECT ${selectClause}
//         FROM public.service_usage su
//         JOIN public.service_catalog sc ON su.service_id = sc.service_id
//         ${whereClause}
//         GROUP BY ${groupByClause}
//         ORDER BY total_revenue DESC
//     `;

//     try {
//         const result = await executeQuery(query, params);

//         res.json({
//             success: true,
//             data: result.rows
//         });
//     } catch (error) {
//         console.error('Error in getServiceUsageSummary:', error);
//         res.status(500).json({
//             success: false,
//             error: 'Internal server error',
//             details: error.message
//         });
//     }
// });

const getServiceUsageSummary = asyncHandler(async (req, res) => {
    const { start_date, end_date, group_by = 'service' } = req.query;

    // --- 1. INITIALIZE FILTERING VARIABLES FIRST ---
    let whereClause = 'WHERE 1=1';
    const params = [];
    let filterParamIndex = 0;

    if (start_date && end_date) {
        whereClause += ` AND su.used_on BETWEEN $${++filterParamIndex} AND $${++filterParamIndex}`;
        params.push(start_date, end_date);
    }
    
    // --- 2. DEFINE DYNAMIC QUERY STRUCTURE ---
    let groupByClause;
    let selectClause;
    let baseQuery; 
    let finalQuery; 

    // Base Calculation Metrics
    const baseMetrics = `
        COUNT(su.service_usage_id) AS usage_count,
        SUM(su.qty) AS total_quantity,
        SUM(su.qty * su.unit_price_at_use) AS total_revenue,
        ROUND(AVG(su.unit_price_at_use), 2) AS avg_unit_price,
        ROUND(AVG(su.qty), 2) AS avg_quantity_per_usage,
        MAX(su.unit_price_at_use) AS max_unit_price_used
    `;

    // --- Dynamic SELECT and GROUP BY ---
    if (group_by === 'date') {
        groupByClause = 'DATE(su.used_on)';
        selectClause = `
            DATE(su.used_on) AS usage_date,
            ${baseMetrics}
        `;
        baseQuery = `
            SELECT ${selectClause}
            FROM public.service_usage su
            ${whereClause}
            GROUP BY ${groupByClause}
        `;
        // No window function needed for 'date'
        finalQuery = baseQuery; 
    } else { // 'category' or 'service' (requires JOIN and Window Function)
        
        if (group_by === 'category') {
            groupByClause = 'sc.category';
            selectClause = `
                sc.category,
                ${baseMetrics}
            `;
        } else { // default: group_by === 'service'
            groupByClause = 'sc.name, sc.service_id, sc.category';
            selectClause = `
                sc.service_id,
                sc.name AS service_name,
                sc.category,
                ${baseMetrics}
            `;
        }
        
        // Initial GROUP BY query (uses whereClause successfully)
        baseQuery = `
            SELECT ${selectClause}
            FROM public.service_usage su
            JOIN public.service_catalog sc ON su.service_id = sc.service_id
            ${whereClause}
            GROUP BY ${groupByClause}
        `;
        
        // Final Query with Window Functions for Contribution
        finalQuery = `
            WITH GroupedStats AS (${baseQuery}),
            TotalRevenue AS (
                SELECT SUM(total_revenue) AS overall_total FROM GroupedStats
            )
            SELECT 
                gs.*,
                ROUND(gs.total_revenue * 100.0 / tr.overall_total, 2) AS revenue_share_pct,
                ROUND(
                    SUM(gs.total_revenue) OVER (ORDER BY gs.total_revenue DESC) * 100.0 / tr.overall_total, 2
                ) AS cumulative_share_pct
            FROM GroupedStats gs, TotalRevenue tr
        `;
    }

    // --- 3. EXECUTE FINAL QUERY ---
    // Final query construction ensures ORDER BY is outside the CTE (finalQuery already includes ORDER BY logic via window function)
    const query = `${finalQuery} ORDER BY total_revenue DESC`; 


    try {
        const result = await executeQuery(query, params);

        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Error in getServiceUsageSummary:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error',
            details: error.message
        });
    }
});

module.exports = {
    getAllServiceUsages,
    getServiceUsageById,
    getServiceUsagesByBooking,
    createServiceUsage,
    deleteMostRecentServiceUsage,
    getServiceUsageSummary
};