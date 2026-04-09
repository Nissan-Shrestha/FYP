let allRequests = [];

document.addEventListener("DOMContentLoaded", () => {
    fetchRequests();

    // Setup form listener
    const rejectForm = document.getElementById("reject-form");
    if (rejectForm) {
        rejectForm.addEventListener("submit", handleRejectSubmit);
    }
});

async function fetchRequests() {
    const tableBody = document.getElementById("requests-table-body");
    const countBadge = document.getElementById("request-count-badge");
    
    // Updated to use the ADMIN endpoint
    let url = `${API_BASE_URL}/admin/feature-requests/`; 

    try {
        const response = await fetch(url, {
            headers: getAuthHeaders()
        });

        if (response.status === 401 || response.status === 403) {
            window.location.href = "login.html";
            return;
        }

        allRequests = await response.json();
        renderRequests(allRequests);
        countBadge.innerText = `${allRequests.filter(r => r.status === 'pending').length} pending`;
    } catch (error) {
        console.error("Error fetching requests:", error);
        if (tableBody) {
            tableBody.innerHTML = `<tr><td colspan="5" class="text-center text-danger py-4">Error loading requests. Check if API is running at ${API_BASE_URL}.</td></tr>`;
        }
    }
}

function renderRequests(requests) {
    const tableBody = document.getElementById("requests-table-body");
    if (!tableBody) return;
    
    tableBody.innerHTML = "";

    if (requests.length === 0) {
        tableBody.innerHTML = `<tr><td colspan="5" class="text-center py-4 text-muted">No feature requests found.</td></tr>`;
        return;
    }

    // Sort: Pending first, then by date desc
    requests.sort((a, b) => {
        if (a.status === 'pending' && b.status !== 'pending') return -1;
        if (a.status !== 'pending' && b.status === 'pending') return 1;
        return new Date(b.created_at) - new Date(a.created_at);
    });

    requests.forEach(request => {
        const row = document.createElement("tr");
        const statusClass = request.status === 'approved' ? 'bg-success' : (request.status === 'rejected' ? 'bg-danger' : 'bg-warning text-dark');
        const createdDate = new Date(request.created_at).toLocaleDateString(undefined, { 
            month: 'short', 
            day: 'numeric', 
            year: 'numeric'
        });

        row.innerHTML = `
            <td>
                <div class="fw-bold">${request.requester_username || 'User #' + request.requester}</div>
                <div class="text-muted small">Req ID: ${request.id}</div>
                <div class="mt-1">
                    <a href="user_details.html?uid=${request.requester_firebase_uid || request.requester}" class="btn btn-sm btn-link p-0 text-decoration-none small">
                        <i class="bi bi-person me-1"></i>View User
                    </a>
                </div>
            </td>
            <td>
                <span class="badge bg-light text-dark border mb-1">${request.wardrobe_name || 'Wardrobe #' + request.wardrobe}</span>
                <div>
                    <a href="wardrobe_details.html?id=${request.wardrobe}" class="btn btn-sm btn-outline-info py-0 px-2 small" title="Review items">
                        <i class="bi bi-eye"></i> Review Wardrobe
                    </a>
                </div>
            </td>
            <td class="text-muted small">${createdDate}</td>
            <td><span class="badge ${statusClass}">${request.status.toUpperCase()}</span></td>
            <td class="text-end">
                ${request.status === 'pending' ? `
                    <div class="btn-group shadow-sm">
                        <button class="btn btn-sm btn-success" onclick="approveRequest(${request.id})">
                            <i class="bi bi-check-lg me-1"></i>Approve
                        </button>
                        <button class="btn btn-sm btn-outline-danger" onclick="openRejectModal(${request.id})">
                            <i class="bi bi-x-lg me-1"></i>Reject
                        </button>
                    </div>
                ` : `
                    <div class="text-muted small text-truncate" style="max-width: 180px;" title="${request.admin_feedback || ''}">
                        ${request.admin_feedback ? `Feedback: ${request.admin_feedback}` : ''}
                    </div>
                `}
            </td>
        `;
        tableBody.appendChild(row);
    });
}

async function approveRequest(id) {
    if (!confirm("Are you sure you want to approve this wardrobe to be featured? This will also verify the creator.")) return;

    try {
        const response = await fetch(`${API_BASE_URL}/admin/feature-requests/`, {
            method: "POST",
            headers: getAuthHeaders(),
            body: JSON.stringify({ 
                request_id: id,
                status: 'approved'
            })
        });

        if (response.ok) {
            fetchRequests();
        } else {
            const err = await response.json();
            alert("Failed to approve request: " + (err.error || "Unknown error"));
        }
    } catch (error) {
        console.error("Error approving request:", error);
        alert("Network error occurred.");
    }
}

function openRejectModal(id) {
    document.getElementById("reject-request-id").value = id;
    document.getElementById("reject-feedback").value = "";
    
    const modalEl = document.getElementById('rejectModal');
    const modal = new bootstrap.Modal(modalEl);
    modal.show();
}

async function handleRejectSubmit(e) {
    e.preventDefault();
    
    const id = document.getElementById("reject-request-id").value;
    const feedback = document.getElementById("reject-feedback").value;

    try {
        const response = await fetch(`${API_BASE_URL}/admin/feature-requests/`, {
            method: "POST",
            headers: getAuthHeaders(),
            body: JSON.stringify({ 
                request_id: id,
                status: 'rejected',
                feedback: feedback
            })
        });

        if (response.ok) {
            fetchRequests();
            const modalEl = document.getElementById('rejectModal');
            const modal = bootstrap.Modal.getInstance(modalEl);
            modal.hide();
        } else {
            const err = await response.json();
            alert("Failed to reject request: " + (err.error || "Unknown error"));
        }
    } catch (error) {
        console.error("Error rejecting request:", error);
        alert("Network error occurred.");
    }
}
