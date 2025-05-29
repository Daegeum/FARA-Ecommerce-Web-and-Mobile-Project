document.querySelectorAll('.drop-header').forEach(header => {
    header.addEventListener('click', function() {
        const dropdown = this.parentElement;
        dropdown.classList.toggle('active'); // Toggle active class
    });
});

function updateCartCount() {
    fetch('/cart/count')
        .then(response => response.json())
        .then(data => {
            // Log the data to make sure the correct count is being received
            console.log('Updated cart count:', data.count);
            document.getElementById('cart-total').textContent = data.count;
        })
        .catch(error => console.error('Error fetching cart count:', error));
}

// Call the function to update cart count when the page loads
document.addEventListener('DOMContentLoaded', updateCartCount);

// Toast auto-hide
setTimeout(function() {
    const toasts = document.querySelectorAll('.toast');
    toasts.forEach(toast => {
        toast.classList.remove('show');
    });
}, 3000);