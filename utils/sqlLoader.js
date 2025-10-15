const fs = require('fs').promises;
const path = require('path');

/**
 * Load an SQL query from a file
 * @param {string} filename - Name of the SQL file without extension
 * @returns {Promise<string>} The SQL query string
 */
const loadQuery = async (filename) => {
    try {
        const filePath = path.join(__dirname, '..', 'sql', `${filename}.sql`);
        const query = await fs.readFile(filePath, 'utf8');
        return query;
    } catch (error) {
        console.error(`Error loading SQL query ${filename}:`, error);
        throw error;
    }
};

module.exports = {
    loadQuery
};
