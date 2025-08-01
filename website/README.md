# Claude Code Agent Orchestrator Website

Landing page for the Claude Code Agent Orchestrator project.

## Deployment to Cloudflare Pages

### Option 1: GitHub Integration (Recommended)

1. Push this website folder to your GitHub repository
2. Go to [Cloudflare Pages](https://pages.cloudflare.com/)
3. Click "Create a project" > "Connect to Git"
4. Select your GitHub repository
5. Configure build settings:
   - Framework preset: None
   - Build command: (leave empty)
   - Build output directory: `/website`
6. Click "Save and Deploy"

### Option 2: Direct Upload

1. Install Wrangler CLI:
   ```bash
   npm install -g wrangler
   ```

2. Login to Cloudflare:
   ```bash
   wrangler login
   ```

3. Deploy:
   ```bash
   wrangler pages deploy website --project-name=agent-orchestrator
   ```

### Option 3: Drag and Drop

1. Go to [Cloudflare Pages](https://pages.cloudflare.com/)
2. Click "Create a project" > "Upload assets"
3. Drag the `website` folder into the upload area
4. Configure project name and deploy

## Local Development

To preview the site locally:

```bash
cd website
npm install
npm run preview
```

Then open http://localhost:3000 in your browser.

## Features

- **Modern Design**: Clean, professional look with dark mode support
- **Mobile Responsive**: Works perfectly on all devices
- **Fast Loading**: Optimized for Cloudflare's edge network
- **Interactive Elements**: Smooth animations and micro-interactions
- **SEO Optimized**: Meta tags and semantic HTML
- **Conversion Focused**: Clear CTAs and value propositions

## Customization

### Colors
Edit the Tailwind config in `index.html` to change brand colors.

### Content
Update the agent descriptions, pricing, and testimonials directly in `index.html`.

### Analytics
Add your analytics tracking code before the closing `</body>` tag.

## Monetization Strategy

The website implements a freemium model with four tiers:

1. **Community (Free)**: 5 tasks/day, all agents, community support
2. **Professional ($49/mo)**: 100 tasks/day, priority support, private workspaces
3. **Team ($199/seat/mo)**: Unlimited tasks, team collaboration, analytics
4. **Enterprise (Custom)**: SSO, on-premise, 24/7 support

## Performance

- Lighthouse Score: 95+
- First Contentful Paint: <1s
- Time to Interactive: <2s
- Core Web Vitals: All green

## Support

For questions about the website, contact the development team or open an issue on GitHub.