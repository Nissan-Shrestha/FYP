const API_BASE_URL = window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1" 
    ? `http://${window.location.hostname}:8000/api` 
    : `http://localhost:8000/api`;

function getAuthHeaders() {
    const token = localStorage.getItem("admin_token");
    return {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json"
    };
}

function updateNavbar(admin) {
    if (!admin) return;
    
    // Support multiple IDs for name container
    const nameEls = document.querySelectorAll("#admin-name, #admin-name-nav");
    const avatarImg = document.getElementById("admin-avatar");
    const placeholderIcon = document.getElementById("admin-avatar-placeholder");

    nameEls.forEach(el => el.innerText = admin.username);

    if (admin.profile_picture) {
        if (avatarImg) {
            avatarImg.src = admin.profile_picture;
            avatarImg.classList.remove("d-none");
            avatarImg.style.display = "block";
        }
        if (placeholderIcon) {
            placeholderIcon.classList.add("d-none");
            placeholderIcon.style.display = "none";
        }
    }
}
