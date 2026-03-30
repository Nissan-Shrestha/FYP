document.addEventListener("DOMContentLoaded", () => {
    fetchDashboardData();
    
    // Add event listener for refresh button if it exists
    const refreshBtn = document.querySelector('button.btn-primary');
    if (refreshBtn) {
        refreshBtn.addEventListener('click', fetchDashboardData);
    }
});

async function fetchDashboardData() {
    const token = localStorage.getItem("admin_token");
    if (!token) {
        console.warn("No token found. Redirecting to login...");
        window.location.href = "login.html";
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/admin/dashboard-data/`, {
            headers: getAuthHeaders()
        });

        if (response.status === 401 || response.status === 403) {
            console.error("Access denied or session expired.");
            alert("Your session has expired or you do not have admin permissions. Please log in again.");
            window.location.href = "login.html";
            return;
        }

        const data = await response.json();
        updateStats(data.stats);
        renderRecentUsers(data.recent_users);
        renderTopOutfits(data.top_outfits);
    } catch (error) {
        console.error("Error fetching dashboard data:", error);
        alert("Could not connect to the backend server. Make sure 'python manage.py runserver' is running on port 8000.");
    }
}

function updateStats(stats) {
    document.getElementById("total-users-count").innerText = stats.total_users.toLocaleString();
    document.getElementById("premium-users-count").innerText = stats.premium_users.toLocaleString();
    document.getElementById("total-outfits-count").innerText = (stats.total_public_outfits || 0).toLocaleString();
    document.getElementById("total-saves-count").innerText = (stats.total_saves || 0).toLocaleString();
    document.getElementById("pending-reports-count").innerText = (stats.pending_reports || 0).toLocaleString();
}

function renderRecentUsers(users) {
    const tableBody = document.getElementById("recent-signups-table-body");
    tableBody.innerHTML = "";

    if (!users || users.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="5" class="text-center py-4 text-muted">No recent signups found.</td></tr>';
        return;
    }

    users.forEach(user => {
        const row = document.createElement("tr");
        const planBadgeClass = user.plan.toLowerCase() === "premium" ? "bg-success" : "bg-secondary";
        
        row.innerHTML = `
            <td>${user.username}</td>
            <td>${user.email}</td>
            <td><span class="badge ${planBadgeClass}">${user.plan}</span></td>
            <td>${new Date(user.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}</td>
            <td>
                <button class="btn btn-sm btn-outline-secondary">Edit</button>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

function renderTopOutfits(outfits) {
    const tableBody = document.getElementById("popular-outfits-table-body");
    tableBody.innerHTML = "";

    if (!outfits || outfits.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="4" class="text-center py-4 text-muted">No public outfits shared yet.</td></tr>';
        return;
    }

    outfits.forEach(outfit => {
        const row = document.createElement("tr");
        
        row.innerHTML = `
            <td><span class="fw-medium">${outfit.owner_username || 'User'}</span></td>
            <td>${outfit.name}</td>
            <td><span class="badge bg-light text-dark border">${outfit.occasion}</span></td>
            <td class="text-center">
                <span class="badge bg-warning text-dark">
                    <i class="bi bi-bookmark-heart-fill me-1"></i>${outfit.saves_count || 0}
                </span>
            </td>
        `;
        tableBody.appendChild(row);
    });
}
