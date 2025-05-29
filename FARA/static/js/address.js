document.addEventListener('DOMContentLoaded', function () {
    const apiBase = 'https://psgc.cloud/api'; // Replace with your API URL

    const regionDropdown = document.getElementById('region');
    const provinceDropdown = document.getElementById('province');
    const cityDropdown = document.getElementById('city');
    const barangayDropdown = document.getElementById('barangay');

    // Populate Regions
    fetch(`${apiBase}/regions`)
        .then(response => response.json())
        .then(data => {
            data.forEach(region => {
                const option = document.createElement('option');
                option.value = region.code ||region.name; // Use the name instead of code
                option.textContent = region.name;
                regionDropdown.appendChild(option);
            });
        });

    // Handle Region Change
    regionDropdown.addEventListener('change', function () {
        const selectedRegion = regionDropdown.value;
        document.getElementById('region-text').value = selectedRegion;

        // Clear dependent dropdowns
        provinceDropdown.innerHTML = '<option selected disabled>Choose Province</option>';
        cityDropdown.innerHTML = '<option selected disabled>Choose City/Municipality</option>';
        barangayDropdown.innerHTML = '<option selected disabled>Choose Barangay</option>';

        // Fetch provinces for the selected region
        fetch(`${apiBase}/regions/${selectedRegion}/provinces`)
            .then(response => response.json())
            .then(data => {
                data.forEach(province => {
                    const option = document.createElement('option');
                    option.value =province.code ||province.name; // Use the name instead of code
                    option.textContent = province.name;
                    provinceDropdown.appendChild(option);
                });
                provinceDropdown.disabled = false;  // Enable the province dropdown
            });
    });

    // Handle Province Change
    provinceDropdown.addEventListener('change', function () {
        const selectedProvince = provinceDropdown.value;
        document.getElementById('province-text').value = selectedProvince;

        // Clear dependent dropdowns
        cityDropdown.innerHTML = '<option selected disabled>Choose City/Municipality</option>';
        barangayDropdown.innerHTML = '<option selected disabled>Choose Barangay</option>';

        // Fetch cities/municipalities for the selected province
        fetch(`${apiBase}/provinces/${selectedProvince}/cities-municipalities`)
            .then(response => response.json())
            .then(data => {
                data.forEach(city => {
                    const option = document.createElement('option');
                    option.value = city.code || city.name; 
                    option.textContent = city.name;
                    cityDropdown.appendChild(option);
                });
                cityDropdown.disabled = false;  // Enable the city dropdown
            });
    });

    // Handle City Change
    cityDropdown.addEventListener('change', function () {
        const selectedCity = cityDropdown.value;
        document.getElementById('city-text').value = selectedCity;

        // Clear dependent dropdown
        barangayDropdown.innerHTML = '<option selected disabled>Choose Barangay</option>';

        // Fetch barangays for the selected city
        fetch(`${apiBase}/cities-municipalities/${selectedCity}/barangays`)
            .then(response => response.json())
            .then(data => {
                data.forEach(barangay => {
                    const option = document.createElement('option');
                    option.value = barangay.code ||barangay.name; // Use the name instead of code
                    option.textContent = barangay.name;
                    barangayDropdown.appendChild(option);
                });
                barangayDropdown.disabled = false;  // Enable the barangay dropdown
            });
    });

    // Handle Barangay Change
    barangayDropdown.addEventListener('change', function () {
        document.getElementById('barangay-text').value = barangayDropdown.options[barangayDropdown.selectedIndex].text;
    });

    // Form submission
    const form = document.getElementById('address-form');
    form.addEventListener('submit', function (event) {
        event.preventDefault(); // Prevent the default form submission

        // Validate that all dropdowns are selected before submitting
        if (!regionDropdown.textContent || !provinceDropdown.textContent || !cityDropdown.textContent || !barangayDropdown.textContent) {
            alert('Please select all address fields.');
            return;
        }

        // Get selected values for region, province, city, barangay, and street
        const addressData = {
            region: regionDropdown.options[regionDropdown.selectedIndex].textContent, // Use name for region
            province: provinceDropdown.options[provinceDropdown.selectedIndex].textContent, // Use name for province
            city: cityDropdown.options[cityDropdown.selectedIndex].textContent,
            barangay: barangayDropdown.options[barangayDropdown.selectedIndex].textContent, // Use name for barangay
            street: document.getElementById('street').value,  // Optional field
        };

        // Send address data to the backend
        fetch('/address', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',  // Send JSON data
            },
            body: JSON.stringify(addressData)  // Convert to JSON string
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                window.location.href = '/verify_otp';
            } else {
                alert('Error saving address: ' + data.message);
            }
        })
        .catch(error => {
            console.error('Error:', error);
        });
    });
});
