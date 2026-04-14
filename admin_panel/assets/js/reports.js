let currentPage = 1;

document.addEventListener("DOMContentLoaded", () => {
    fetchReports(1);
});

async function fetchReports(page = 1) {
    currentPage = page;
    const tableBody = document.getElementById("reports-table-body");
    const countBadge = document.getElementById("report-count-badge");

    try {
        const response = await fetch(`${API_BASE_URL}/admin/reports/?page=${page}`, {
            headers: getAuthHeaders()
        });

        if (response.status === 401 || response.status === 403) {
            window.location.href = "login.html";
            return;
        }

        const data = await response.json();
        // data: {count, next, previous, results}
        renderReports(data.results);
        renderPagination(data);
        countBadge.innerText = `${data.count} reports`;
    } catch (error) {
        console.error("Error fetching reports:", error);
    }
}

function renderPagination(data) {
    const paginationRoot = document.getElementById("reports-pagination");
    if (!paginationRoot) return;
    paginationRoot.innerHTML = "";

    const totalPages = Math.ceil(data.count / 10);
    if (totalPages <= 1) return;

    // Previous Button
    const prevLi = document.createElement("li");
    prevLi.className = `page-item ${!data.previous ? 'disabled' : ''}`;
    prevLi.innerHTML = `<a class="page-link" href="#" onclick="fetchReports(${currentPage - 1})">Previous</a>`;
    paginationRoot.appendChild(prevLi);

    // Page Numbers
    for (let i = 1; i <= totalPages; i++) {
        const li = document.createElement("li");
        li.className = `page-item ${i === currentPage ? 'active' : ''}`;
        li.innerHTML = `<a class="page-link" href="#" onclick="fetchReports(${i})">${i}</a>`;
        paginationRoot.appendChild(li);
    }

    // Next Button
    const nextLi = document.createElement("li");
    nextLi.className = `page-item ${!data.next ? 'disabled' : ''}`;
    nextLi.innerHTML = `<a class="page-link" href="#" onclick="fetchReports(${currentPage + 1})">Next</a>`;
    paginationRoot.appendChild(nextLi);
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
