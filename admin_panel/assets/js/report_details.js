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

    // Render Description if exists
    const descContainer = document.getElementById("report-description-container");
    const descEl = document.getElementById("report-description");
    if (report.description && report.description.trim() !== "") {
        descEl.innerText = report.description;
        descContainer.classList.remove("d-none");
    } else {
        descContainer.classList.add("d-none");
    }

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
    const feat = report.featured_request_details;
    const nameEl = document.getElementById("reported-user-name");
    const imgEl = document.getElementById("reported-user-img");
    const resetNameBtn = document.getElementById("reset-username-btn");
    const resetAvatarBtn = document.getElementById("reset-avatar-btn");

    const ownerName = outfit ? outfit.owner_username : (feat ? feat.requester_username : "Unknown User");
    const ownerImg = outfit ? outfit.owner_profile_picture : (feat ? feat.requester_profile_picture : null);
    const ownerUid = outfit ? outfit.owner_firebase_uid : (feat ? feat.requester_firebase_uid : null);

    nameEl.innerText = ownerName;
    if (ownerImg) {
        imgEl.src = ownerImg;
    }

    // Render Bio
    const bio = outfit ? outfit.owner_bio : (feat ? feat.requester_bio : null);
    const bioContainer = document.getElementById("reported-user-bio-container");
    const bioText = document.getElementById("reported-user-bio");
    if (bio && bio.trim() !== "") {
        bioText.innerText = bio;
        bioContainer.classList.remove("d-none");
    } else {
        bioContainer.classList.add("d-none");
    }

    // Render Socials
    const socials = outfit ? outfit.owner_social_links : (feat ? feat.requester_social_links : null);
    const socialsContainer = document.getElementById("reported-user-socials-container");
    const socialsList = document.getElementById("reported-user-socials");
    socialsList.innerHTML = "";

    let hasSocials = false;
    if (socials) {
        const platforms = [
            { key: 'instagram', icon: 'bi-instagram', color: 'text-danger', baseUrl: 'https://instagram.com/' },
            { key: 'twitter', icon: 'bi-twitter-x', color: 'text-primary', baseUrl: 'https://twitter.com/' },
            { key: 'tiktok', icon: 'bi-tiktok', color: 'text-dark', baseUrl: 'https://tiktok.com/@' }
        ];

        platforms.forEach(platform => {
            if (socials[platform.key] && socials[platform.key].trim() !== "") {
                hasSocials = true;
                const handle = String(socials[platform.key]).replace('@', '');
                socialsList.innerHTML += `
                    <a href="${platform.baseUrl}${handle}" target="_blank" class="btn btn-sm btn-light border d-flex align-items-center gap-2 mb-2">
                        <i class="bi ${platform.icon} ${platform.color} fs-6"></i>
                        <span class="fw-medium">${socials[platform.key]}</span>
                    </a>
                `;
            }
        });
    }

    if (hasSocials) {
        socialsContainer.classList.remove("d-none");
    } else {
        socialsContainer.classList.add("d-none");
    }

    if (!ownerUid) {
        resetNameBtn.disabled = true;
        resetAvatarBtn.disabled = true;
    } else {
        resetNameBtn.onclick = () => resetUserModeration(ownerUid, 'username');
        resetAvatarBtn.onclick = () => resetUserModeration(ownerUid, 'avatar');
    }
}

function renderModerationControls(report) {
    const container = document.getElementById("moderation-controls");
    container.innerHTML = "";

    const hasOutfit = !!report.outfit;
    const hasFeatured = !!report.featured_request;
    const ownerUid = report.outfit_details?.owner_firebase_uid || report.featured_request_details?.requester_firebase_uid;

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

    if (hasFeatured) {
        container.innerHTML += `
            <a href="#" class="list-group-item list-group-item-action py-3 border-start-4 border-danger" onclick="handleAction(${report.id}, 'remove_featured')">
                <i class="bi bi-x-circle-fill text-danger me-2 fs-5"></i>
                <div><div class="fw-bold">Remove from Discovery</div><div class="small text-muted">Un-feature and demote user's Trusted Status.</div></div>
            </a>
        `;
    }

}


function renderOutfitPreview(report) {
    const container = document.getElementById("outfit-preview-container");
    const ownerBadge = document.getElementById("outfit-owner-badge");

    // Support both Outfit and Featured Wardrobe reports
    const content = report.outfit_details || report.featured_request_details?.wardrobe_details;
    const isWardrobe = !!report.featured_request;

    if (!content) {
        container.innerHTML = `
            <div class="text-center py-5">
                <i class="bi bi-file-earmark-x fs-1 text-muted"></i>
                <h5 class="mt-3">Content Not Found</h5>
                <p class="text-muted">The reported content has been deleted or moved.</p>
            </div>
        `;
        return;
    }

    const ownerName = report.outfit_details ? report.outfit_details.owner_username : report.featured_request_details.requester_username;
    ownerBadge.innerHTML = `<span class="badge bg-primary rounded-pill">By ${ownerName}</span>`;

    let itemsHtml = "";
    // Note: Outfit has 'items', Wardrobe serializer for requests might not have full items if it's the simplified one, 
    // but our new serializer uses WardrobeSerializer which has item_count and thumbnail.
    // However, for review, it's better if we fetch the full wardrobe items.
    // Given the current scope, we'll show what we have.

    if (content.items && content.items.length > 0) {
        itemsHtml = `
            <div class="row g-3">
                ${content.items.map(item => `
                    <div class="col-6 col-md-4">
                        <div class="card h-100 shadow-sm border">
                            <img src="${item.image || 'assets/img/placeholder.png'}" class="card-img-top item-preview" style="object-fit: contain; padding: 10px; background: #fff;">
                            <div class="card-body p-2">
                                <div class="fw-bold small text-truncate" title="${item.name}">${item.name}</div>
                                <div class="mt-2">
                                    <span class="badge bg-light text-dark border small" style="font-size: 0.65rem;">${item.category}</span>
                                    <span class="badge bg-secondary small" style="font-size: 0.65rem;">${item.item_type}</span>
                                </div>
                                ${item.brand && item.brand !== "None" ? `<div class="small text-muted mt-1" style="font-size: 0.7rem;"><i class="bi bi-tag me-1"></i>${item.brand}</div>` : ''}
                            </div>
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    } else if (isWardrobe && content.thumbnail) {
        itemsHtml = `
            <div class="mb-3">
                <img src="${content.thumbnail}" class="img-fluid rounded border" style="max-height: 200px;">
                <p class="mt-2 text-muted small">Wardrobe Preview (contains ${content.item_count} items)</p>
            </div>
        `;
    }

    container.innerHTML = `
        <div class="mb-4">
            <h3 class="fw-bold">${content.name}</h3>
            <span class="badge bg-light text-dark border">${isWardrobe ? 'Wardrobe' : (content.occasion || 'Outfit')}</span>
            ${!isWardrobe ? `<span class="ms-2 small text-muted"><i class="bi bi-bookmark-heart ms-1"></i> ${content.saves_count} saves</span>` : ''}
        </div>
        <div>
            <h6 class="text-uppercase small fw-bold text-muted mb-3">${isWardrobe ? 'Wardrobe Contents' : 'Included Clothing Items'}</h6>
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
