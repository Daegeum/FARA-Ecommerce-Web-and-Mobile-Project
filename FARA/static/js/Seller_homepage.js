document.querySelectorAll('.drop-header').forEach(header => {
    header.addEventListener('click', function() {
        const dropdown = this.parentElement;
        dropdown.classList.toggle('active'); // Toggle active class
    });
});
// Toast auto-hide
setTimeout(function() {
    const toasts = document.querySelectorAll('.toast');
    toasts.forEach(toast => {
        toast.classList.remove('show');
    });
}, 3000);