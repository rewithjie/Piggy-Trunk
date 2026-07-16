const https = require('https');

const supabaseUrl = 'https://ywwwrshblzyqmxkbkxsp.supabase.co';
const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3d3dyc2hibHp5cW14a2JreHNwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3MjU2MDMsImV4cCI6MjA5MzMwMTYwM30.ceKymQgbjU3IAbHxS2OUiOV9Mf5DxVxf9eBgzRuCHXo';

const passwords = ['password', 'password123', 'admin123'];
const email = 'admin@piggytrunk.com';

function tryLogin(index) {
  if (index >= passwords.length) {
    console.log('Failed to login with any password candidate.');
    return;
  }
  const password = passwords[index];
  console.log(`Attempting login for ${email} with password: "${password}"...`);

  const postData = JSON.stringify({ email, password });
  
  const req = https.request(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: {
      'apikey': anonKey,
      'Content-Type': 'application/json',
      'Content-Length': postData.length
    }
  }, (res) => {
    let body = '';
    res.on('data', (chunk) => body += chunk);
    res.on('end', () => {
      const result = JSON.parse(body);
      if (result.access_token) {
        console.log('Login Success! JWT Token obtained.');
        queryTables(result.access_token);
      } else {
        console.log(`Login failed: ${result.error_description || result.error || body}`);
        tryLogin(index + 1);
      }
    });
  });

  req.on('error', (e) => {
    console.error(e);
  });

  req.write(postData);
  req.end();
}

function queryTables(token) {
  const options = {
    headers: {
      'apikey': anonKey,
      'Authorization': `Bearer ${token}`
    }
  };

  https.get(`${supabaseUrl}/rest/v1/app_users?select=*`, options, (res) => {
    let body = '';
    res.on('data', (chunk) => body += chunk);
    res.on('end', () => {
      console.log('\n--- APP USERS ---');
      console.log(body);

      https.get(`${supabaseUrl}/rest/v1/hog_raisers?select=*`, options, (res2) => {
        let body2 = '';
        res2.on('data', (chunk) => body2 += chunk);
        res2.on('end', () => {
          console.log('\n--- HOG RAISERS ---');
          console.log(body2);
        });
      });
    });
  });
}

tryLogin(0);
