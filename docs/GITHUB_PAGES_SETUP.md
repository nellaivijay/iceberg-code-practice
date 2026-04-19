# GitHub Pages Setup Guide

This repository is configured to automatically deploy documentation to GitHub Pages.

## 🚀 Automatic Deployment

Documentation is automatically deployed to GitHub Pages when you push to the `main` branch.

### Access Your Site

Once deployed, your documentation will be available at:
```
https://nellaivijay.github.io/iceberg-code-practice
```

## 📁 What Gets Deployed

The `docs/` directory is deployed to GitHub Pages, including:
- Main documentation files (ARCHITECTURE.md, SETUP_GUIDE.md, etc.)
- Conceptual guides (docs/conceptual-guides/)
- Lab guides (referenced from main labs directory)
- Static assets and configuration

## 🔧 Manual Deployment

To trigger a manual deployment:

1. Go to your repository on GitHub
2. Click on the "Actions" tab
3. Select "Deploy to GitHub Pages" workflow
4. Click "Run workflow" button

## 🎨 Customization

### Site Configuration

Edit `docs/_config.yml` to customize:
- Site title and description
- Navigation menu
- Theme settings
- SEO metadata

### Theme

The site uses the `jekyll-theme-minimal` theme. You can change this in `_config.yml`:

```yaml
theme: jekyll-theme-cayman  # or other Jekyll themes
```

### Custom Styling

Add custom CSS by creating `docs/assets/css/style.css` and referencing it in your layouts.

## 📝 Adding Content

### New Documentation Pages

1. Create your markdown file in `docs/`
2. Add it to the navigation in `_config.yml`
3. Push to `main` branch - it will be automatically deployed

### New Conceptual Guides

1. Create markdown file in `docs/conceptual-guides/`
2. Follow the naming convention: `XX-topic-name.md`
3. Update the navigation in `_config.yml`

## 🔍 SEO and Analytics

### Google Analytics

Add your Google Analytics tracking ID in `_config.yml`:

```yaml
google_analytics: UA-XXXXXXXXX-X
```

### Search Engine Optimization

The site includes:
- Automatic sitemap generation
- SEO tags via jekyll-seo-tag
- Meta tags from _config.yml

## 🐛 Troubleshooting

### Deployment Failures

If deployment fails:

1. Check the Actions tab for error logs
2. Ensure all markdown files are properly formatted
3. Verify that _config.yml has no syntax errors
4. Check that the docs/ directory exists

### Local Testing

To test locally before pushing:

1. Install Jekyll:
   ```bash
   gem install jekyll
   ```

2. Build and serve locally:
   ```bash
   cd docs
   jekyll serve
   ```

3. Open browser to `http://localhost:4000/iceberg-code-practice`

### Custom Domain

To use a custom domain:

1. Go to repository Settings → Pages
2. Set your custom domain
3. Update DNS settings
4. Update `url` in `_config.yml`

## 📊 Analytics

Monitor your site traffic using:
- GitHub Pages built-in analytics (Settings → Pages)
- Google Analytics (if configured)
- Other third-party analytics tools

## 🔗 Related Resources

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [Jekyll SEO Tag Plugin](https://github.com/jekyll/jekyll-seo-tag)
- [Minimal Theme Documentation](https://github.com/pages-themes/minimal)

## 🆘 Support

For issues with GitHub Pages deployment:
- Check GitHub Actions logs
- Review GitHub Pages documentation
- Open an issue in this repository
