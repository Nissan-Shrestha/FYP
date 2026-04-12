let allUsers = [];

document.addEventListener("DOMContentLoaded", () => {
    fetchUsers();

    // Setup form listener
    const editForm = document.getElementById("edit-user-form");
    if (editForm) {
        editForm.addEventListener("submit", handleEditSubmit);
    }
});

async function fetchUsers() {
    // ... no changes to fetchUsers except storing data
    const tableBody = document.getElementById("all-users-table-body");
    const countBadge = document.getElementById("user-count-badge");
    
    let url = `${API_BASE_URL}/admin/users/`;

    try {
        const response = await fetch(url, {
            headers: getAuthHeaders()
        });

        if (response.status === 401 || response.status === 403) {
            window.location.href = "login.html";
            return;
        }

        allUsers = await response.json();
        renderUsers(allUsers);
        countBadge.innerText = `${allUsers.length} users`;
    } catch (error) {
        console.error("Error fetching users:", error);
        tableBody.innerHTML = `<tr><td colspan="6" class="text-center text-danger py-4">Error loading users data.</td></tr>`;
    }
}

function renderUsers(users) {
    const tableBody = document.getElementById("all-users-table-body");
    tableBody.innerHTML = "";

    if (users.length === 0) {
        tableBody.innerHTML = `<tr><td colspan="6" class="text-center py-4 text-muted">No users found.</td></tr>`;
        return;
    }

    users.forEach(user => {
        const row = document.createElement("tr");
        const planBadgeClass = user.plan.toLowerCase() === "premium" ? "bg-success" : "bg-info text-dark";
        let roleBadge;
        if (user.is_superadmin) {
            roleBadge = '<span class="badge" style="background: linear-gradient(135deg, #d4af37, #f5d060); color: #333;">Superadmin</span>';
        } else if (user.is_admin) {
            roleBadge = '<span class="badge bg-danger">Admin</span>';
        } else {
            roleBadge = '<span class="badge bg-light text-dark border">User</span>';
        }
        const joinDate = user.created_at ? new Date(user.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' }) : "N/A";
        
        const avatarUrl = user.profile_picture || "https://img.icons8.com/color/96/test-account.png";

        const deleteBtn = user.is_superadmin ? '' : `<button class="btn btn-sm btn-outline-danger" onclick="deleteUser('${user.firebase_uid}', '${user.username.replace(/'/g, "\\'")}')"><i class="bi bi-trash"></i></button>`;

        row.innerHTML = `
            <td>
                <div class="d-flex align-items-center">
                    <img src="${avatarUrl}" class="rounded-circle me-3" width="40" height="40" style="object-fit: cover; border: 1px solid #ddd;">
                    <span class="fw-semibold">${user.username}</span>
                </div>
            </td>
            <td>${user.email}</td>
            <td><span class="badge ${planBadgeClass}">${user.plan}</span></td>
            <td>${roleBadge}</td>
            <td class="text-muted small">${joinDate}</td>
            <td>
                <div class="btn-group">
                    <button class="btn btn-sm btn-outline-primary" onclick="openEditModal('${user.firebase_uid}')" title="Edit User"><i class="bi bi-pencil"></i></button>
                    <a href="user_details.html?uid=${user.firebase_uid}" class="btn btn-sm btn-outline-secondary" title="View Details"><i class="bi bi-eye"></i></a>
                    ${deleteBtn}
                </div>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

function openEditModal(firebaseUid) {
    const user = allUsers.find(u => u.firebase_uid === firebaseUid);
    if (!user) return;

    document.getElementById("edit-user-firebase-uid").value = user.firebase_uid;
    document.getElementById("edit-username").value = user.username;
    document.getElementById("edit-plan").value = user.plan;
    document.getElementById("edit-is-admin").checked = user.is_admin;

    // Disable admin toggle for superadmins (they cannot be demoted)
    const adminCheckbox = document.getElementById("edit-is-admin");
    const superadminWarning = document.getElementById("superadmin-warning");
    if (user.is_superadmin) {
        adminCheckbox.disabled = true;
        if (superadminWarning) superadminWarning.classList.remove("d-none");
    } else {
        adminCheckbox.disabled = false;
        if (superadminWarning) superadminWarning.classList.add("d-none");
    }

    const modal = new bootstrap.Modal(document.getElementById('editUserModal'));
    modal.show();
}

async function handleEditSubmit(e) {
    e.preventDefault();
    
    const firebaseUid = document.getElementById("edit-user-firebase-uid").value;
    const username = document.getElementById("edit-username").value;
    const plan = document.getElementById("edit-plan").value;
    const is_admin = document.getElementById("edit-is-admin").checked;

    try {
        const response = await fetch(`${API_BASE_URL}/admin/users/${firebaseUid}/`, {
            method: "PATCH",
            headers: getAuthHeaders(),
            body: JSON.stringify({
                username,
                plan,
                is_admin
            })
        });

        if (response.ok) {
            // Reload the table
            fetchUsers();
            
            // Hide modal (using bootstrap instance)
            const modalEl = document.getElementById('editUserModal');
            const modal = bootstrap.Modal.getInstance(modalEl);
            modal.hide();
        } else {
            const data = await response.json();
            alert(data.error || "Failed to update user.");
        }
    } catch (error) {
        console.error("Error updating user:", error);
    }
}

async function deleteUser(firebaseUid, username) {
    if (!confirm(`Are you sure you want to permanently delete user "${username}"?\n\nThis will remove ALL their data (wardrobes, clothing items, outfits, schedules) and their Firebase account. This action cannot be undone.`)) {
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/admin/users/${firebaseUid}/delete/`, {
            method: "DELETE",
            headers: getAuthHeaders()
        });

        const data = await response.json();

        if (response.ok) {
            alert(data.message || "User deleted successfully.");
            fetchUsers();
        } else {
            alert(data.error || "Failed to delete user.");
        }
    } catch (error) {
        console.error("Error deleting user:", error);
        alert("An error occurred while deleting the user.");
    }
}
