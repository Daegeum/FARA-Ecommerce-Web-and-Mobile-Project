function validateContactNumber(input) {
    // Remove any non-digit characters
    input.value = input.value.replace(/\D/g, '');

    // Ensure the input length doesn't exceed 11 digits
    if (input.value.length > 11) {
        input.value = input.value.slice(0, 11);
    }
}
// Toast auto-hide
setTimeout(function() {
    const toasts = document.querySelectorAll('.toast');
    toasts.forEach(toast => {
        toast.classList.remove('show');
    });
}, 3000);