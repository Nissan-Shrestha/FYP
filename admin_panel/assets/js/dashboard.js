document.addEventListener("DOMContentLoaded", () => {
    fetchDashboardData();
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
    } catch (error) {
        console.error("Error fetching dashboard data:", error);
        alert("Could not connect to the backend server. Make sure 'python manage.py runserver' is running on port 8000.");
    }
}


function updateStats(stats) {
    document.getElementById("total-users-count").innerText = stats.total_users.toLocaleString();
    document.getElementById("premium-users-count").innerText = stats.premium_users.toLocaleString();
}


function renderRecentUsers(users) {
    const tableBody = document.getElementById("recent-signups-table-body");
    tableBody.innerHTML = "";

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
