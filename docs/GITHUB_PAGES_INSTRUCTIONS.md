# GitHub Pages Setup Instructions

This guide will help you set up GitHub Pages for your Apache Iceberg Code Practice repository to deploy the documentation automatically.

## 🎯 What You'll Get

After setup, your documentation will be available at:
```
https://nellaivijay.github.io/iceberg-code-practice
```

## 📋 Prerequisites

- GitHub repository: `nellaivijay/iceberg-code-practice`
- GitHub Actions workflow already created (`.github/workflows/github-pages.yml`)
- Documentation files in `docs/` directory
- Admin access to repository settings

## 🚀 Step-by-Step Setup

### Step 1: Enable GitHub Pages

1. **Go to your repository on GitHub**
   ```
   https://github.com/nellaivijay/iceberg-code-practice
   ```

2. **Navigate to Settings**
   - Click the "Settings" tab at the top of the repository
   - Scroll down to the "Code and automation" section
   - Click on "Pages"

3. **Configure GitHub Pages**
   - Under "Build and deployment", click "Source"
   - Select "GitHub Actions" from the dropdown menu
   - GitHub will detect the workflow file automatically
   - Click "Save"

4. **Verify Configuration**
   - You should see a message indicating GitHub Pages is enabled
   - The workflow will run automatically on the next push to main branch

### Step 2: Trigger Initial Deployment

1. **Push changes to main branch**
   ```bash
   git add .
   git commit -m "Enable GitHub Pages deployment"
   git push origin main
   ```

2. **Monitor Deployment**
   - Go to the "Actions" tab in your repository
   - You should see a workflow run named "Deploy to GitHub Pages"
   - Click on it to monitor the deployment progress
   - Wait for the workflow to complete (usually 1-2 minutes)

3. **Access Your Site**
   - Once deployed, your site will be available at:
     ```
     https://nellaivijay.github.io/iceberg-code-practice
     ```
   - You can also find the URL in:
     - Repository Settings → Pages
     - The Actions workflow run summary

### Step 3: Configure Custom Domain (Optional)

If you want to use a custom domain:

1. **Buy a Domain**
   - Purchase a domain from a registrar (Namecheap, GoDaddy, etc.)

2. **Add Domain in GitHub**
   - Go to Settings → Pages
   - Under "Custom domain", enter your domain
   - Click "Save"

3. **Configure DNS**
   - Add a CNAME record pointing to:
     ```
     nellaivijay.github.io
     ```
   - Or configure with your DNS provider following GitHub's instructions

4. **Enable HTTPS**
   - Wait for DNS to propagate (can take 24-48 hours)
   - Enable "Enforce HTTPS" in GitHub Pages settings

## 🔧 Workflow Details

The GitHub Actions workflow (`.github/workflows/github-pages.yml`) automatically:

- Triggers on push to `main` branch
- Builds your documentation from the `docs/` directory
- Deploys to GitHub Pages
- Provides deployment URL in workflow summary

### Manual Deployment

To trigger deployment manually:

1. Go to the "Actions" tab
2. Select "Deploy to GitHub Pages" workflow
3. Click "Run workflow" button
4. Select branch (usually `main`)
5. Click "Run workflow"

## 📁 What Gets Deployed

The workflow deploys everything in the `docs/` directory:

- Main documentation files (ARCHITECTURE.md, SETUP_GUIDE.md, etc.)
- Conceptual guides (docs/conceptual-guides/)
- Lab documentation references
- Static assets (index.html, robots.txt, sitemap.xml)
- Jekyll configuration (_config.yml)

## 🎨 Customization

### Update Site Configuration

Edit `docs/_config.yml` to customize:

```yaml
title: Apache Iceberg Code Practice
description: Free Hands-on Labs for Data Lakehouse Learning
url: "https://nellaivijay.github.io/iceberg-code-practice"
baseurl: "/iceberg-code-practice"
```

### Change Navigation

Edit the navigation section in `_config.yml`:

```yaml
nav:
  - title: Home
    url: /
  - title: Labs
    url: /labs/
  - title: Conceptual Guides
    url: /conceptual-guides/
```

### Add Custom Pages

1. Create markdown file in `docs/`
2. Add to navigation in `_config.yml`
3. Push to trigger deployment

## 🔍 Troubleshooting

### Deployment Fails

1. **Check Actions Logs**
   - Go to Actions tab
   - Click on failed workflow run
   - Review error messages

