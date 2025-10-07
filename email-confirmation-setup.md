# Email Confirmation Redirect Setup

## Overview
To fix the "site cannot be reached" issue when users click the email confirmation link, you need to configure Supabase to redirect to a proper confirmation page.

## Steps to Configure

### 1. Host the Confirmation Page
You have several options for hosting the `email-confirmation.html` file:

**Option A: GitHub Pages (Free)**
1. Create a new GitHub repository
2. Upload the `email-confirmation.html` file
3. Enable GitHub Pages in repository settings
4. Use the GitHub Pages URL (e.g., `https://yourusername.github.io/your-repo-name/email-confirmation.html`)

**Option B: Netlify (Free)**
1. Go to [netlify.com](https://netlify.com)
2. Drag and drop the `email-confirmation.html` file
3. Get the provided URL (e.g., `https://your-site-name.netlify.app/email-confirmation.html`)

**Option C: Vercel (Free)**
1. Go to [vercel.com](https://vercel.com)
2. Upload the file and get the URL

### 2. Configure Supabase Settings
1. Go to your Supabase project dashboard
2. Navigate to **Authentication** > **URL Configuration**
3. Set the **Site URL** to your hosted confirmation page URL
4. Set the **Redirect URLs** to include your confirmation page URL
5. Save the changes

### 3. Alternative: Use a Custom Domain
If you have a custom domain for your app, you can:
1. Host the confirmation page on your domain
2. Set up the redirect URL to something like `https://yourdomain.com/email-confirmed`

## What the Confirmation Page Does

The `email-confirmation.html` page:
- Shows a success message confirming email verification
- Provides a button to open the MacroTrackr app
- Automatically attempts to redirect to the app after 10 seconds
- Has a fallback to the App Store if the app isn't installed
- Is mobile-responsive and visually appealing

## Testing

After configuration:
1. Create a new test account
2. Check your email for the confirmation link
3. Click the link to verify it redirects to your confirmation page
4. Test the "Open App" button functionality

## Notes

- The confirmation page includes deep linking to try to open the app directly
- If the app isn't installed, it provides guidance to download from the App Store
- The page is designed to match MacroTrackr's branding and provide a smooth user experience
