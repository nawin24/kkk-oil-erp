import { initializeApp, type FirebaseApp } from 'firebase/app'
import { getFirestore, type Firestore } from 'firebase/firestore'
import { getAuth, type Auth } from 'firebase/auth'

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
}

// Two run modes:
//  - "live" : real Firebase project configured in .env → Firestore + Auth used.
//  - "demo" : no credentials → app runs on local seed data + localStorage.
export const isFirebaseConfigured = Boolean(
  firebaseConfig.apiKey && firebaseConfig.projectId,
)

let app: FirebaseApp | null = null
let db: Firestore | null = null
let auth: Auth | null = null

if (isFirebaseConfigured) {
  app = initializeApp(firebaseConfig)
  db = getFirestore(app)
  auth = getAuth(app)
}

export { app, db, auth }
