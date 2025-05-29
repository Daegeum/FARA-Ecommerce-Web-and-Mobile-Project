document.querySelectorAll('.drop-header').forEach(header => {
    header.addEventListener('click', function() {
        const dropdown = this.parentElement;
        dropdown.classList.toggle('active'); // Toggle active class
    });
});

function fetchSellerOrders() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', '/seller/orders', true);  // Assume this route fetches seller-specific orders
    xhr.onload = function() {
        if (xhr.status === 200) {
            var orders = JSON.parse(xhr.responseText);
            var orderList = document.getElementById('order-list');
            orderList.innerHTML = '';  // Clear the list before appending new items

            orders.forEach(function(order) {
                var li = document.createElement('li');
                li.textContent = 'Order ID: ' + order.order_id + ', Buyer ID: ' + order.buyer_id + ', Product: ' + order.product_name;
                orderList.appendChild(li);
            });
        } else {
            console.error('Failed to fetch orders');
        }
    };
    xhr.send();
}

// Poll every 5 seconds
setInterval(fetchSellerOrders, 5000);

// Fetch immediately on page load
fetchSellerOrders();

// Function to add a new product
document.getElementById('add-product-form').addEventListener('submit', function(event) {
    event.preventDefault();  // Prevent the default form submission

    var formData = new FormData(this);  // Create FormData object to handle form data

    var xhr = new XMLHttpRequest();
    xhr.open('POST', '/seller/add_product', true);
    xhr.onload = function() {
        var messageDiv = document.getElementById('message');
        if (xhr.status === 200) {
            // Success
            messageDiv.className = 'message success';
            messageDiv.textContent = 'Product added successfully!';
            messageDiv.style.display = 'block';
            // Clear the form
            document.getElementById('add-product-form').reset();
        } else {
            // Error
            messageDiv.className = 'message error';
            messageDiv.textContent = 'Error adding product: ' + xhr.responseText;
            messageDiv.style.display = 'block';
        }
    };
    xhr.send(formData);  // Send the form data
});

// Toast auto-hide
setTimeout(function() {
    const toasts = document.querySelectorAll('.toast');
    toasts.forEach(toast => {
        toast.classList.remove('show');
    });
}, 3000);