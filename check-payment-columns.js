const { executeQuery } = require('./config/database');

async function checkPaymentColumns() {
    try {
        const result = await executeQuery(`
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'payment' 
            ORDER BY ordinal_position;
        `);
        
        console.log('Payment table columns:');
        result.rows.forEach(col => {
            console.log(`  ${col.column_name}: ${col.data_type}`);
        });
        
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkPaymentColumns();
