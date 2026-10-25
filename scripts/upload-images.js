// Uploads every picture in images/animals (and images/shelters, if it exists) to Cloudinary
// and writes the resulting URLs to images/cloudinary-urls.json.
// scripts/gen-data.js then puts those URLs into the CSV files (Animals.photo, Shelters.imageUrl).
//
// Run from the project root (node 20+ reads the keys from .env with --env-file):
//   node --env-file=.env scripts/upload-images.js
//
// Why a one-time script and not code in the app: Cloudinary URLs are public, so the app only
// needs to store the URL. The secret key is only needed here, on your laptop, never on BTP.
const fs = require('fs');
const path = require('path');
const cloudinary = require('cloudinary').v2;

const { CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET } = process.env;
if (!CLOUDINARY_CLOUD_NAME || !CLOUDINARY_API_KEY || !CLOUDINARY_API_SECRET) {
    console.error('Missing Cloudinary keys. Run: node --env-file=.env scripts/upload-images.js');
    process.exit(1);
}
cloudinary.config({
    cloud_name: CLOUDINARY_CLOUD_NAME,
    api_key: CLOUDINARY_API_KEY,
    api_secret: CLOUDINARY_API_SECRET,
    secure: true            // https URLs
});

const ROOT = path.join(__dirname, '..');
const OUT = path.join(ROOT, 'images', 'cloudinary-urls.json');
const PICTURE = /\.(jpe?g|jfif|png|webp)$/i;

async function main() {
    const result = {};
    for (const kind of ['animals', 'shelters']) {
        const dir = path.join(ROOT, 'images', kind);
        if (!fs.existsSync(dir)) continue;
        for (const file of fs.readdirSync(dir).filter(f => PICTURE.test(f))) {
            // public_id = file name without extension, so uploading again REPLACES the picture
            // (overwrite: true) instead of creating a copy with a random name
            const publicId = path.parse(file).name;
            const up = await cloudinary.uploader.upload(path.join(dir, file), {
                folder: `animal-adoption/${kind}`,
                public_id: publicId,
                overwrite: true,
                resource_type: 'image'
            });
            // delivery URL with transformations: square crop around the animal (g_auto),
            // 600 px, best format and quality for the browser -> small and fast in Fiori
            const url = cloudinary.url(up.public_id, {
                secure: true,
                version: up.version,
                transformation: [{ width: 600, height: 600, crop: 'fill', gravity: 'auto' },
                                 { fetch_format: 'auto', quality: 'auto' }]
            });
            result[`${kind}/${publicId}`] = { url, publicId: up.public_id };
            console.log(`uploaded ${kind}/${file}`);
        }
    }
    fs.writeFileSync(OUT, JSON.stringify(result, null, 2) + '\n');
    console.log(`\n${Object.keys(result).length} pictures, URLs written to images/cloudinary-urls.json`);
}

main().catch(err => { console.error(err.message || err); process.exit(1); });
