// Function to calculate the total amount
function calculateTotal() {
    let total = 0;  // Initialize total amount
    const cartItems = document.querySelectorAll('.card'); // Select all card elements in the cart

    cartItems.forEach(card => {
        const checkbox = card.querySelector('input[type="checkbox"]'); // Get the checkbox
        if (checkbox.checked) {
            const quantityInput = card.querySelector('.quantity-input'); // Get quantity input
            const price = parseFloat(card.querySelector('.card-text').innerText.replace('Price: ₱', '')); // Extract price
            const quantity = parseInt(quantityInput.value); // Get quantity value

            // Calculate total for the item and add to total
            total += price * quantity;
        }
    });

    // Update the total amount display
    document.getElementById('total-amount').innerText = `Total: ₱${total.toFixed(2)}`;
}

// Event listener to recalculate total on quantity change
document.querySelectorAll('.quantity-input').forEach(input => {
    input.addEventListener('change', calculateTotal);
});

// Event listener to recalculate total on checkbox change
document.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
    checkbox.addEventListener('change', calculateTotal);
});

// Initial total calculation on page load
calculateTotal();

// Toast auto-hide
setTimeout(function() {
    const toasts = document.querySelectorAll('.toast');
    toasts.forEach(toast => {
        toast.classList.remove('show');
    });
}, 3000);
