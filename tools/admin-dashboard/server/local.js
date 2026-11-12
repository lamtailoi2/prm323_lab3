// Local development server: the same Express app as Vercel, plus Vite in
// middleware mode so React and the API share http://127.0.0.1:4317.

// `npm run dev` must not inherit a production NODE_ENV (some shells set it),
// or Vite starts without React Fast Refresh.
process.env.NODE_ENV = 'development';

const { createServer: createViteServer, loadEnv } = await import('vite');

// Vite reads .env files for `import.meta.env`, but the Express app reads
// `process.env`. Copy the same values (without overriding real shell vars) so
// ADMIN_EMAILS, GA4_PROPERTY_ID and the credential overrides work locally.
const fileEnv = loadEnv('development', process.cwd(), '');
for (const [key, value] of Object.entries(fileEnv)) {
  if (process.env[key] === undefined) process.env[key] = value;
}

const { default: app } = await import('./app.js');

const PORT = Number(process.env.PORT || 4317);
const HOST = process.env.HOST || '127.0.0.1';

const vite = await createViteServer({
  server: { middlewareMode: true },
  appType: 'spa',
});

app.use(vite.middlewares);

app.listen(PORT, HOST, () => {
  console.log(`Internly admin dashboard → http://${HOST}:${PORT}`);
  console.log(
    process.env.ADMIN_EMAILS
      ? `Admin allowlist: ${process.env.ADMIN_EMAILS}`
      : 'ADMIN_EMAILS is empty; every request will be rejected.',
  );
});
