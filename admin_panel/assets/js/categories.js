let currentType = "category";
let allOptions = [];

document.addEventListener("DOMContentLoaded", () => {
    console.log("Categories script initialized.");
    fetchOptions();

    // Setup Add Option Form
    const addForm = document.getElementById("addOptionForm");
    if (addForm) {
        addForm.addEventListener("submit", async (e) => {
            e.preventDefault();
            const value = document.getElementById("optionName").value;
            if (!value) return;

            await addOption(currentType, value);
        });
    }
});

async function fetchOptions() {
    const tableBody = document.getElementById("options-table-body");
    const url = `${API_BASE_URL}/admin/options/`;

    console.log(`Fetching options from: ${url}`);

    try {
        const response = await fetch(url, {
            headers: getAuthHeaders()
        });

        console.log(`Response status: ${response.status}`);

        if (response.status === 401 || response.status === 403) {
            console.error("Auth failed. Redirecting to login.");
            window.location.href = "login.html";
            return;
        }

        if (!response.ok) {
            throw new Error(`Server returned error: ${response.statusText}`);
        }

        allOptions = await response.json();
        console.log("Options received:", allOptions);
        renderFilteredOptions();
    } catch (error) {
        console.error("Error fetching options:", error);
        if (tableBody) {
            tableBody.innerHTML = `<tr><td colspan="2" class="text-center text-danger">
                <i class="bi bi-exclamation-triangle me-2"></i>Error loading data: ${error.message}
            </td></tr>`;
        }
    }
}

function renderFilteredOptions() {
    const tableBody = document.getElementById("options-table-body");
    if (!tableBody) return;

    tableBody.innerHTML = "";
    console.log(`Rendering type: ${currentType}`);

    // Some types might be named differently in the list than the UI tab labels
    // but here we used 'category', 'season', 'occasion', 'size', 'material' in models.py
    const filtered = allOptions.filter(o => o.type === currentType);
    console.log(`Filtered count for ${currentType}: ${filtered.length}`);

    if (filtered.length === 0) {
        tableBody.innerHTML = `<tr><td colspan="2" class="text-center py-5 text-muted">
            No ${currentType} options found. Add one using the button above.
        </td></tr>`;
        return;
    }

    filtered.forEach(o => {
        const row = document.createElement("tr");
        row.innerHTML = `
            <td><span class="fw-semibold">${o.name}</span></td>
            <td>
                <button class="btn btn-sm btn-outline-danger" onclick="deleteOption(${o.id}, '${o.name}')">
                    <i class="bi bi-trash"></i>
                </button>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

function switchType(type) {
    console.log(`Switching to type: ${type}`);
    currentType = type;
    
    // Update active tab UI
    const tabs = document.querySelectorAll("#optionsTabs .nav-link");
    tabs.forEach(tab => {
        tab.classList.remove("active");
        // Check if the tab text matches or if it's the specific Category vs Categories label
        const tabLabel = tab.innerText.toLowerCase();
        if (tabLabel === type.toLowerCase() || (type === "category" && tabLabel === "categories")) {
            tab.classList.add("active");
        }
    });

    renderFilteredOptions();
}

function openAddModal() {
    const modalEl = document.getElementById("addOptionModal");
    if (!modalEl) return;
    
    document.getElementById("optionType").value = currentType;
    document.getElementById("optionName").value = "";
    
    const modal = new bootstrap.Modal(modalEl);
    modal.show();
}

async function addOption(type, name) {
    const url = `${API_BASE_URL}/admin/options/manage/`;

    try {
        const response = await fetch(url, {
            method: "POST",
            headers: getAuthHeaders(),
            body: JSON.stringify({ type, name })
        });

        if (response.ok) {
            const modalEl = document.getElementById("addOptionModal");
            const modal = bootstrap.Modal.getInstance(modalEl);
            if (modal) modal.hide();
            fetchOptions(); // Refresh list
        } else {
            const err = await response.json();
            alert(`Failed to add: ${err.error || JSON.stringify(err)}`);
        }
    } catch (error) {
        console.error("Error adding option:", error);
        alert("Network error while adding option.");
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
            fetchOptions(); // Refresh list
        } else {
            alert("Failed to delete option.");
        }
    } catch (error) {
        console.error("Error deleting option:", error);
    }
}
