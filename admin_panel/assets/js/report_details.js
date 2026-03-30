document.addEventListener("DOMContentLoaded", () => {
    const urlParams = new URLSearchParams(window.location.search);
    const reportId = urlParams.get('id');

    if (!reportId) {
        window.location.href = "reports.html";
        return;
    }

    fetchReportDetails(reportId);
});

async function fetchReportDetails(reportId) {
    try {
        const response = await fetch(`${API_BASE_URL}/admin/reports/${reportId}/`, {
            headers: getAuthHeaders()
        });

        if (!response.ok) {
            window.location.href = "reports.html";
            return;
        }

        const report = await response.json();
        renderReportDetails(report);
    } catch (error) {
        console.error("Error fetching report details:", error);
    }
}

function renderReportDetails(report) {
    document.getElementById("display-report-id").innerText = report.id;
    document.getElementById("reporter-name").innerText = report.reporter_username;
    document.getElementById("report-reason").innerText = report.reason;
    document.getElementById("report-date").innerText = new Date(report.created_at).toLocaleString();

    // Render Status Badge
    const statusContainer = document.getElementById("report-status-container");
    let badgeClass = "bg-secondary";
    if (report.status === "pending") badgeClass = "bg-warning text-dark";
    if (report.status === "resolved") badgeClass = "bg-success";
    if (report.status === "ignored") badgeClass = "bg-light text-dark border";
    
    statusContainer.innerHTML = `<span class="badge ${badgeClass} fs-6 status-pill text-uppercase">${report.status}</span>`;

    renderModerationControls(report);
    renderOutfitPreview(report);
    renderReportedUserProfile(report);
}

function renderReportedUserProfile(report) {
    const outfit = report.outfit_details;
    const nameEl = document.getElementById("reported-user-name");
    const imgEl = document.getElementById("reported-user-img");
    const resetNameBtn = document.getElementById("reset-username-btn");
    const resetAvatarBtn = document.getElementById("reset-avatar-btn");

    if (!outfit) {
        nameEl.innerText = "Unknown User";
        imgEl.src = "assets/img/avatar-placeholder.png";
        resetNameBtn.disabled = true;
        resetAvatarBtn.disabled = true;
        return;
    }

    nameEl.innerText = outfit.owner_username;
    if (outfit.owner_profile_picture) {
        imgEl.src = outfit.owner_profile_picture;
    }

    resetNameBtn.onclick = () => resetUserModeration(outfit.owner_firebase_uid, 'username');
    resetAvatarBtn.onclick = () => resetUserModeration(outfit.owner_firebase_uid, 'avatar');
}

function renderModerationControls(report) {
    const container = document.getElementById("moderation-controls");
    container.innerHTML = "";

    const hasOutfit = !!report.outfit;
    const ownerUid = report.outfit_details?.owner_firebase_uid;

    if (report.status === "pending") {
        container.innerHTML += `
            <a href="#" class="list-group-item list-group-item-action py-3 border-start-4 border-success" onclick="handleAction(${report.id}, 'resolve')">
                <i class="bi bi-check-circle text-success me-2 fs-5"></i>
                <div><div class="fw-bold">Mark as Resolved</div><div class="small text-muted">Keep content but clear report.</div></div>
            </a>
            <a href="#" class="list-group-item list-group-item-action py-3 border-start-4 border-secondary" onclick="handleAction(${report.id}, 'ignore')">
                <i class="bi bi-eye-slash text-muted me-2 fs-5"></i>
                <div><div class="fw-bold">Ignore Report</div><div class="small text-muted">Reject and close this report.</div></div>
            </a>
        `;
    }

    if (hasOutfit) {
        container.innerHTML += `
            <a href="#" class="list-group-item list-group-item-action py-3 border-start-4 border-danger" onclick="handleAction(${report.id}, 'delete_outfit')">
                <i class="bi bi-trash-fill text-danger me-2 fs-5"></i>
                <div><div class="fw-bold">Delete Reported Outfit</div><div class="small text-muted">Permanently remove this content.</div></div>
            </a>
        `;
    }

    if (ownerUid) {
        container.innerHTML += `
            <hr class="m-0">
            <a href="user_details.html?uid=${ownerUid}" class="list-group-item list-group-item-action py-3 border-start-4 border-info">
                <i class="bi bi-person-fill text-info me-2 fs-5"></i>
                <div><div class="fw-bold">Inspect Full Profile</div><div class="small text-muted">View user history and items.</div></div>
            </a>
        `;
    }
}

function renderOutfitPreview(report) {
    const container = document.getElementById("outfit-preview-container");
    const ownerBadge = document.getElementById("outfit-owner-badge");
    const outfit = report.outfit_details;

    if (!outfit) {
        container.innerHTML = `
            <div class="text-center py-5">
                <i class="bi bi-file-earmark-x fs-1 text-muted"></i>
                <h5 class="mt-3">Content Not Found</h5>
                <p class="text-muted">The reported outfit has been deleted or moved.</p>
            </div>
        `;
        return;
    }

    ownerBadge.innerHTML = `<span class="badge bg-primary rounded-pill">By ${outfit.owner_username}</span>`;

    let itemsHtml = "";
    if (outfit.items && outfit.items.length > 0) {
        itemsHtml = `
            <div class="row g-2">
                ${outfit.items.map(item => `
                    <div class="col-4 col-md-3">
                        <img src="${item.image || 'assets/img/placeholder.png'}" class="item-preview border" title="${item.name}">
                        <div class="small text-truncate mt-1">${item.name}</div>
                    </div>
                `).join('')}
            </div>
        `;
    }

    container.innerHTML = `
        <div class="mb-4">
            <h3 class="fw-bold">${outfit.name}</h3>
            <span class="badge bg-light text-dark border">${outfit.occasion}</span>
            <span class="ms-2 small text-muted"><i class="bi bi-bookmark-heart ms-1"></i> ${outfit.saves_count} saves</span>
        </div>
        <div>
            <h6 class="text-uppercase small fw-bold text-muted mb-3">Included Clothing Items</h6>
            ${itemsHtml}
        </div>
    `;
}

async function handleAction(reportId, action) {
    if (action === 'delete_outfit' && !confirm("Delete this outfit permanently?")) return;
    
    try {
        const response = await fetch(`${API_BASE_URL}/admin/reports/${reportId}/action/`, {
            method: "POST",
            headers: getAuthHeaders(),
            body: JSON.stringify({ action: action })
        });

        if (response.ok) {
            window.location.href = "reports.html";
        } else {
            const err = await response.json();
            alert(err.error || "Failed!");
        }
    } catch (error) {
        console.error("Error:", error);
    }
}

async function resetUserModeration(uid, target) {
    if (!confirm(`Reset this user's ${target}?`)) return;
    try {
        const response = await fetch(`${API_BASE_URL}/admin/users/${uid}/moderation-reset/`, {
            method: "POST",
            headers: getAuthHeaders(),
            body: JSON.stringify({ target: target })
        });

        if (response.ok) {
            window.location.href = "reports.html";
        } else {
            const err = await response.json();
            alert(err.error || "Failed!");
        }
    } catch (error) {
        console.error("Error:", error);
    }
}
