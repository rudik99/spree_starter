# Serving Images Directly from Cloudflare R2

This guide explains how to serve images directly from R2 instead of proxying through your Rails application.

## What Changed

### 1. Active Storage Configuration (`config/initializers/active_storage.rb`)

Changed from `:rails_storage_proxy` to `:rails_storage_redirect`:

```ruby
# Before (slow - proxies through Rails):
Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_proxy

# After (fast - redirects to R2):
Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_redirect
```

This change means:
- **Before**: User → Rails → R2 → Rails → User (double hop, uses Railway bandwidth)
- **After**: User → Rails (redirect) → R2 → User (single hop, minimal Railway usage)

### 2. Storage Configuration (`config/storage.yml`)

Set `public: true` for R2 bucket configuration to allow public access.

## Setup Options

### Option A: Signed URLs with Redirect (Current - No Additional Setup Required)

**What happens:**
1. User requests image
2. Rails generates a signed R2 URL and redirects
3. User's browser loads directly from R2

**Pros:**
- No additional configuration needed
- Works immediately after deploy
- Secure - URLs expire after a period

**Cons:**
- Still requires one redirect through Rails
- Slightly slower than direct URLs

**Status:** ✅ Already configured and working

### Option B: Public URLs via Custom Domain (Future Enhancement)

**What happens:**
1. User requests image
2. Rails returns direct R2 public URL
3. User's browser loads directly from R2 (no redirect)

**Pros:**
- Fastest possible - zero Rails involvement
- Better caching (CDN can cache the URL itself)
- Lower Railway resource usage

**Cons:**
- Requires setting up R2 public domain
- Files are publicly accessible (usually fine for product images)

## Setting Up Option B (Public URLs) - Advanced Configuration

**Note:** This feature requires additional Rails configuration beyond storage.yml. The steps below outline the R2 setup, but additional application-level changes are needed to utilize custom public domains.

### Step 1: Enable R2 Public Access

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com) → R2
2. Select your bucket (e.g., `spree-production`)
3. Click **Settings** tab
4. Scroll to **Public Access** section
5. Click **Allow Access** (or **Connect Domain** if already enabled)

### Step 2: Set Up Public Domain

You have two options:

#### Option 2A: Use Cloudflare's R2.dev Domain (Easiest)

1. In the Public Access section, click **Allow Access**
2. Cloudflare will provide a URL like: `https://pub-xxxxxxxxxxxxx.r2.dev`
3. Copy this URL

#### Option 2B: Use Custom Domain (Best for Production)

1. In Public Access, click **Connect Domain**
2. Enter a subdomain from your Cloudflare-managed domain:
   - Example: `cdn.yourdomain.com` or `assets.yourdomain.com`
3. Cloudflare will automatically configure DNS
4. Your public URL will be: `https://cdn.yourdomain.com`

### Step 3: Configure Rails Asset Host (Future Enhancement)

To use custom public domains, you would need to configure `config.asset_host` or implement a custom Active Storage service. This is not currently implemented in the default configuration.

### Step 4: Update CORS Configuration (if not already done)

Ensure your R2 bucket has CORS configured (see `R2_CORS_SETUP.md`). Add your public domain to AllowedOrigins:

```json
{
  "AllowedOrigins": [
    "http://localhost:3000",
    "https://yourdomain.com",
    "https://cdn.yourdomain.com"
  ],
  "AllowedMethods": ["GET", "HEAD"],
  "AllowedHeaders": ["*"],
  "MaxAgeSeconds": 3000
}
```

### Step 5: Deploy and Test

1. Push changes to your repository
2. Railway will redeploy with new environment variable
3. Test by viewing a product image
4. Inspect the image URL in browser DevTools - it should point directly to R2

## Verification

### Check if redirect is working (Option A):

```bash
# In your Rails console:
rails c

# Get an image attachment:
image = Spree::Image.first.attachment
image.url
# Should return: /rails/active_storage/blobs/redirect/...

# This will redirect to R2
```

### Check if public URLs are working (Option B):

```bash
# In your Rails console:
rails c

image = Spree::Image.first.attachment
image.url
# Should return: https://pub-xxx.r2.dev/... or https://cdn.yourdomain.com/...
```

### Browser DevTools Check:

1. Open your storefront
2. Right-click on a product image → Inspect
3. Look at the `src` attribute
4. For Option A: Should see `/rails/active_storage/blobs/redirect/...`
5. For Option B: Should see `https://pub-xxx.r2.dev/...` or `https://cdn.yourdomain.com/...`

## Performance Impact

### Before (Proxy Mode):
- **Latency**: ~200-500ms (Rails processing + R2 fetch)
- **Railway Bandwidth**: Used for every image
- **Rails CPU**: Used for every image request

### After (Redirect Mode - Option A):
- **Latency**: ~100-200ms (one redirect + R2 fetch)
- **Railway Bandwidth**: Minimal (just redirect)
- **Rails CPU**: Minimal (just redirect)

### After (Public URLs - Option B):
- **Latency**: ~50-100ms (direct R2 fetch)
- **Railway Bandwidth**: Zero for images
- **Rails CPU**: Zero for images
- **CDN Caching**: Full caching possible

## Troubleshooting

### Images not loading after changing to redirect:

1. Check Rails logs for errors
2. Verify CLOUDFLARE_ENDPOINT is correct
3. Verify R2 credentials are valid
4. Check R2 CORS configuration

### Images not loading with public URLs:

1. Verify `CLOUDFLARE_PUBLIC_URL` is set correctly
2. Check R2 bucket has public access enabled
3. Verify CORS includes your public domain
4. Test the URL directly in browser

### Images still proxying through Rails:

1. Ensure you've restarted Rails after configuration change
2. Check `config/initializers/active_storage.rb` has `:rails_storage_redirect`
3. Clear browser cache and hard reload (Cmd+Shift+R / Ctrl+Shift+F5)

## Security Considerations

### Option A (Signed URLs):
- ✅ URLs expire after a time period
- ✅ Cannot be guessed or enumerated
- ✅ Can be revoked by changing R2 credentials

### Option B (Public URLs):
- ⚠️ Anyone with URL can access the image
- ⚠️ URLs are permanent (until file deleted)
- ✅ Acceptable for public product images
- ❌ Not recommended for private/sensitive files

## Recommendations

1. **For product images**: Use **Option B** (public URLs) for best performance
2. **For user uploads/documents**: Use **Option A** (signed URLs) for security
3. **For high-traffic sites**: Use **Option B** with custom domain + Cloudflare CDN

## Additional Optimization (Optional)

### Set up Cloudflare Caching

If using a custom domain (Option 2B), you can enable aggressive caching:

1. Go to Cloudflare Dashboard → Your Domain → Rules → Page Rules
2. Create a rule for `cdn.yourdomain.com/*`:
   - Cache Level: Cache Everything
   - Edge Cache TTL: 1 month
   - Browser Cache TTL: 1 month

This will cache images at Cloudflare's edge for ultra-fast delivery worldwide.
