const fs = require('fs');

// Function to load GeoJSON file
function loadGeoJSON(filePath) {
    try {
        const data = fs.readFileSync(filePath, 'utf8');
        return JSON.parse(data);
    } catch (err) {
        console.error('Error reading GeoJSON file:', err);
        process.exit(1);
    }
}

// Function to convert GeoJSON coordinates to Overpass-compatible polygon
function convertToOverpassPolygon(geojson) {
    if (!geojson.features || geojson.features.length === 0) {
        throw new Error('No features found in GeoJSON');
    }

    // Assuming the first feature is a polygon
    const geometry = geojson.features[0].geometry;

    if (geometry.type !== 'Polygon') {
        throw new Error(`Unsupported geometry type: ${geometry.type}`);
    }

    const coordinates = geometry.coordinates[0]; // Outer ring of the polygon
    if (!coordinates) {
        throw new Error('No coordinates found in Polygon');
    }

    // Convert [longitude, latitude] to Overpass [latitude longitude]
    return coordinates
        .map(coord => `${coord[1]} ${coord[0]}`) // Swap longitude and latitude
        .join(' '); // Join coordinates with spaces
}

// Main function to process GeoJSON and output Overpass polygon
function main() {
    const inputFilePath = process.argv[2]; // Input GeoJSON file path from CLI
    if (!inputFilePath) {
        console.error('Usage: node geojson-to-overpass.js <geojson-file>');
        process.exit(1);
    }

    // Load and convert GeoJSON
    const geojson = loadGeoJSON(inputFilePath);
    const overpassPolygon = convertToOverpassPolygon(geojson);

    console.log('Overpass-compatible polygon:');
    console.log(overpassPolygon);
}

// Execute main function
main();
