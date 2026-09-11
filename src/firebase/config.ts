import { initializeApp, type FirebaseApp } from 'firebase/app'
import { getFirestore, type Firestore } from 'firebase/firestore'
import { getAuth, type Auth } from 'firebase/auth'

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || 'AIzaSyC6674SxdJIGOlmyIdZZK0PTS3VK55Srks',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || 'kkk-oil-erp.firebaseapp.com',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || 'kkk-oil-erp',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || 'kkk-oil-erp.firebasestorage.app',
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || '959332742121',
  appId: import.meta.env.VITE_FIREBASE_APP_ID || '1:959332742121:web:87fe3420e13815b28b1178',
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
