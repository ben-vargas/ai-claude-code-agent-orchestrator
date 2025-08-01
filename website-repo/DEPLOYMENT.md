# Cloudflare Worker Deployment Guide

This guide explains how to deploy the Agent Orchestrator website using Cloudflare Workers.

## Prerequisites

1. A Cloudflare account
2. Node.js and npm installed locally (for wrangler CLI)

## Deployment Steps

### 1. Install Wrangler CLI (if not already installed)

```bash
npm install -g wrangler
```

### 2. Login to Cloudflare

```bash
wrangler login
```

### 3. Deploy the Worker

From the project directory, run:

```bash
npx wrangler deploy
```

This will deploy your worker to Cloudflare's edge network.

### 4. View Your Deployment

After deployment, you'll receive a URL like:
```
https://agent-orchestrator.YOUR-SUBDOMAIN.workers.dev
```

## Cloudflare Dashboard Setup

1. Go to your Cloudflare dashboard
2. Navigate to Workers & Pages
3. Find your `agent-orchestrator` worker
4. Click on it to view settings and analytics

## Custom Domain Setup (Optional)

To use a custom domain:

1. In the Worker settings, go to "Triggers"
2. Add a custom domain or route
3. Configure your DNS settings to point to the worker

## Updating the Site

To update the website content:

1. Edit the HTML in `worker.js`
2. Run `npx wrangler deploy` again

## Environment Variables (Optional)

If you need environment variables, add them to `wrangler.toml`:

```toml
[vars]
API_KEY = "your-api-key"
```

## Monitoring

- View real-time logs: `wrangler tail`
- Check analytics in the Cloudflare dashboard
- Set up alerts for errors or high traffic

## Troubleshooting

1. **Deployment fails**: Ensure you're logged in with `wrangler login`
2. **Site not loading**: Check the worker status in Cloudflare dashboard
3. **Changes not appearing**: Clear browser cache or use incognito mode

## Why Workers Instead of Pages?

Cloudflare Workers offer:
- Better performance with edge computing
- More control over request/response handling
- Built-in caching capabilities
- Easy A/B testing and gradual rollouts
- Better suited for dynamic content in the future