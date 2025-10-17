const { executeQuery } = require('./config/database');

async function getAllTableStructures() {
    try {
        // Get all table names
        const tablesResult = await executeQuery(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_type = 'BASE TABLE'
            ORDER BY table_name;
        `);
        
        console.log('='.repeat(80));
        console.log('DATABASE STRUCTURE - skynest');
        console.log('='.repeat(80));
        
        for (const table of tablesResult.rows) {
            const tableName = table.table_name;
            
            // Get columns for this table
            const columnsResult = await executeQuery(`
                SELECT 
                    column_name, 
                    data_type,
                    character_maximum_length,
                    is_nullable,
                    column_default
                FROM information_schema.columns 
                WHERE table_name = $1
                ORDER BY ordinal_position;
            `, [tableName]);
            
            console.log(`\nTable: ${tableName.toUpperCase()}`);
            console.log('-'.repeat(80));
            
            columnsResult.rows.forEach(col => {
                let type = col.data_type;
                if (col.character_maximum_length) {
                    type += `(${col.character_maximum_length})`;
                }
                const nullable = col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
                const def = col.column_default ? ` DEFAULT ${col.column_default}` : '';
                console.log(`  ${col.column_name.padEnd(30)} ${type.padEnd(25)} ${nullable}${def}`);
            });
        }
        
        console.log('\n' + '='.repeat(80));
        console.log('END OF DATABASE STRUCTURE');
        console.log('='.repeat(80));
        
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

getAllTableStructures();
