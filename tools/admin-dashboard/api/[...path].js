// Vercel catch-all function: /api/* is handled by the Express app.
// The serverless runtime keeps the service-account credential server-side.

import app from '../server/app.js';

export default app;
