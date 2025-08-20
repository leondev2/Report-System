let currentReportId = null;

document.addEventListener('DOMContentLoaded', function() {
    const reportContainer = document.getElementById('report-container');
    const closeBtn = document.getElementById('close-btn');
    const submitBtn = document.getElementById('submit-btn');
    const categorySelect = document.getElementById('category');
    const messageTextarea = document.getElementById('message');
    const playerSelect = document.getElementById('player');
    
    const adminContainer = document.getElementById('admin-container');
    const adminCloseBtn = document.getElementById('admin-close-btn');
    const refreshBtn = document.getElementById('refresh-btn');
    const reportsList = document.getElementById('reports-list');
    const detailsContent = document.getElementById('details-content');
    const gotoBtn = document.getElementById('goto-btn');
    const bringBtn = document.getElementById('bring-btn');
    const closeReportBtn = document.getElementById('close-btn');
    
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.type === 'openReport') {
            reportContainer.style.display = 'block';
            fetchPlayers();
        } else if (data.type === 'openAdmin') {
            adminContainer.style.display = 'block';
            fetchReports();
        } else if (data.type === 'closeAll') {
            reportContainer.style.display = 'none';
            adminContainer.style.display = 'none';
        } else if (data.type === 'playersList') {
            populatePlayers(data.players);
        } else if (data.type === 'reportsList') {
            populateReports(data.reports);
        } else if (data.type === 'reportDetails') {
            showReportDetails(data.report);
        }
    });

    closeBtn.addEventListener('click', closeUI);
    adminCloseBtn.addEventListener('click', closeUI);

    submitBtn.addEventListener('click', function() {
        const category = categorySelect.value;
        const message = messageTextarea.value;
        const playerId = playerSelect.value;
        
        if (!message) {
            return;
        }
        
        fetch(`https://${GetParentResourceName()}/submitReport`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                category: category,
                message: message,
                playerId: playerId
            })
        }).then(resp => resp.json()).then(resp => {
            if (resp.success) {
                closeUI();
            }
        });
    });

    refreshBtn.addEventListener('click', fetchReports);
    
    gotoBtn.addEventListener('click', function() {
        if (currentReportId) {
            fetch(`https://${GetParentResourceName()}/gotoReport`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    reportId: currentReportId
                })
            }).then(() => {
                setTimeout(fetchReports, 500);
            });
        }
    });
    
    bringBtn.addEventListener('click', function() {
        if (currentReportId) {
            fetch(`https://${GetParentResourceName()}/bringReport`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    reportId: currentReportId
                })
            }).then(() => {
                setTimeout(fetchReports, 500);
            });
        }
    });
    
    closeReportBtn.addEventListener('click', function() {
        if (currentReportId) {
            console.log('Closing report:', currentReportId);
            fetch(`https://${GetParentResourceName()}/closeReport`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    reportId: currentReportId
                })
            }).then(() => {
                fetchReports();
                detailsContent.innerHTML = '';
                currentReportId = null;
            });
        }
    });

    document.addEventListener('keyup', function(e) {
        if (e.key === 'Escape') {
            closeUI();
        }
    });
    
    function closeUI() {
        reportContainer.style.display = 'none';
        adminContainer.style.display = 'none';
        fetch(`https://${GetParentResourceName()}/closeUI`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });
    }
    
    function fetchPlayers() {
        fetch(`https://${GetParentResourceName()}/getPlayers`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });
    }
    
    function populatePlayers(players) {
        playerSelect.innerHTML = '<option value="">Select a player</option>';
        
        players.forEach(player => {
            const option = document.createElement('option');
            option.value = player.id;
            option.textContent = `${player.name} (${player.id})`;
            playerSelect.appendChild(option);
        });
    }
    
    function fetchReports() {
        fetch(`https://${GetParentResourceName()}/getReports`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });
    }
    
    function populateReports(reports) {
        reportsList.innerHTML = '';
        
        reports.forEach(report => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>${report.id}</td>
                <td>${report.playerName}</td>
                <td>${report.category}</td>
                <td class="${report.status === 'open' ? 'status-open' : 'status-closed'}">${report.status}</td>
                <td>${new Date(report.time).toLocaleTimeString()}</td>
                <td>${report.adminName || '-'}</td>
            `;
            
            tr.addEventListener('click', function() {
                fetch(`https://${GetParentResourceName()}/getReportDetails`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        reportId: report.id
                    })
                });
                currentReportId = report.id;
            });
            
            reportsList.appendChild(tr);
        });
    }
    
    function showReportDetails(report) {
        detailsContent.innerHTML = `
            <p><strong>Reported by:</strong> ${report.playerName} (ID: ${report.playerId})</p>
            <p><strong>Category:</strong> ${report.category}</p>
            <p><strong>Time:</strong> ${new Date(report.time).toLocaleString()}</p>
            <p><strong>Status:</strong> <span class="${report.status === 'open' ? 'status-open' : 'status-closed'}">${report.status}</span></p>
            <p><strong>Handled by:</strong> ${report.adminName || 'Not handled yet'}</p>
            <div style="margin-top: 15px;">
                <strong>Message:</strong>
                <p style="background: rgba(30,30,30,0.5); padding: 10px; border-radius: 6px; margin-top: 5px;">${report.message}</p>
            </div>
        `;
    }
});