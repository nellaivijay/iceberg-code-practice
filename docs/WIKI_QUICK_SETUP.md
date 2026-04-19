# Wiki Setup Instructions

Follow these exact steps to set up your GitHub Wiki with the educational content.

## 🚀 Step-by-Step Setup

### Step 1: Access Your Wiki (1 minute)

1. **Go to your repository wiki**
   - Visit: https://github.com/nellaivijay/iceberg-code-practice/wiki

2. **Enable wiki if needed**
   - If you see "Enable Wiki" button, click it
   - If wiki is already enabled, you'll see wiki pages

### Step 2: Create Wiki Pages (15-20 minutes)

Use the helper script to easily copy content:

```bash
./scripts/copy_wiki_content.sh
```

This script will display each wiki file's content for easy copying.

#### Manual Process (Alternative)

For each wiki file, create a page:

**Page 1: Home**
1. Click "Add Page" in wiki
2. Title: `Home`
3. Copy content from: `wiki/Home.md`
4. Paste into wiki editor
5. Click "Save"

**Page 2: Getting-Started**
1. Click "Add Page"
2. Title: `Getting-Started`
3. Copy content from: `wiki/Getting-Started.md`
4. Paste into wiki editor
5. Click "Save"

**Page 3: Iceberg-Fundamentals**
1. Click "Add Page"
2. Title: `Iceberg-Fundamentals`
3. Copy content from: `wiki/Iceberg-Fundamentals.md`
4. Paste into wiki editor
5. Click "Save"

**Page 4: Lab-Guides**
1. Click "Add Page"
2. Title: `Lab-Guides`
3. Copy content from: `wiki/Lab-Guides.md`
4. Paste into wiki editor
5. Click "Save"

**Page 5: Learning-Path**
1. Click "Add Page"
2. Title: `Learning-Path`
3. Copy content from: `wiki/Learning-Path.md`
4. Paste into wiki editor
5. Click "Save"

**Page 6: Best-Practices**
1. Click "Add Page"
2. Title: `Best-Practices`
3. Copy content from: `wiki/Best-Practices.md`
4. Paste into wiki editor
5. Click "Save"

**Page 7: Troubleshooting**
1. Click "Add Page"
2. Title: `Troubleshooting`
3. Copy content from: `wiki/Troubleshooting.md`
4. Paste into wiki editor
5. Click "Save"

### Step 3: Organize Wiki Sidebar (Optional, 2 minutes)

1. **Click "Edit sidebar"** (if available)

2. **Add pages in this order:**
   ```
   Home
   Getting-Started
   Iceberg-Fundamentals
   Lab-Guides
   Learning-Path
   Best-Practices
   Troubleshooting
   ```

3. **Save sidebar**

## 📋 Quick Reference

**Wiki URL:** https://github.com/nellaivijay/iceberg-code-practice/wiki

**Wiki Files Location:** `wiki/` directory

**Helper Script:** `./scripts/copy_wiki_content.sh`

**Available Wiki Pages:**
- Home.md - Main landing page
- Getting-Started.md - Setup and first steps
- Iceberg-Fundamentals.md - Core concepts
- Lab-Guides.md - Detailed lab walkthroughs
- Learning-Path.md - Recommended learning sequence
- Best-Practices.md - Production patterns
- Troubleshooting.md - Common issues

## ✅ Verification Checklist

- [ ] Wiki enabled in repository
- [ ] All 7 wiki pages created
- [ ] Content properly formatted
- [ ] Links work correctly
- [ ] Sidebar organized (if available)
- [ ] Pages accessible at wiki URL

## 🎯 Tips for Success

### Content Formatting

- **Headings**: Use proper markdown heading syntax
- **Links**: Verify all links point to correct locations
- **Code blocks**: Use proper markdown code formatting
- **Images**: Add images if they enhance understanding

### Link Verification

After creating pages, verify:
- Internal wiki links work
- Repository links are correct
- External links are valid
- Navigation is intuitive

### Community Engagement

Once wiki is set up:
- Share wiki URL in README
- Link wiki from GitHub Pages site
- Encourage community contributions
- Monitor and update content regularly

## 🆘 Troubleshooting

### Wiki Not Enabled

**Solution:**
1. Go to Settings → Features
2. Ensure "Wiki" is checked
3. Save settings

### Content Not Formatting

**Solution:**
- Check markdown syntax
- Verify proper heading levels
- Ensure code blocks are properly formatted
- Test in markdown preview

### Links Not Working

**Solution:**
- Verify URL formats
- Check for typos in links
- Ensure repository URLs are correct
- Test links in incognito mode

## 🎨 Customization

### Add Additional Pages

1. Create new markdown file in `wiki/` directory
2. Add content following existing format
3. Create corresponding page in GitHub Wiki
4. Update sidebar if needed

### Add Images

1. Upload images to wiki (if supported)
2. Reference images in markdown:
   ```markdown
   ![Alt text](image-url)
   ```

### Customize Styling

- GitHub Wiki has limited styling options
- Focus on content quality and structure
- Use consistent formatting throughout

## 📊 Wiki Analytics

GitHub provides basic wiki analytics:
- Page views
- Visitor count
- Edit history

Access via:
- Wiki page views (shown on each page)
- Repository insights (if available)

## 🔄 Maintenance

### Regular Updates

**Monthly:**
- Review content for accuracy
- Update with new information
- Fix broken links
- Add new content as needed

**Community Contributions:**
- Monitor wiki edits
- Review community contributions
- Merge valuable changes
- Acknowledge contributors

## 🎉 Success Indicators

When setup is complete, you should see:

✅ All 7 wiki pages created
✅ Content properly formatted and readable
✅ All links working correctly
✅ Sidebar organized logically
✅ Pages accessible via wiki URL
✅ Content integrated with main documentation

---

**📚 Your educational wiki will be a comprehensive resource for Apache Iceberg learners!**
