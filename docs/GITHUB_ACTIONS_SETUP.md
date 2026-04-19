# GitHub Actions Setup Guide

This guide helps you enable and configure GitHub Actions for your Apache Iceberg Code Practice repository.

## 🎯 Current Status

Your repository already has GitHub Actions workflows configured:
- ✅ **CI/CD Pipeline** (`.github/workflows/ci.yml`) - Automated testing and validation
- ✅ **GitHub Pages Deployment** (`.github/workflows/github-pages.yml`) - Documentation deployment

These workflows will automatically trigger on pushes to the `main` branch.

## 🚀 Step-by-Step Setup

### Step 1: Enable GitHub Actions (2 minutes)

1. **Go to repository settings**
   - Visit: https://github.com/nellaivijay/iceberg-code-practice/settings/actions

2. **Verify Actions is enabled**
   - GitHub Actions is typically enabled by default
   - If you see "Enable GitHub Actions" button, click it
   - If you see Actions interface, it's already enabled

3. **Configure Actions permissions** (if needed)
   - In Actions settings, ensure "Allow GitHub Actions to create and approve pull requests" is enabled
   - This allows workflows to run automatically

### Step 2: Configure Workflow Permissions (1 minute)

1. **Go to Actions → General**
   - Visit: https://github.com/nellaivijay/iceberg-code-practice/settings/actions

2. **Configure workflow permissions**
   - Under "Workflow permissions", select:
     - ✅ "Read and write permissions"
     - This allows workflows to deploy to GitHub Pages and make necessary changes

3. **Save settings**

### Step 3: Enable GitHub Pages for Actions (2 minutes)

This is required for the GitHub Pages deployment workflow:

1. **Go to Pages settings**
   - Visit: https://github.com/nellaivijay/iceberg-code-practice/settings/pages

2. **Configure deployment source**
   - Under "Build and deployment" → "Source"
   - Select "GitHub Actions"
   - GitHub will detect your workflow automatically
   - Click "Save"

### Step 4: Trigger Workflows (Automatic)

Since you just pushed changes, workflows should trigger automatically:

1. **Go to Actions tab**
   - Visit: https://github.com/nellaivijay/iceberg-code-practice/actions

2. **Monitor workflow runs**
   - You should see recent workflow runs
   - Both CI/CD Pipeline and GitHub Pages workflows should appear

3. **Check for successful completion**
   - Look for green checkmarks ✅
   - If any failed, click to see error logs

## 📋 Your Configured Workflows

### 1. CI/CD Pipeline (`.github/workflows/ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Jobs:**
- **Python Linting** - Code quality checks with flake8, black, mypy
- **YAML Linting** - Configuration file validation
- **Security Scanning** - Dependency and code security checks
- **Script Validation** - Shell and Python syntax checking
- **Secret Scanning** - Detect leaked credentials
- **Documentation Check** - Broken link detection
- **Docker Compose Validation** - Docker configuration validation
- **Kubernetes Validation** - K8s manifest validation

### 2. GitHub Pages Deployment (`.github/workflows/github-pages.yml`)

**Triggers:**
- Push to `main` branch
- Manual workflow dispatch

**Jobs:**
- **Deploy** - Deploys `docs/` directory to GitHub Pages

## 🔧 Manual Workflow Trigger

If you want to manually trigger workflows:

### Trigger CI/CD Pipeline

1. **Go to Actions tab**
   - https://github.com/nellaivijay/iceberg-code-practice/actions

2. **Select "CI/CD Pipeline" workflow**

3. **Click "Run workflow"**

4. **Select branch** (usually `main`)

5. **Click "Run workflow"**

### Trigger GitHub Pages Deployment

1. **Go to Actions tab**
   - https://github.com/nellaivijay/iceberg-code-practice/actions

2. **Select "Deploy to GitHub Pages" workflow**

3. **Click "Run workflow"**

4. **Click "Run workflow"**

## ✅ Verification Checklist