2. **Common Issues**
   - Invalid markdown syntax
   - Broken links in documentation
   - Missing files referenced in _config.yml
   - Jekyll configuration errors

3. **Fix and Retry**
   - Fix the issue locally
   - Commit and push changes
   - Deployment will retry automatically

### Site Not Accessible

1. **Check DNS Propagation**
   - Wait 5-10 minutes after initial deployment
   - Clear browser cache
   - Try incognito/private browsing

2. **Verify Workflow Success**
   - Check Actions tab for successful deployment
   - Verify workflow completed without errors

3. **Check GitHub Pages Status**
   - Visit https://www.githubstatus.com/
   - Check if GitHub Pages is experiencing issues

### Local Testing

To test locally before deploying:

1. **Install Jekyll**
   ```bash
   gem install jekyll
   ```

2. **Serve Locally**
   ```bash
   cd docs
   jekyll serve
   ```

3. **Access Local Site**
   ```
   http://localhost:4000/iceberg-code-practice
   ```

## 📊 Analytics

### Built-in Analytics

GitHub Pages provides basic analytics:
- Go to Settings → Pages
- View page views and visitors

### Google Analytics (Optional)

1. **Get Tracking ID**
   - Go to Google Analytics
   - Create a property for your site
   - Copy the tracking ID (UA-XXXXXXXXX-X)

2. **Add to Configuration**
   - Edit `docs/_config.yml`
   - Add your tracking ID:
     ```yaml
     google_analytics: UA-XXXXXXXXX-X
     ```

3. **Deploy Changes**
   - Commit and push to trigger deployment

## 🔒 Security

### Access Control

GitHub Pages sites are public by default. For private documentation:

1. **Use GitHub Authentication**
   - Pages are still accessible, but you can control repository access
   - Restrict repository access to authorized users

2. **Alternative: Private Documentation**
   - Consider using GitHub Codespaces
   - Or self-hosted documentation solutions

## 📈 SEO Optimization

Your site includes built-in SEO:

- **Sitemap**: Automatically generated at `/sitemap.xml`
- **Robots.txt**: Configured for search engines
- **Meta Tags**: Included in HTML files
- **Social Cards**: Twitter and Open Graph tags

### Improve SEO

1. **Add Keywords**
   - Update meta descriptions in `docs/index.html`
   - Add relevant keywords to content

2. **Internal Linking**
   - Link between documentation pages
   - Create clear navigation structure

3. **External Links**
   - Link to authoritative sources
   - Get backlinks from relevant sites

## 🔄 Maintenance

### Regular Updates

- **Monthly**: Review and update documentation
- **After Lab Updates**: Update related docs
- **Community Feedback**: Incorporate suggestions
- **Technology Changes**: Update for new versions

### Monitor Performance

- Check GitHub Pages analytics
- Monitor deployment success rate
- Review user feedback
- Track broken links

## 🎯 Best Practices

1. **Test Locally First**
   - Use Jekyll serve to test changes
   - Verify links and formatting
   - Check mobile responsiveness

2. **Commit Frequently**
   - Small, focused commits
   - Clear commit messages
   - Automatic deployment on each push

3. **Monitor Deployments**
   - Check Actions tab regularly
   - Fix deployment failures quickly
   - Keep deployment time short

4. **Backup Content**
   - Documentation is in git repository
   - Automatic version control
   - Easy rollback if needed

## 🆘 Getting Help

### GitHub Pages Documentation
- [GitHub Pages Guide](https://docs.github.com/en/pages)
- [Jekyll on GitHub Pages](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll)

### Common Issues
- Check [GitHub Status](https://www.githubstatus.com/)
- Review [Actions documentation](https://docs.github.com/en/actions)
- Search [GitHub Community Forums](https://github.community/)

### Project-Specific Help
- Open an issue in this repository
- Check existing documentation
- Review troubleshooting guides

## 📝 Checklist

Use this checklist to verify your setup:

- [ ] GitHub Pages enabled in repository settings
- [ ] Source set to "GitHub Actions"
- [ ] Workflow file exists (`.github/workflows/github-pages.yml`)
- [ ] First deployment successful
- [ ] Site accessible at `https://nellaivijay.github.io/iceberg-code-practice`
- [ ] Navigation works correctly
- [ ] Links are functional
- [ ] Mobile responsive (test on phone)
- [ ] SEO meta tags configured
- [ ] Analytics set up (optional)

---

**🎉 Your GitHub Pages site is now ready!**

Your documentation will be automatically deployed whenever you push changes to the main branch.
