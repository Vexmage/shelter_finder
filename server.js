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

        console.log("Using API Key:", apiKey); // Debugging

        const radius = 8000; // Increase to 10km (or more)
        const url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=${radius}&keyword=homeless+shelter|food+pantry&key=${apiKey}`;

        const response = await axios.get(url);
        res.json(response.data);
    } catch (error) {
        console.error("Error fetching shelters:", error);
        res.status(500).json({ error: "Error fetching places" });
    }
});

const PORT = 8080;
app.listen(PORT, () => console.log(`Server running on port ${PORT} 🚀`));
