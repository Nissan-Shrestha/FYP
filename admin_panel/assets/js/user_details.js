let currentUid = null;

document.addEventListener("DOMContentLoaded", () => {
    const urlParams = new URLSearchParams(window.location.search);
    currentUid = urlParams.get("uid");

    if (!currentUid) {
        window.location.href = "users.html";
        return;
    }

    fetchUserDetails(currentUid);
});

async function fetchUserDetails(uid) {
    // ... no change to fetch line
    let url = `${API_BASE_URL}/admin/users/${uid}/details/`;

    try {
        const response = await fetch(url, {
            headers: getAuthHeaders()
        });

        if (response.status === 401 || response.status === 403) {
            window.location.href = "login.html";
            return;
        }

        const data = await response.json();
        renderHeader(data.profile);
        renderWardrobes(data.wardrobes);
        renderClothingItems(data.items);
    } catch (error) {
        console.error("Error fetching user details:", error);
    }
}

function renderHeader(profile) {
    document.getElementById("user-display-name").innerText = profile.username;
    document.getElementById("user-email").innerText = profile.email;
    document.getElementById("user-plan-badge").innerText = profile.plan;
    document.getElementById("user-role-badge").innerText = profile.is_admin ? "Administrator" : "Regular User";

    const hasPicture = !!profile.profile_picture;
    const avatarUrl = profile.profile_picture || "https://img.icons8.com/color/150/test-account.png";
    document.getElementById("user-avatar-container").innerHTML = `
        <img src="${avatarUrl}" class="rounded-circle border border-4 border-white shadow-sm" width="120" height="120" style="object-fit: cover;">
    `;

    // Show/hide delete button
    const actions = document.getElementById("avatar-actions");
    if (hasPicture) {
        actions.classList.remove("d-none");
    } else {
        actions.classList.add("d-none");
    }
}

async function deleteAvatar() {
    if (!confirm("Are you sure you want to remove this user's profile picture?")) return;

    try {
        const response = await fetch(`${API_BASE_URL}/admin/users/${currentUid}/avatar/`, {
            method: "DELETE",
            headers: getAuthHeaders()
        });

        if (response.ok) {
            fetchUserDetails(currentUid); // Refresh
        } else {
            alert("Failed to delete profile picture.");
        }
    } catch (error) {
        console.error("Error deleting avatar:", error);
    }
}


function renderWardrobes(wardrobes) {
    const list = document.getElementById("wardrobe-list");
    list.innerHTML = "";

    if (wardrobes.length === 0) {
        list.innerHTML = '<div class="list-group-item text-center py-4 text-muted">No wardrobes found.</div>';
        return;
    }

    wardrobes.forEach(w => {
        const item = document.createElement("div");
        item.className = "list-group-item p-3";
        item.innerHTML = `
            <div class="d-flex justify-content-between align-items-center">
                <div class="fw-bold">${w.name} ${w.is_default ? '<span class="badge bg-secondary border ms-1">Default</span>' : ''}</div>
                <span class="badge bg-light text-dark border">${w.items.length} items</span>
            </div>
            <div class="small text-muted mt-1">Created: ${new Date(w.created_at).toLocaleDateString()}</div>
        `;
        list.appendChild(item);
    });
}

function renderClothingItems(items) {
    const grid = document.getElementById("clothing-items-grid");
    const countBadge = document.getElementById("item-count-badge");
    grid.innerHTML = "";
    countBadge.innerText = `${items.length} items`;

    if (items.length === 0) {
        grid.innerHTML = '<div class="col-12 text-center py-5 text-muted">User has no clothing items uploaded.</div>';
        return;
    }

    items.forEach(item => {
        const col = document.createElement("div");
        col.className = "col-md-4 col-sm-6";
        const imageUrl = item.image ? item.image : "https://via.placeholder.com/150";
        col.innerHTML = `
            <div class="card h-100 item-card border-0 shadow-sm overflow-hidden">
                <img src="${imageUrl}" class="card-img-top item-img" alt="${item.name}">
                <div class="card-body p-3">
                    <h6 class="fw-bold mb-1">${item.name}</h6>
                    <div class="small text-muted mb-2">${item.category} | ${item.season}</div>
                    <div class="d-flex justify-content-between align-items-center mt-auto">
                        <span class="badge bg-light text-dark border">${item.brand || 'Generic'}</span>
                    </div>
                </div>
            </div>
        `;
        grid.appendChild(col);
    });
}
