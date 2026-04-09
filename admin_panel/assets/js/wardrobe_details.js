document.addEventListener("DOMContentLoaded", () => {
    const urlParams = new URLSearchParams(window.location.search);
    const wardrobeId = urlParams.get('id');

    if (wardrobeId) {
        fetchWardrobeDetails(wardrobeId);
    } else {
        window.location.href = "feature_requests.html";
    }
});

async function fetchWardrobeDetails(id) {
    const grid = document.getElementById("items-grid");
    const nameEl = document.getElementById("wardrobe-name");
    const countEl = document.getElementById("wardrobe-count");

    // Correct ADMIN endpoint for detailed review
    const url = `${API_BASE_URL}/admin/wardrobes/${id}/`;

    try {
        const response = await fetch(url, {
            headers: getAuthHeaders()
        });

        if (response.status === 401 || response.status === 403) {
            window.location.href = "login.html";
            return;
        }

        if (!response.ok) {
            grid.innerHTML = `<div class="col-12 text-center text-danger py-4">Error fetching wardrobe items. Ensure you have admin access.</div>`;
            return;
        }

        const data = await response.json();
        
        nameEl.innerText = `Wardrobe: ${data.name}`;
        countEl.innerText = `${data.items_details.length} Items found in this collection`;
        
        renderItems(data.items_details);
    } catch (error) {
        console.error("Error fetching items:", error);
        grid.innerHTML = `<div class="col-12 text-center text-danger py-4">Network error. Please try again.</div>`;
    }
}

function renderItems(items) {
    const grid = document.getElementById("items-grid");
    grid.innerHTML = "";

    if (items.length === 0) {
        grid.innerHTML = `<div class="col-12 text-center py-4 text-muted">This wardrobe is empty.</div>`;
        return;
    }

    items.forEach(item => {
        const col = document.createElement("div");
        col.className = "col-md-3";
        
        const imageUrl = item.image || "https://placehold.co/400x400/f8f9fa/adb5bd?text=No+Image";
        const purchaseLinkBtn = item.purchase_link 
            ? `<a href="${item.purchase_link}" target="_blank" class="btn btn-sm btn-outline-primary w-100 mt-2">View Product</a>`
            : "";

        col.innerHTML = `
            <div class="card h-100 clothing-item-card">
                <img src="${imageUrl}" class="card-img-top item-image" alt="${item.name}">
                <div class="card-body p-3">
                    <h6 class="card-title fw-bold text-truncate mb-1">${item.name}</h6>
                    <div class="d-flex justify-content-between mb-2">
                        <span class="badge bg-light text-dark border small">${item.item_type}</span>
                        <span class="badge bg-light text-dark border small">${item.category}</span>
                    </div>
                    <div class="small text-muted mb-3">
                        ${item.season} • ${item.occasion}
                    </div>
                    ${purchaseLinkBtn}
                </div>
            </div>
        `;
        grid.appendChild(col);
    });
}
