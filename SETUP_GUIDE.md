# Agreement Gallery - Setup Guide

This guide will help you set up and run the Agreement Gallery application locally.

## Prerequisites

- **Node.js** (v18 or higher) - [Download here](https://nodejs.org/)
- **npm** or **bun** (comes with Node.js)
- **Git** - [Download here](https://git-scm.com/)
- **Supabase Account** (optional, only if creating your own instance)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/gals-glitch/agreement-gallery.git
cd agreement-gallery
```

### 2. Install Dependencies

```bash
npm install
```

Or if using bun:

```bash
bun install
```

### 3. Configure Environment Variables

Create a `.env` file in the root directory:

```bash
# Create .env file
touch .env
```

Add the following configuration to `.env`:

```env
# Supabase Configuration
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_PUBLISHABLE_KEY=your_supabase_anon_key

# Example:
# VITE_SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
# VITE_SUPABASE_PUBLISHABLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

⚠️ **Important**: Never commit the `.env` file to git! It contains sensitive credentials.

### 4. Get Supabase Credentials

You have two options:

#### Option A: Request Access to Existing Project
Contact the project administrator (gals@buligocapital.com) to get:
- Supabase project URL
- Publishable (anon) key

#### Option B: Create Your Own Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create a new account/project
3. Run the database migrations (see below)
4. Get your project URL and anon key from Project Settings > API

### 5. Run Database Migrations (If creating your own instance)

If you created your own Supabase project, you need to set up the database schema:

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push
```

### 6. Start the Development Server

```bash
npm run dev
```

The application will be available at: **http://localhost:8080**

## Project Structure

```
agreement-gallery/
├── src/                      # Frontend React application
│   ├── components/          # Reusable UI components
│   ├── pages/              # Page components
│   ├── api/                # API client functions
│   └── integrations/       # Supabase integration
├── supabase/
│   ├── functions/          # Edge functions (API endpoints)
│   └── migrations/         # Database migrations
├── docs/                   # Documentation
├── tests/                  # PowerShell integration tests
└── .env                    # Environment variables (create this!)
```

## Features

Once set up, you'll have access to:

- **Investor Management** - Track investors with source attribution
- **Commission Agreements** - Manage distributor/referrer agreements
- **Connect to Distributor** - Link investors to parties
- **Manual Contributions** - Add individual transactions
- **VAT Management** - Configure and track VAT rates
- **Credits & Charges** - Commission calculation system
- **Agreement Approval Workflow** - Multi-step approval process

## Troubleshooting

### "Failed to fetch" or CORS errors
- Check that your `.env` file has the correct Supabase URL and key
- Verify you're using the **publishable key** (anon key), not the service role key

### "Authentication required" errors
- Make sure you've created a user account in your Supabase project
- Check Supabase > Authentication > Users to see registered users

### Missing dependencies errors
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

### Database errors
- Ensure all migrations have been applied
- Check Supabase dashboard > SQL Editor for any errors

## Default Users / Roles

If using the existing project instance:
- Default admin users are configured in the `user_roles` table
- Contact the admin for access credentials

If you created your own instance:
1. Sign up through the app at `/auth`
2. Manually grant admin role in Supabase dashboard:

```sql
-- Run in Supabase SQL Editor
INSERT INTO user_roles (user_id, role_key)
VALUES ('your-user-id', 'admin');
```

## Development Commands

```bash
# Start dev server
npm run dev

# Build for production
npm run build

# Run type checking
npm run type-check

# Run linting
npm run lint
```

## API Endpoints

The backend API is served via Supabase Edge Functions:

- Base URL: `{SUPABASE_URL}/functions/v1/api-v1`
- Endpoints: `/investors`, `/agreements`, `/contributions`, `/charges`, etc.
- Documentation: See `docs/QUICK-REFERENCE.md`

## Testing

PowerShell integration tests are available in the `tests/` directory:

```bash
# Example: Test charge workflow
pwsh ./tests/test_charge_workflow.ps1
```

## Production Deployment

See `DEPLOYMENT_GUIDE.md` for instructions on deploying to production.

## Need Help?

- **Documentation**: Check the `docs/` folder
- **Issues**: [GitHub Issues](https://github.com/gals-glitch/agreement-gallery/issues)
- **Contact**: gals@buligocapital.com

## Security Notes

🔒 **Important Security Practices:**

1. Never commit `.env` files
2. Rotate Supabase keys if accidentally exposed
3. Use Row Level Security (RLS) policies in production
4. Keep dependencies updated: `npm audit`

## License

[Add your license information here]

---

**Last Updated**: November 2025
**Version**: 1.0.0
