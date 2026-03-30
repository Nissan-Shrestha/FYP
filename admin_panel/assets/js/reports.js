document.addEventListener("DOMContentLoaded", () => {
    fetchReports();
});

async function fetchReports() {
    const tableBody = document.getElementById("reports-table-body");
    const countBadge = document.getElementById("report-count-badge");

    try {
        const response = await fetch(`${API_BASE_URL}/admin/reports/`, {
            headers: getAuthHeaders()
        });

        if (response.status === 401 || response.status === 403) {
            window.location.href = "login.html";
            return;
        }

        const reports = await response.json();
        renderReports(reports);
        countBadge.innerText = `${reports.length} reports`;
    } catch (error) {
        console.error("Error fetching reports:", error);
    }
}

function renderReports(reports) {
    const tableBody = document.getElementById("reports-table-body");
    tableBody.innerHTML = "";

    if (reports.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="6" class="text-center py-5 text-muted">No reports found! Good job moderating.</td></tr>';
        return;
    }

    reports.forEach(report => {
        const row = document.createElement("tr");
        
        let statusBadgeClass = "bg-secondary";
        if (report.status === "pending") statusBadgeClass = "bg-warning text-dark";
        if (report.status === "resolved") statusBadgeClass = "bg-success";
        if (report.status === "ignored") statusBadgeClass = "bg-light text-dark border";

        const hasOutfit = !!report.outfit;
        const outfitInfo = hasOutfit 
            ? `<div class="fw-bold">${report.outfit_name}</div><div class="small text-muted">by ${report.outfit_owner_username}</div>`
            : `<div class="text-muted"><i>Outfit Deleted</i></div>`;

        row.innerHTML = `
            <td>
                <div class="fw-medium">${report.reporter_username}</div>
            </td>
            <td>
                ${outfitInfo}
            </td>
            <td>
                <div class="reason-cell text-wrap">${report.reason}</div>
            </td>
            <td>
                <span class="badge ${statusBadgeClass} status-badge">${report.status}</span>
            </td>
            <td>
                <div class="small">${new Date(report.created_at).toLocaleDateString()}</div>
                <div class="small text-muted text-uppercase" style="font-size: 0.7rem;">${new Date(report.created_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</div>
            </td>
            <td class="text-end">
                <a href="report_details.html?id=${report.id}" class="btn btn-sm btn-primary">
                    <i class="bi bi-search me-1"></i>Review
                </a>
            </td>
        `;
        tableBody.appendChild(row);
    });
}
