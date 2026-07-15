// Shared Admin SDK init for the maintenance scripts.
//
// These run with FULL admin privileges: they bypass every Firestore rule and can
// delete anything. That is the point — and the reason they live outside the app
// and need an explicit service-account key rather than picking up ambient
// credentials.
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const KEY_PATH = path.join(__dirname, "serviceAccountKey.json");

if (!fs.existsSync(KEY_PATH)) {
  console.error(`
✗ Missing ${KEY_PATH}

  Firebase console → Project settings → Service accounts
  → "Generate new private key" → save the file as:

      scripts/serviceAccountKey.json

  (It is gitignored. Treat it like a root password: it can read and delete
  anything in the project.)
`);
  process.exit(1);
}

const serviceAccount = require(KEY_PATH);

if (serviceAccount.project_id !== "edulinky-86123") {
  console.error(
    `✗ Key is for project "${serviceAccount.project_id}", expected "edulinky-86123". Refusing to run.`
  );
  process.exit(1);
}

admin.initializeApp({credential: admin.credential.cert(serviceAccount)});

module.exports = {
  admin,
  db: admin.firestore(),
  auth: admin.auth(),
  projectId: serviceAccount.project_id,
};
