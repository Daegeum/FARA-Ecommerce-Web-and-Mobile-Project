// buyer_userprof.js

document.addEventListener('DOMContentLoaded', function () {
    // Select all order item cards
    const orderItems = document.querySelectorAll('.order-item-card');

    orderItems.forEach(item => {
        // Get the status from the data attribute
        const statusBar = item.querySelector('.status-bar');
        const statusFill = item.querySelector('.status-fill');
        const status = statusBar.getAttribute('data-status');

        // Set fill width based on status
        let fillWidth = '0%'; // Default fill width
        switch (status) {
            case 'Delivered':
                fillWidth = '100%';
                statusFill.style.backgroundColor = 'green'; // Green for delivered
                break;
            case 'To Receive':
                fillWidth = '75%';
                statusFill.style.backgroundColor = 'yellow'; // Yellow for to receive
                break;
            case 'To Ship':
                fillWidth = '50%';
                statusFill.style.backgroundColor = 'orange'; // Orange for to ship
                break;
            case 'Pending':
                fillWidth = '25%';
                statusFill.style.backgroundColor = 'red'; // Red for pending
                break;
            default:
                fillWidth = '0%'; // No status
                statusFill.style.backgroundColor = 'grey'; // Grey for unknown
                break;
        }

        // Set the width of the status fill
        statusFill.style.width = fillWidth;
    });
});

// Toast auto-hide
setTimeout(function() {
    const toasts = document.querySelectorAll('.toast');
    toasts.forEach(toast => {
        toast.classList.remove('show');
    });
}, 3000);