# GitHub Pages Setup Instructions

Follow these exact steps to enable GitHub Pages for your repository.

## 🚀 Step-by-Step Setup

### Step 1: Enable GitHub Pages (2 minutes)

1. **Navigate to repository settings**
   - Go to: https://github.com/nellaivijay/iceberg-code-practice/settings/pages

2. **Configure deployment source**
   - Under "Build and deployment" section
   - Find "Source" dropdown menu
   - Select "GitHub Actions" 
   - GitHub will automatically detect your workflow file
   - Click "Save" button

3. **Verify configuration**
   - You should see a green checkmark indicating GitHub Pages is enabled
   - The workflow will run automatically on the next push to main branch

### Step 2: Trigger Initial Deployment (1 minute)

Since you just pushed your changes, the deployment should trigger automatically:

1. **Go to Actions tab**
   - Visit: https://github.com/nellaivijay/iceberg-code-practice/actions

2. **Monitor deployment**
   - Look for workflow named "Deploy to GitHub Pages"
   - Click on it to see the deployment progress
   - Wait for it to complete (usually 1-2 minutes)

3. **Check for success**
   - Look for green checkmark ✅
   - If failed, click on the red ❌ to see error logs

### Step 3: Access Your Site

Once deployment succeeds:

**Your site will be live at:**
```
https://nellaivijay.github.io/iceberg-code-practice
```

You can also find the URL in:
- Repository Settings → Pages
- The Actions workflow run summary

## 🔧 Manual Deployment (If Needed)

If automatic deployment doesn't trigger:

1. **Go to Actions tab**
   - https://github.com/nellaivijay/iceberg-code-practice/actions

2. **Select "Deploy to GitHub Pages" workflow**

3. **Click "Run workflow" button**

4. **Select branch**: main

5. **Click "Run workflow"**

## ✅ Verification Checklist

- [ ] GitHub Pages enabled in settings
- [ ] Source set to "GitHub Actions"
- [ ] Workflow runs successfully
- [ ] Site accessible at https://nellaivijay.github.io/iceberg-code-practice
- [ ] All documentation pages load correctly
- [ ] Navigation works
- [ ] Mobile responsive (test on your phone)

## 🎨 Customization Options

### Add Custom Domain (Optional)

If you want a custom domain like `iceberg-learning.com`:

1. **Purchase domain** from registrar (Namecheap, GoDaddy, etc.)

2. **Add domain in GitHub**
   - Go to Settings → Pages
   - Under "Custom domain", enter your domain
   - Click "Save"

3. **Configure DNS**
   - Add CNAME record pointing to `nellaivijay.github.io`
   - Follow GitHub's DNS configuration guide

4. **Enable HTTPS**
   - Wait 24-48 hours for DNS propagation
   - Enable "Enforce HTTPS" in GitHub Pages settings

### Change Site Appearance

Edit `docs/_config.yml` to customize:
- Site title and description
- Navigation menu
- Color scheme (if theme supports)
- Social media links

## 🆘 Troubleshooting

### Deployment Fails

**Check Actions logs:**
1. Go to Actions tab
2. Click on failed workflow
3. Review error messages
4. Common issues:
   - Invalid markdown syntax
   - Broken configuration in _config.yml
   - Missing required files

**Fix and retry:**
1. Fix the issue locally
2. Commit and push changes
3. Deployment will retry automatically

### Site Not Accessible

**Wait for DNS propagation:**
- It can take 5-10 minutes after initial deployment
- Clear your browser cache
- Try incognito/private browsing

**Check workflow success:**
- Verify deployment completed successfully
- Check Actions tab for errors

### Local Testing

To test changes locally before deploying:

1. **Install Jekyll**
   ```bash
   gem install jekyll
   ```

2. **Serve locally**
   ```bash
   cd docs
   jekyll serve
   ```

3. **Access local site**
   ```
   http://localhost:4000/iceberg-code-practice
   ```

## 📊 Analytics Setup (Optional)

### GitHub Pages Built-in Analytics

1. Go to Settings → Pages
2. View page views and visitors
3. No setup required

### Google Analytics (Optional)

1. **Create Google Analytics account**
   - Go to https://analytics.google.com/

2. **Get tracking ID**
   - Create a property for your site
   - Copy the Measurement ID (G-XXXXXXXXXX)

3. **Add to configuration**
   - Edit `docs/_config.yml`
   - Add: `google_analytics: G-XXXXXXXXXX`

4. **Deploy changes**
   ```bash
   git add docs/_config.yml
   git commit -m "Add Google Analytics"
   git push origin main
   ```

## 🎉 Success Indicators

When setup is complete, you should see:

✅ Green checkmark in Actions tab
✅ Site accessible at your GitHub Pages URL
✅ All documentation pages loading correctly
✅ Navigation working properly
✅ Mobile-responsive design
✅ Fast page load times

---

**🚀 Your GitHub Pages site will be live and automatically updated with every push to the main branch!**
