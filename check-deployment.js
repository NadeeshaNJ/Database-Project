const https = require('https');

console.log('\n🔍 CHECKING GITHUB PAGES DEPLOYMENT...\n');

const frontendUrl = 'https://nadeeshanj.github.io/Database-Project';
const backendUrl = 'https://skynest-backend-api.onrender.com/api/health';

console.log('🌐 Testing Frontend URL:', frontendUrl);
https.get(frontendUrl, (res) => {
  console.log(`   Status: ${res.statusCode}`);
  if (res.statusCode === 200) {
    console.log('   ✅ Frontend is accessible');
  } else {
    console.log('   ❌ Frontend returned status:', res.statusCode);
  }
}).on('error', (err) => {
  console.log('   ❌ Frontend error:', err.message);
});

console.log('\n🔌 Testing Backend API:', backendUrl);
https.get(backendUrl, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log(`   Status: ${res.statusCode}`);
    if (res.statusCode === 200) {
      console.log('   ✅ Backend is accessible');
      try {
        const json = JSON.parse(data);
        console.log('   Response:', json);
      } catch(e) {
        console.log('   Response:', data.substring(0, 100));
      }
    } else {
      console.log('   ❌ Backend returned status:', res.statusCode);
    }
  });
}).on('error', (err) => {
  console.log('   ❌ Backend error:', err.message);
});

setTimeout(() => {
  console.log('\n' + '='.repeat(60));
  console.log('💡 If frontend loads but login fails:');
  console.log('   1. Open browser console (F12) to see errors');
  console.log('   2. Check Network tab for failed API calls');
  console.log('   3. Verify backend is responding above');
  console.log('\n💡 If frontend doesn\'t load at all:');
  console.log('   1. Check if gh-pages branch is deployed');
  console.log('   2. Rebuild and redeploy: npm run deploy');
  console.log('   3. Check GitHub Pages settings in repository');
  console.log('='.repeat(60) + '\n');
}, 2000);
