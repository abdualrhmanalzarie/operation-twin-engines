#!/bin/bash
## -- you could write any frontend service here! --
apt-get update
apt-get install -y apache2 curl
systemctl enable apache2
systemctl start apache2

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>Frontend App</title>
</head>
<body>
  <h1>Frontend is running</h1>
  <p id="result">Loading backend response...</p>

  <script>
    fetch('http://${backend_ip}:5000/')
      .then(response => response.json())
      .then(data => {
        document.getElementById('result').innerText =
          'Backend says: ' + data.message + ' | Status: ' + data.status;
      })
      .catch(error => {
        document.getElementById('result').innerText =
          'Failed to reach backend API: ' + error;
      });
  </script>
</body>
</html>
EOF
