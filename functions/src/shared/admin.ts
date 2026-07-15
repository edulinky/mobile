import {initializeApp, getApps, App} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getAuth} from "firebase-admin/auth";
import {getStorage} from "firebase-admin/storage";
import {getMessaging} from "firebase-admin/messaging";

// Initialize the Admin SDK exactly once. Multiple imports across function files
// share this single app instance (cold starts re-run module init, so guard it).
const app: App = getApps().length > 0 ? getApps()[0] : initializeApp();

export const db = getFirestore(app);
export const auth = getAuth(app);
export const storage = getStorage(app);
export const messaging = getMessaging(app);
