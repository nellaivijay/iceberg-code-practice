# Manual Setup Guide for Wiki and GitHub Pages

Since GitHub Wiki pages and GitHub Pages settings require manual action in the GitHub web interface (for security reasons), this guide provides exact step-by-step instructions.

## 🎯 What I Cannot Do Automatically

**I cannot directly:**
- Create GitHub Wiki pages (requires web interface)
- Enable GitHub Pages (requires repository settings)
- Modify GitHub repository settings
- Access GitHub authentication on your behalf

**What I have prepared for you:**
- ✅ All wiki content ready to copy-paste
- ✅ Enhanced helper script to guide you through the process
- ✅ SEO-optimized configuration
- ✅ GitHub Actions workflow ready to deploy

## 🚀 Part 1: Enable GitHub Pages (2 minutes)

### Step-by-Step Instructions

1. **Open GitHub repository settings**
   - Go to: https://github.com/nellaivijay/iceberg-code-practice/settings/pages
   - You'll see the "Pages" settings page

2. **Configure deployment source**
   - Find the "Build and deployment" section
   - Look for "Source" dropdown menu
   - Click on the dropdown
   - Select "GitHub Actions" from the options
   - GitHub will automatically detect your workflow file

3. **Save the configuration**
   - Click the "Save" button
   - Wait for the page to reload
   - You should see a green checkmark indicating GitHub Pages is enabled

4. **Automatic deployment will begin**
   - Go to the "Actions" tab: https://github.com/nellaivijay/iceberg-code-practice/actions
   - You'll see a workflow run named "Deploy to GitHub Pages"
   - Wait for it to complete (usually 1-2 minutes)
   - Look for a green checkmark ✅

5. **Access your site**
   - Once deployment succeeds, your site will be live at:
     ```
     https://nellaivijay.github.io/iceberg-code-practice
     ```
   - Open this URL in your browser to verify

### Troubleshooting GitHub Pages

**If deployment fails:**
- Click on the failed workflow in Actions tab
- Read the error message
- Common issues: invalid Jekyll configuration, broken links
- Fix the issue locally, commit, and push again

**If site not accessible:**
- Wait 5-10 minutes for DNS propagation
- Clear your browser cache
- Try in incognito/private browsing mode

## 📚 Part 2: Create GitHub Wiki Pages (15-20 minutes)

### Option A: Use Enhanced Helper Script (Recommended)

1. **Run the enhanced setup script**
   ```bash
   ./scripts/enhanced_wiki_setup.sh
   ```

2. **Follow the guided process**
   - The script will show you exactly what content to copy
   - It will guide you through each page one by one
   - Press Enter after completing each page

### Option B: Manual Step-by-Step Process

#### Page 1: Home

1. **Go to your wiki**
   - Open: https://github.com/nellaivijay/iceberg-code-practice/wiki

2. **Create Home page**
   - Click "Add Page" button
   - Enter title exactly: `Home`
   - Open the file `wiki/Home.md` in a text editor
   - Copy all the content
   - Paste into the wiki editor
   - Click "Save"

#### Page 2: Getting-Started

1. **Create Getting-Started page**
   - Click "Add Page" button
   - Enter title exactly: `Getting-Started`
   - Open the file `wiki/Getting-Started.md` in a text editor
   - Copy all the content
   - Paste into the wiki editor
   - Click "Save"

#### Page 3: Iceberg-Fundamentals

1. **Create Iceberg-Fundamentals page**
   - Click "Add Page" button
   - Enter title exactly: `Iceberg-Fundamentals`
   - Open the file `wiki/Iceberg-Fundamentals.md` in a text editor
   - Copy all the content
   - Paste into the wiki editor
   - Click "Save"

#### Page 4: Lab-Guides

1. **Create Lab-Guides page**
   - Click "Add Page" button
   - Enter title exactly: `Lab-Guides`
   - Open the file `wiki/Lab-Guides.md` in a text editor
   - Copy all the content
   - Paste into the wiki editor
   - Click "Save"

#### Page 5: Learning-Path

1. **Create Learning-Path page**
   - Click "Add Page" button
   - Enter title exactly: `Learning-Path`
   - Open the file `wiki/Learning-Path.md` in a text editor
   - Copy all the content
   - Paste into the wiki editor
   - Click "Save"

#### Page 6: Best-Practices

