// Tabs Login / Registro
const loginTab = document.getElementById('login-tab');
const registerTab = document.getElementById('register-tab');
const loginForm = document.getElementById('login-form');
const registerForm = document.getElementById('register-form');
const roleButtons = document.querySelectorAll('.role-btn');
const roleInput = document.getElementById('reg-role');

// Cambiar a Login
loginTab.addEventListener('click', () => {
    loginForm.style.display = 'block';
    registerForm.style.display = 'none';

    loginTab.classList.add('active');
    registerTab.classList.remove('active');
});

// Cambiar a Registro
registerTab.addEventListener('click', () => {
    loginForm.style.display = 'none';
    registerForm.style.display = 'block';

    loginTab.classList.remove('active');
    registerTab.classList.add('active');
});

// Toggle contraseña login
const togglePassword = document.getElementById('togglePassword');
const password = document.getElementById('password');

togglePassword.addEventListener('click', () => {
    const type = password.getAttribute('type') === 'password' ? 'text' : 'password';
    password.setAttribute('type', type);
    togglePassword.classList.toggle('fa-eye-slash');
});

// Toggle contraseña registro
const toggleRegPassword = document.getElementById('toggleRegPassword');
const regPassword = document.getElementById('reg-password');

toggleRegPassword.addEventListener('click', () => {
    const type = regPassword.getAttribute('type') === 'password' ? 'text' : 'password';
    regPassword.setAttribute('type', type);
    toggleRegPassword.classList.toggle('fa-eye-slash');
});

// Selector de rol
roleButtons.forEach(btn => {
    btn.addEventListener('click', () => {
        roleButtons.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');

        roleInput.value = btn.dataset.role;
        console.log("Rol seleccionado:", roleInput.value);
    });
});
