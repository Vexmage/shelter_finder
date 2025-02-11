const express = require("express");
const cors = require("cors");
const axios = require("axios");
require("dotenv").config({ path: "./.env" });
console.log("GOOGLE_MAPS_API_KEY:", process.env.GOOGLE_MAPS_API_KEY);

const app = express();
app.use(cors());

// ✅ Add an endpoint to serve the API key securely
app.get("/api-key", (req, res) => {
  res.send(process.env.GOOGLE_MAPS_API_KEY || "API_KEY_NOT_FOUND");
});

app.use(express.static('public')); 

app.get("/shelters", async (req, res) => {
    try {
        const { lat, lng } = req.query;
        const apiKey = process.env.GOOGLE_MAPS_API_KEY;

        if (!apiKey) {
            return res.status(500).json({ error: "API Key is missing on the server ❌" });
        }

        let allResults = [];
        let nextPageToken = null;
        let url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=15000&keyword=homeless+shelter|food+pantry&key=${apiKey}`;

        do {
            console.log(`Fetching shelters from: ${url}`);

            const response = await axios.get(url);
            const data = response.data;

            if (data.results) {
                allResults.push(...data.results);
            }

            nextPageToken = data.next_page_token;

            // If there's a next page, set up the URL for the next request
            if (nextPageToken) {
                url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?pagetoken=${nextPageToken}&key=${apiKey}`;
                // Google requires a small delay before using the next_page_token
                await new Promise(resolve => setTimeout(resolve, 2000)); 
            }
        } while (nextPageToken);

        res.json({ results: allResults });
    } catch (error) {
        console.error("Error fetching shelters:", error);
        res.status(500).json({ error: "Error fetching places" });
    }
});


const PORT = 8080;
app.listen(PORT, () => console.log(`Server running on port ${PORT} 🚀`));
