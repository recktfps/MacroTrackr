# Supabase Apple Authentication Setup

## Overview
This guide will help you configure Supabase to support Sign in with Apple for your MacroTrackr app.

## Prerequisites
- Apple Developer Account
- Supabase project (already set up)
- Xcode project with Sign in with Apple capability

## Step 1: Enable Sign in with Apple in Apple Developer Portal

1. **Go to Apple Developer Portal**
   - Visit [developer.apple.com](https://developer.apple.com)
   - Sign in with your Apple Developer account

2. **Configure App ID**
   - Go to "Certificates, Identifiers & Profiles"
   - Select "Identifiers" → "App IDs"
   - Find your app's App ID (bundle identifier)
   - Edit the App ID and enable "Sign In with Apple"
   - Save the configuration

3. **Create Service ID (for Supabase)**
   - Go to "Identifiers" → "Services IDs"
   - Click "+" to create a new Service ID
   - Description: "MacroTrackr Supabase Auth"
   - Identifier: Use your bundle identifier + `.auth` (e.g., `com.yourname.macrotrackr.auth`)
   - Enable "Sign In with Apple"
   - Configure domains and redirect URLs:
     - Primary App ID: Select your app's App ID
     - Domains: `adnjakimzfidaolaxmck.supabase.co`
     - Return URLs: `https://adnjakimzfidaolaxmck.supabase.co/auth/v1/callback`

4. **Create Private Key**
   - Go to "Keys" → "All"
   - Click "+" to create a new key
   - Key Name: "MacroTrackr Apple Sign In Key"
   - Enable "Sign In with Apple"
   - Configure for your App ID
   - Download the key file (.p8)
   - **Save the Key ID** (you'll need this for Supabase)

## Step 2: Configure Supabase

1. **Go to Supabase Dashboard**
   - Visit [supabase.com](https://supabase.com)
   - Sign in and select your project

2. **Enable Apple Provider**
   - Go to "Authentication" → "Providers"
   - Find "Apple" and toggle it ON

3. **Configure Apple Settings**
   - **Client ID**: Your Service ID from Step 1.3 (e.g., `com.yourname.macrotrackr.auth`)
   - **Client Secret**: Leave empty (Supabase will generate this)
   - **Redirect URL**: `https://adnjakimzfidaolaxmck.supabase.co/auth/v1/callback`

4. **Upload Apple Private Key**
   - In the Apple provider settings, you'll need to provide:
     - **Team ID**: Found in your Apple Developer account (top right corner)
     - **Key ID**: From Step 1.4 (the key you created)
     - **Private Key**: Content of the .p8 file you downloaded

## Step 3: Configure Xcode Project

1. **Add Sign in with Apple Capability**
   - Open your Xcode project
   - Select your app target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "Sign In with Apple"

2. **Update Bundle Identifier**
   - Make sure your bundle identifier matches the App ID you configured in Apple Developer Portal

## Step 4: Test the Integration

1. **Build and Run**
   - Build your app in Xcode
   - Run on a physical device (Sign in with Apple doesn't work in simulator)
   - Or use iOS Simulator with iOS 13+ and sign in with a real Apple ID

2. **Test Sign In Flow**
   - Tap "Sign in with Apple" button
   - Complete the Apple authentication flow
   - Verify user is created in Supabase Auth dashboard

## Troubleshooting

### Common Issues

1. **"Invalid client" error**
   - Verify Service ID matches exactly in Supabase
   - Check that Sign in with Apple is enabled for your App ID

2. **"Invalid redirect URI" error**
   - Ensure redirect URL in Supabase matches exactly: `https://adnjakimzfidaolaxmck.supabase.co/auth/v1/callback`

3. **"Invalid team ID" error**
   - Double-check Team ID in Supabase matches your Apple Developer account

4. **Sign in with Apple not showing**
   - Make sure you're testing on a physical device
   - Verify the capability is added to your Xcode project

### Debug Steps

1. **Check Supabase Logs**
   - Go to Supabase Dashboard → Logs
   - Look for authentication errors

2. **Verify Apple Configuration**
   - Double-check all IDs and URLs match exactly
   - Ensure the private key is uploaded correctly

3. **Test with Different Devices**
   - Try on multiple physical devices
   - Test with different Apple IDs

## Security Notes

- Never commit your Apple private key (.p8 file) to version control
- Keep your Team ID and Key ID secure
- Regularly rotate your Apple private keys
- Use environment variables for sensitive configuration in production

## Next Steps

Once Apple authentication is working:

1. Test the complete user flow
2. Verify user profiles are created correctly
3. Test sign out functionality
4. Consider implementing additional OAuth providers (Google, Facebook, etc.)

## Support

If you encounter issues:
1. Check the Supabase documentation: [supabase.com/docs/guides/auth/social-login/auth-apple](https://supabase.com/docs/guides/auth/social-login/auth-apple)
2. Review Apple's Sign in with Apple documentation
3. Check the Supabase community forums for similar issues