1. **Create Best-Practices page**
   - Click "Add Page" button
   - Enter title exactly: `Best-Practices`
   - Open the file `wiki/Best-Practices.md` in a text editor
   - Copy all the content
   - Paste into the wiki editor
   - Click "Save"

#### Page 7: Troubleshooting

1. **Create Troubleshooting page**
   - Click "Add Page" button
   - Enter title exactly: `Troubleshooting`
   - Open the file `wiki/Troubleshooting.md` in a text editor
   - Copy all the content
   - Paste into the wiki editor
   - Click "Save"

### Organize Wiki Sidebar (Optional)

1. **Click "Edit sidebar"** (if available in your wiki)
2. **Add pages in this exact order:**
   ```
   Home
   Getting-Started
   Iceberg-Fundamentals
   Lab-Guides
   Learning-Path
   Best-Practices
   Troubleshooting
   ```
3. **Click "Save"**

## ✅ Verification Checklist

### GitHub Pages Verification

- [ ] GitHub Pages enabled in repository settings
- [ ] Source set to "GitHub Actions"
- [ ] Deployment workflow runs successfully
- [ ] Site accessible at: https://nellaivijay.github.io/iceberg-code-practice
- [ ] All documentation pages load correctly
- [ ] Navigation works properly
- [ ] Site is mobile-responsive

### Wiki Verification

- [ ] All 7 wiki pages created
- [ ] Page titles match exactly (Home, Getting-Started, etc.)
- [ ] Content properly formatted
- [ ] All links work correctly
- [ ] Sidebar organized (if available)
- [ ] Wiki accessible at: https://github.com/nellaivijay/iceberg-code-practice/wiki

## 🎯 Quick Copy-Paste Reference

### Wiki File Locations

All wiki files are in the `wiki/` directory:
- `wiki/Home.md`
- `wiki/Getting-Started.md`
- `wiki/Iceberg-Fundamentals.md`
- `wiki/Lab-Guides.md`
- `wiki/Learning-Path.md`
- `wiki/Best-Practices.md`
- `wiki/Troubleshooting.md`

### GitHub Pages Settings URL

```
https://github.com/nellaivijay/iceberg-code-practice/settings/pages
```

### Wiki URL

```
https://github.com/nellaivijay/iceberg-code-practice/wiki
```

## 🆘 Common Issues and Solutions

### GitHub Pages Issues

**"GitHub Pages not enabled"**
- Solution: Follow the exact steps in Part 1 above
- Make sure you're in repository Settings → Pages

**"Deployment failed"**
- Solution: Check Actions tab for error logs
- Common issues: Jekyll configuration errors, broken links
- Fix locally, commit, and push again

**"Site not accessible"**
- Solution: Wait 5-10 minutes for DNS propagation
- Clear browser cache
- Try in incognito mode

### Wiki Issues

**"Wiki not enabled"**
- Solution: Go to Settings → Features
- Ensure "Wiki" checkbox is checked
- Save settings

**"Content not formatting"**
- Solution: Ensure markdown syntax is correct
- Check for proper heading levels (#, ##, ###)
- Verify code blocks are properly formatted with ``` ```

**"Links not working"**
- Solution: Verify URL formats are correct
- Check for typos in repository URLs
- Test links in incognito mode

## 🎉 Success Indicators

When both setups are complete, you should have:

### GitHub Pages
- ✅ Live site at: https://nellaivijay.github.io/iceberg-code-practice
- ✅ All documentation accessible
- ✅ Mobile-responsive design
- ✅ SEO-optimized for search engines

### GitHub Wiki
- ✅ 7 comprehensive educational pages
- ✅ Properly formatted content
- ✅ Working internal and external links
- ✅ Organized navigation

## 📞 Need Help?

If you encounter issues:

1. **Check the detailed guides:**
   - GitHub Pages: `docs/GITHUB_PAGES_QUICK_SETUP.md`
   - Wiki Setup: `docs/WIKI_QUICK_SETUP.md`
   - Complete Deployment: `docs/DEPLOYMENT_GUIDE.md`

2. **Review GitHub documentation:**
   - GitHub Pages: https://docs.github.com/en/pages
   - GitHub Wiki: https://docs.github.com/en/wiki

3. **Open an issue:**
   - https://github.com/nellaivijay/iceberg-code-practice/issues

---

**🚀 Follow these exact steps and your educational platform will be fully operational!**