- [ ] GitHub Actions enabled in repository settings
- [ ] Workflow permissions configured (Read and write)
- [ ] GitHub Pages source set to GitHub Actions
- [ ] CI/CD workflow runs successfully
- [ ] GitHub Pages workflow runs successfully
- [ ] Workflows trigger automatically on push

## 🆘 Troubleshooting

### Workflows Not Triggering

**Issue:** Workflows don't run on push

**Solutions:**
1. Check if Actions is enabled in settings
2. Verify workflow files are in `.github/workflows/`
3. Check branch names match workflow triggers
4. Ensure workflow syntax is correct (YAML validation)

### Workflow Permissions Error

**Issue:** "Resource not accessible by this integration"

**Solutions:**
1. Go to Settings → Actions → General
2. Set workflow permissions to "Read and write permissions"
3. Ensure GitHub Pages permissions are configured

### GitHub Pages Deployment Fails

**Issue:** Pages workflow fails

**Solutions:**
1. Check Actions logs for specific error
2. Verify Jekyll configuration is valid
3. Ensure `docs/` directory exists
4. Check for broken links in documentation

### CI/CD Pipeline Failures

**Issue:** CI checks fail

**Solutions:**
1. Check which specific job failed
2. Review error logs for that job
3. Fix the issue locally
4. Commit and push again

## 📊 Monitoring Workflows

### View Workflow History

1. **Go to Actions tab**
   - https://github.com/nellaivijay/iceberg-code-practice/actions

2. **View workflow runs**
   - All workflow runs are listed
   - Click on any run to see details

3. **Check logs**
   - Click on failed jobs to see error logs
   - Download logs if needed

### Workflow Status Badges

Add workflow status badges to your README:

```markdown
![CI/CD Pipeline](https://github.com/nellaivijay/iceberg-code-practice/actions/workflows/ci.yml/badge.svg)
![GitHub Pages](https://github.com/nellaivijay/iceberg-code-practice/actions/workflows/github-pages.yml/badge.svg)
```

## 🎨 Workflow Customization

### Add New Workflow

1. **Create workflow file**
   - Create `.github/workflows/your-workflow.yml`
   - Follow GitHub Actions syntax

2. **Define triggers**
   ```yaml
   on:
     push:
       branches: [ main ]
     pull_request:
       branches: [ main ]
   ```

3. **Define jobs and steps**
   ```yaml
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - run: echo "Hello World"
   ```

### Modify Existing Workflows

1. **Edit workflow file**
   - Edit `.github/workflows/ci.yml` or `github-pages.yml`
   - Make your changes

2. **Commit and push**
   ```bash
   git add .github/workflows/
   git commit -m "Update workflow configuration"
   git push origin main
   ```

3. **Workflow will run automatically**

## 🔒 Security Best Practices

### Workflow Permissions

- Use minimum required permissions
- Don't grant unnecessary access
- Review permissions regularly

### Secrets Management

- Store sensitive data in GitHub Secrets
- Never hardcode credentials in workflows
- Use environment variables for configuration

### Dependency Security

- Keep dependencies updated
- Use Dependabot for automated dependency updates
- Review security alerts regularly

## 📈 Performance Optimization

### Workflow Caching

Add caching to speed up workflows:

```yaml
- name: Cache pip packages
  uses: actions/cache@v3
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
```

### Parallel Jobs

Run jobs in parallel to save time:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ['3.8', '3.9', '3.10']
```

### Conditional Steps

Add conditional execution:

```yaml
- name: Deploy
  if: github.ref == 'refs/heads/main'
  run: echo "Deploying to production"
```

## 🎯 Success Indicators

When GitHub Actions is properly configured:

✅ Workflows trigger automatically on push
✅ CI/CD pipeline runs successfully
✅ GitHub Pages deployment completes
✅ Workflow history shows recent runs
✅ No permission errors in logs
✅ All jobs complete successfully

---

**🚀 Your GitHub Actions are configured and ready to automate your CI/CD and documentation deployment!**
