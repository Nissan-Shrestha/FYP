// auth.js
// Initialize Firebase
firebase.initializeApp(FIREBASE_CONFIG);
const auth = firebase.auth();

if (document.getElementById("login-form")) {
    document.getElementById("login-form").addEventListener("submit", async (e) => {
        e.preventDefault();
        
        const email = document.getElementById("floatingEmail").value;
        const password = document.getElementById("floatingPassword").value;
        const errorDiv = document.getElementById("login-error");
        
        try {
            const userCredential = await auth.signInWithEmailAndPassword(email, password);
            const token = await userCredential.user.getIdToken();
            
            // Store the token in localStorage
            localStorage.setItem("admin_token", token);
            
            // Redirect to dashboard
            window.location.href = "index.html";
        } catch (error) {
            console.error("Login failed:", error);
            errorDiv.innerText = error.message;
            errorDiv.classList.remove("d-none");
        }
    });
}

const logoutBtn = document.getElementById("admin-logout");
if (logoutBtn) {
    logoutBtn.addEventListener("click", async (e) => {
        e.preventDefault();
        try {
            await auth.signOut();
            localStorage.removeItem("admin_token");
            window.location.href = "login.html";
        } catch (error) {
            console.error("Logout failed:", error);
        }
    });

    // Auto-fetch admin profile for the navbar if we are on a page with a logout button
    (async () => {
        try {
            const response = await fetch(`${API_BASE_URL}/admin/me/`, {
                headers: getAuthHeaders()
            });
            if (response.ok) {
                const admin = await response.json();
                updateNavbar(admin);
            }
        } catch (error) {
            console.error("Failed to fetch admin profile for navbar:", error);
        }
    })();
}
