// Wait until the HTML document is fully loaded in the browser
window.addEventListener('DOMContentLoaded', () => {

    const apiURL = 'https://nqo81sem29.execute-api.eu-north-1.amazonaws.com/';

    // 1. Fire the background network request to our Traffic Cop Route (GET /)
    fetch(apiURL)
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json(); // Parse the raw JSON package coming back from Lambda
        })
        .then(data => {
            // 2. Find the <span> with id="counter" and update "00" with the live number
            // Note: Making sure 'count' matches the exact key name your Lambda Python script returns!
            document.getElementById('counter').innerText = data.count; 
        })
        .catch(error => {
            console.error('Error fetching the visitor counter:', error);
            document.getElementById('counter').innerText = 'Err'; // Graceful fallback
        });
});