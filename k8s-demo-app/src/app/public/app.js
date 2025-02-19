let startTime = new Date();

function updateUptime() {
    const now = new Date();
    const uptimeInSeconds = Math.floor((now - startTime) / 1000);
    const hours = Math.floor(uptimeInSeconds / 3600);
    const minutes = Math.floor((uptimeInSeconds % 3600) / 60);
    const seconds = uptimeInSeconds % 60;
    
    document.getElementById('uptime').textContent = 
        `${hours}h ${minutes}m ${seconds}s`;
}

async function checkHealth() {
    try {
        const response = await fetch('/health');
        const data = await response.json();
        const statusBadge = document.getElementById('healthStatus');
        
        if (data.status === 'healthy') {
            statusBadge.textContent = 'Healthy';
            statusBadge.classList.add('healthy');
        } else {
            statusBadge.textContent = 'Unhealthy';
            statusBadge.classList.remove('healthy');
        }
    } catch (error) {
        document.getElementById('healthStatus').textContent = 'Service Unavailable';
    }
}

async function loadPodInfo() {
    try {
        const response = await fetch('/');
        const data = await response.json();
        
        document.getElementById('podName').textContent = data.kubernetes.pod;
        document.getElementById('namespace').textContent = data.kubernetes.namespace;
        document.getElementById('version').textContent = data.version;
        
        document.getElementById('podInfo').textContent = 
            JSON.stringify(data, null, 2);
    } catch (error) {
        document.getElementById('podInfo').textContent = 
            'Error loading pod information';
    }
}

async function testEndpoint() {
    const responseBox = document.getElementById('apiResponse');
    try {
        const response = await fetch('/');
        const data = await response.json();
        responseBox.textContent = JSON.stringify(data, null, 2);
    } catch (error) {
        responseBox.textContent = 'Error: Could not reach the API';
    }
}

// Update functions
setInterval(updateUptime, 1000);
setInterval(checkHealth, 5000);
setInterval(loadPodInfo, 10000);

// Initial load
checkHealth();
loadPodInfo();
updateUptime();
