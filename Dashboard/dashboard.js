let chartInstance = null;

function calcUptime(server) {
    if (server.LastStatus === 'UP') return 99.9;
    if (!server.DownSince) return 0;
    try {
        const parts = server.DownSince.split(' ');
        const [d, mo, yr] = parts[0].split('-');
        const downDate = new Date(`${yr}-${mo}-${d}T${parts[1]}`);
        const now = new Date();
        const downDays = (now - downDate) / (1000 * 60 * 60 * 24);
        const monitoringStartDays = 30;
        const upDays = Math.max(0, monitoringStartDays - downDays);
        return Math.min(100, Math.max(0, (upDays / monitoringStartDays) * 100)).toFixed(1);
    } catch (e) { return 0; }
}

function renderCards(servers) {
    const container = document.getElementById('serverCards');
    container.innerHTML = '';
    servers.forEach(s => {
        const isUp = s.LastStatus === 'UP';
        const uptime = calcUptime(s);
        const card = document.createElement('div');
        card.className = 'server-card ' + (isUp ? 'up' : 'down');
        card.innerHTML = `
            <div class="card-top">
                <div>
                    <div class="card-name">${s.ServerName}</div>
                    <div class="card-url">${s.Url}</div>
                </div>
                <span class="badge ${isUp ? 'badge-up' : 'badge-down'}">${s.LastStatus}</span>
            </div>
            <div class="card-stats">
                <div class="stat">
                    <div class="stat-label">Response</div>
                    <div class="stat-value">${isUp ? s.ResponseTime + ' ms' : '—'}</div>
                </div>
                <div class="stat">
                    <div class="stat-label">Uptime</div>
                    <div class="stat-value ${isUp ? 'green' : 'red'}">${uptime}%</div>
                </div>
                <div class="stat">
                    <div class="stat-label">Down since</div>
                    <div class="stat-value" style="font-size:11px">${s.DownSince ? s.DownSince.split(' ')[0] : '—'}</div>
                </div>
            </div>
            <div class="uptime-bar">
                <div class="uptime-fill" style="width:${uptime}%;background:${isUp ? '#639922' : '#e24b4a'}"></div>
            </div>`;
        container.appendChild(card);
    });
}

function renderTable(servers) {
    const tbody = document.getElementById('serverTableBody');
    tbody.innerHTML = '';
    servers.forEach(s => {
        const isUp = s.LastStatus === 'UP';
        const tr = document.createElement('tr');
        if (!isUp) tr.className = 'down-row';
        tr.innerHTML = `
            <td style="font-weight:500">${s.ServerName}</td>
            <td style="color:#888;font-size:12px">${s.Url}</td>
            <td><span class="badge ${isUp ? 'badge-up' : 'badge-down'}">${s.LastStatus}</span></td>
            <td>${isUp ? s.ResponseTime + ' ms' : '—'}</td>
            <td style="color:${isUp ? '#3b6d11' : '#a32d2d'};font-weight:500">${calcUptime(s)}%</td>
            <td style="color:#888;font-size:12px">${s.LastCheckTime}</td>
            <td style="color:#888;font-size:12px">${s.DownSince || '—'}</td>`;
        tbody.appendChild(tr);
    });
}

function renderChart(servers) {
    if (chartInstance) chartInstance.destroy();
    chartInstance = new Chart(document.getElementById('responseChart'), {
        type: 'bar',
        data: {
            labels: servers.map(s => s.ServerName),
            datasets: [{
                label: 'Response time (ms)',
                data: servers.map(s => s.ResponseTime),
                backgroundColor: servers.map(s => s.LastStatus === 'UP' ? '#639922' : '#e24b4a'),
                borderRadius: 4
            }]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
                x: { ticks: { autoSkip: false, maxRotation: 0 }, grid: { display: false } },
                y: { beginAtZero: true, ticks: { callback: v => v + 'ms' }, grid: { color: '#f0f0f0' } }
            }
        }
    });
}

function renderAll(servers) {
    const up = servers.filter(s => s.LastStatus === 'UP').length;
    document.getElementById('totalCount').textContent = servers.length;
    document.getElementById('upCount').textContent = up;
    document.getElementById('downCount').textContent = servers.length - up;
    document.getElementById('uptimePct').textContent = Math.round((up / servers.length) * 100) + '%';
    document.getElementById('lastRefresh').textContent = 'Last checked: ' + new Date().toLocaleTimeString();
    renderCards(servers);
    renderTable(servers);
    renderChart(servers);
}

async function loadServers() {
    try {
        const res = await fetch('servers.json');
        if (!res.ok) throw new Error('HTTP ' + res.status);
        const text = await res.text();
        renderAll(JSON.parse(text.replace(/^\uFEFF/, '')));
    } catch (e) {
        console.error('Could not load servers.json:', e.message);
    }
}

loadServers();
setInterval(loadServers, 30000);