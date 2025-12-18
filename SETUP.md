# Agreement Gallery - Setup Guide

This guide explains how to set up and run the Agreement Gallery project locally.

## Prerequisites

- **Node.js** (v18 or higher recommended)
- **npm** (comes with Node.js)
- Access to the Supabase project credentials

## Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Start the development server
npm run dev
```

The application will be available at:
- **Local:** http://localhost:8080
- **Network:** http://[your-ip]:8080

## Environment Configuration

### Setting Up Environment Variables

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and fill in your Supabase credentials:
   ```env
   VITE_SUPABASE_URL=https://your-project-id.supabase.co
   VITE_SUPABASE_PUBLISHABLE_KEY=your_publishable_anon_key_here
   ```

### Where to Find Supabase Credentials

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Project Settings** > **API**
4. Copy the following values:
   - **Project URL** → `VITE_SUPABASE_URL`
   - **anon/public key** → `VITE_SUPABASE_PUBLISHABLE_KEY`

> **Note:** Never commit the `.env` file to git. It's already in `.gitignore`.

## Supabase Integration

### Project Configuration

The project connects to a Supabase backend with the following configuration:

- **Project ID:** `qwgicrdcoqdketqhxbys`
- **Client Location:** `src/integrations/supabase/client.ts`
- **Types Location:** `src/integrations/supabase/types.ts`

### Edge Functions

The following Supabase Edge Functions are configured (all require JWT verification):

| Function | Description |
|----------|-------------|
| `export-commission-data` | Exports commission data |
| `fee-runs-api` | Fee calculation runs API |
| `create-calculation-run` | Creates new calculation runs |

### Using the Supabase Client

Import the client in your components:

```typescript
import { supabase } from "@/integrations/supabase/client";

// Example: Fetch data
const { data, error } = await supabase
  .from('your_table')
  .select('*');

// Example: Authentication
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password'
});
```

### Authentication Features

The Supabase client is configured with:
- **Persistent sessions** - Sessions are stored in localStorage
- **Auto token refresh** - Tokens are automatically refreshed
- **Session URL detection** - Handles OAuth redirects automatically

## Available Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server on port 8080 |
| `npm run build` | Build for production |
| `npm run build:dev` | Build with development mode |
| `npm run preview` | Preview production build |
| `npm run lint` | Run ESLint |
| `npm run check:legacy` | Check for legacy code issues |
| `npm run validate:openapi` | Validate OpenAPI specification |
| `npm run ci:check` | Run all CI checks |
| `npm run import:all` | Run data import scripts |

## Tech Stack

- **Frontend Framework:** React 18 with TypeScript
- **Build Tool:** Vite 5
- **Styling:** Tailwind CSS with shadcn/ui components
- **State Management:** TanStack Query (React Query)
- **Backend:** Supabase (PostgreSQL, Auth, Edge Functions)
- **Forms:** React Hook Form with Zod validation

## Project Structure

```
src/
├── api/              # API clients and HTTP utilities
├── components/       # React components
│   ├── ui/          # shadcn/ui base components
│   └── ...          # Feature components
├── integrations/
│   └── supabase/    # Supabase client and types
├── pages/           # Page components
├── hooks/           # Custom React hooks
├── lib/             # Utility functions
└── App.tsx          # Main application component
```

## Troubleshooting

### Port Already in Use

If port 8080 is busy, you can modify `vite.config.ts`:

```typescript
server: {
  host: "::",
  port: 3000,  // Change to any available port
}
```

### Supabase Connection Issues

1. Verify your `.env` file has correct credentials
2. Check that your Supabase project is active
3. Ensure your IP is not blocked by Supabase

### Authentication Problems

If sessions expire unexpectedly:
1. Clear browser localStorage
2. Sign in again
3. Check the browser console for errors

## Additional Resources

- [Vite Documentation](https://vitejs.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [TanStack Query Documentation](https://tanstack.com/query)
- [shadcn/ui Components](https://ui.shadcn.com/)
