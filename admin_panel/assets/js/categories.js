let currentType = "category";
let allOptions = [];

document.addEventListener("DOMContentLoaded", () => {
    fetchOptions();

    const form = document.getElementById("optionForm");
    if (form) {
        form.addEventListener("submit", async (e) => {
            e.preventDefault();
            await saveOption();
        });
    }
});

async function fetchOptions() {
    const tableBody = document.getElementById("options-table-body");
    const url = `${API_BASE_URL}/admin/options/`;

    try {
        const response = await fetch(url, {
            headers: getAuthHeaders()
        });

        if (response.status === 401 || response.status === 403) {
            window.location.href = "login.html";
            return;
        }

        allOptions = await response.json();
        renderFilteredOptions();
    } catch (error) {
        console.error("Error fetching options:", error);
        if (tableBody) {
            tableBody.innerHTML = `<tr><td colspan="4" class="text-center text-danger">Error loading data</td></tr>`;
        }
    }
}

function renderFilteredOptions() {
    const tableBody = document.getElementById("options-table-body");
    if (!tableBody) return;

    // Show/Hide category columns
    const isCat = currentType === "category";
    document.getElementById("type-header").style.display = isCat ? "table-cell" : "none";
    document.getElementById("layer-header").style.display = isCat ? "table-cell" : "none";

    tableBody.innerHTML = "";
    const filtered = allOptions.filter(o => o.type === currentType);

    if (filtered.length === 0) {
        tableBody.innerHTML = `<tr><td colspan="${isCat ? 4 : 2}" class="text-center py-4 text-muted">No options found.</td></tr>`;
        return;
    }

    filtered.forEach(o => {
        const row = document.createElement("tr");
        let extraCols = "";
        if (isCat) {
            extraCols = `
                <td><span class="badge bg-info text-dark">${o.item_type || 'N/A'}</span></td>
                <td><span class="badge bg-secondary">${o.layer_level ?? 0}</span></td>
            `;
        }

        row.innerHTML = `
            <td><span class="fw-semibold">${o.name}</span></td>
            ${extraCols}
            <td>
                <button class="btn btn-sm btn-outline-primary me-2" onclick="openEditModal(${o.id})">
                    <i class="bi bi-pencil"></i>
                </button>
                <button class="btn btn-sm btn-outline-danger" onclick="deleteOption(${o.id}, '${o.name}')">
                    <i class="bi bi-trash"></i>
                </button>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

function switchType(type) {
    currentType = type;
    const tabs = document.querySelectorAll("#optionsTabs .nav-link");
    tabs.forEach(tab => {
        tab.classList.remove("active");
        const tabLabel = tab.innerText.toLowerCase();
        if (tabLabel === type.toLowerCase() || 
            (type === "category" && tabLabel === "categories") ||
            (type === "weather" && tabLabel === "weather")) {
            tab.classList.add("active");
        }
    });

    renderFilteredOptions();
}

function openAddModal() {
    document.getElementById("modalTitle").innerText = "Add New Option";
    document.getElementById("editOptionId").value = "";
    document.getElementById("optionTypeDisplay").value = currentType;
    document.getElementById("optionName").value = "";
    
    // Reset category fields
    document.getElementById("itemType").value = "Top";
    document.getElementById("layerLevel").value = "0";
    
    // Show category specific fields only if type is category
    document.getElementById("categorySpecificFields").style.display = currentType === "category" ? "block" : "none";
    
    const modal = new bootstrap.Modal(document.getElementById("optionModal"));
    modal.show();
}

function openEditModal(id) {
    const item = allOptions.find(o => o.id === id);
    if (!item) return;

    document.getElementById("modalTitle").innerText = "Edit Option";
    document.getElementById("editOptionId").value = id;
    document.getElementById("optionTypeDisplay").value = item.type;
    document.getElementById("optionName").value = item.name;
    
    if (item.type === "category") {
        document.getElementById("categorySpecificFields").style.display = "block";
        document.getElementById("itemType").value = item.item_type || "Top";
        document.getElementById("layerLevel").value = item.layer_level || "0";
    } else {
        document.getElementById("categorySpecificFields").style.display = "none";
    }

    const modal = new bootstrap.Modal(document.getElementById("optionModal"));
    modal.show();
}

async function saveOption() {
    const id = document.getElementById("editOptionId").value;
    const name = document.getElementById("optionName").value;
    const type = currentType;
    
    const payload = { type, name };
    
    if (type === "category") {
        payload.item_type = document.getElementById("itemType").value;
        payload.layer_level = parseInt(document.getElementById("layerLevel").value);
    }
    
    const isEdit = id !== "";
    const url = isEdit 
        ? `${API_BASE_URL}/admin/options/manage/${id}/` 
        : `${API_BASE_URL}/admin/options/manage/`;
    
    const method = isEdit ? "PATCH" : "POST";

    try {
        const response = await fetch(url, {
            method: method,
            headers: getAuthHeaders(),
            body: JSON.stringify(payload)
        });

        if (response.ok) {
            const modalEl = document.getElementById("optionModal");
            const modal = bootstrap.Modal.getInstance(modalEl);
            if (modal) modal.hide();
            fetchOptions();
        } else {
            const err = await response.json();
            alert(`Error: ${err.error || JSON.stringify(err)}`);
        }
    } catch (error) {
        alert("Network error.");
    }
}

async function deleteOption(id, name) {
    if (!confirm(`Are you sure you want to delete "${name}"?`)) return;

    try {
        const response = await fetch(`${API_BASE_URL}/admin/options/manage/${id}/`, {
            method: "DELETE",
            headers: getAuthHeaders()
        });

        if (response.ok) {
            fetchOptions();
        } else {
            alert("Failed to delete option.");
        }
    } catch (error) {
        console.error("Error deleting option:", error);
    }
}
