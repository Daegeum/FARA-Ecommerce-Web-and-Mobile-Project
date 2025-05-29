document.getElementById('addShippingAddressBtn').onclick = function() {
    document.getElementById('shippingAddressModal').style.display = 'block';
};

function closeModal() {
    document.getElementById('shippingAddressModal').style.display = 'none';
}

// Toast auto-hide
setTimeout(function() {
    const toasts = document.querySelectorAll('.toast');
    toasts.forEach(toast => {
        toast.classList.remove('show');
    });
}, 3000);