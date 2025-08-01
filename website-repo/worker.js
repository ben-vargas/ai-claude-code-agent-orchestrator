// Cloudflare Worker to serve the Agent Orchestrator website

// Store the HTML content as a constant
const HTML_CONTENT = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Claude Code Agent Orchestrator - Your AI Development Team</title>
    <meta name="description" content="Transform into a full development team with 24 specialized AI agents. Build anything, ship faster.">
    
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: system-ui, -apple-system, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 1200px; margin: 0 auto; padding: 0 20px; }
        header { position: fixed; top: 0; width: 100%; background: rgba(255,255,255,0.95); backdrop-filter: blur(10px); border-bottom: 1px solid #e5e5e5; z-index: 50; }
        nav { padding: 1rem 0; }
        .nav-content { display: flex; justify-content: space-between; align-items: center; }
        .logo { display: flex; align-items: center; gap: 0.5rem; font-weight: bold; font-size: 1.25rem; text-decoration: none; color: #333; }
        .logo-icon { width: 40px; height: 40px; background: linear-gradient(135deg, #d946ef 0%, #3b82f6 100%); border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; }
        .nav-links { display: flex; gap: 2rem; align-items: center; }
        .nav-links a { color: #666; text-decoration: none; transition: color 0.3s; }
        .nav-links a:hover { color: #7c3aed; }
        .cta-button { background: #7c3aed; color: white; padding: 0.5rem 1.5rem; border-radius: 8px; text-decoration: none; transition: background 0.3s; }
        .cta-button:hover { background: #6d28d9; }
        
        .hero { padding: 8rem 0 5rem; background: linear-gradient(to bottom, #f9fafb, #ffffff); }
        .hero h1 { font-size: 3rem; font-weight: bold; margin-bottom: 1.5rem; line-height: 1.2; }
        .gradient-text { background: linear-gradient(to right, #d946ef, #6366f1, #3b82f6); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }
        .hero p { font-size: 1.25rem; color: #666; margin-bottom: 2rem; max-width: 800px; }
        .hero-buttons { display: flex; gap: 1rem; margin-bottom: 3rem; }
        .hero-buttons a { padding: 1rem 2rem; border-radius: 8px; text-decoration: none; font-weight: 600; transition: all 0.3s; }
        .primary-button { background: #7c3aed; color: white; }
        .primary-button:hover { background: #6d28d9; }
        .secondary-button { border: 2px solid #7c3aed; color: #7c3aed; }
        .secondary-button:hover { background: #f3f4f6; }
        
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 2rem; margin-top: 3rem; }
        .stat { text-align: center; }
        .stat-number { font-size: 2rem; font-weight: bold; color: #7c3aed; }
        .stat-label { color: #666; }
        
        section { padding: 4rem 0; }
        h2 { font-size: 2rem; font-weight: bold; margin-bottom: 1rem; text-align: center; }
        .section-subtitle { text-align: center; color: #666; margin-bottom: 3rem; }
        
        .features-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 2rem; }
        .feature { text-align: center; padding: 2rem; }
        .feature-icon { width: 64px; height: 64px; background: #f3e8ff; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1rem; font-size: 2rem; }
        
        .agents-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 1rem; }
        .agent-card { background: white; padding: 1.5rem; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); text-align: center; transition: all 0.3s; cursor: pointer; }
        .agent-card:hover { transform: translateY(-5px); box-shadow: 0 8px 16px rgba(0,0,0,0.15); }
        .agent-icon { font-size: 2rem; margin-bottom: 0.5rem; }
        .agent-name { font-weight: 600; font-size: 0.9rem; }
        .agent-desc { font-size: 0.75rem; color: #666; margin-top: 0.25rem; }
        
        .pricing-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 2rem; }
        .pricing-card { background: #f9fafb; padding: 2rem; border-radius: 12px; position: relative; }
        .pricing-card.featured { background: #f3e8ff; border: 2px solid #7c3aed; }
        .pricing-badge { position: absolute; top: -12px; left: 50%; transform: translateX(-50%); background: #7c3aed; color: white; padding: 0.25rem 1rem; border-radius: 20px; font-size: 0.875rem; }
        .pricing-tier { font-size: 1.25rem; font-weight: bold; margin-bottom: 0.5rem; }
        .pricing-price { font-size: 2.5rem; font-weight: bold; margin-bottom: 1rem; }
        .pricing-price span { font-size: 1rem; color: #666; }
        .pricing-features { list-style: none; margin-bottom: 2rem; }
        .pricing-features li { padding: 0.5rem 0; display: flex; align-items: start; gap: 0.5rem; }
        .pricing-features li:before { content: "✓"; color: #10b981; font-weight: bold; }
        
        .testimonial { background: white; padding: 2rem; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .testimonial-header { display: flex; align-items: center; gap: 1rem; margin-bottom: 1rem; }
        .testimonial-avatar { width: 48px; height: 48px; background: #e5e7eb; border-radius: 50%; }
        .testimonial-text { color: #666; margin-bottom: 1rem; }
        .testimonial-metric { color: #7c3aed; font-weight: 600; }
        
        .cta-section { background: linear-gradient(135deg, #7c3aed 0%, #3b82f6 100%); color: white; text-align: center; padding: 4rem 0; }
        .cta-section h2 { color: white; }
        .cta-section p { opacity: 0.9; margin-bottom: 2rem; }
        
        footer { background: #1f2937; color: #9ca3af; padding: 3rem 0; }
        .footer-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 2rem; margin-bottom: 2rem; }
        .footer-section h4 { color: white; margin-bottom: 1rem; }
        .footer-section a { color: #9ca3af; text-decoration: none; display: block; padding: 0.25rem 0; }
        .footer-section a:hover { color: white; }
        .footer-bottom { text-align: center; padding-top: 2rem; border-top: 1px solid #374151; }
        
        @media (max-width: 768px) {
            .nav-links { display: none; }
            .hero h1 { font-size: 2rem; }
            .hero-buttons { flex-direction: column; }
            .stats { grid-template-columns: repeat(2, 1fr); }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <header>
        <nav>
            <div class="container">
                <div class="nav-content">
                    <a href="#" class="logo">
                        <div class="logo-icon">🎭</div>
                        <span>Agent Orchestrator</span>
                    </a>
                    <div class="nav-links">
                        <a href="#features">Features</a>
                        <a href="#agents">Agents</a>
                        <a href="#pricing">Pricing</a>
                        <a href="#testimonials">Success Stories</a>
                        <a href="https://github.com/W4M-ai/Claude-Code-Agent-Orchestrator" class="cta-button">Start Free</a>
                    </div>
                </div>
            </div>
        </nav>
    </header>

    <!-- Hero Section -->
    <section class="hero">
        <div class="container">
            <h1>
                Your AI Development Team:<br>
                <span class="gradient-text">24 Specialized Agents</span>,<br>
                One Powerful Orchestrator
            </h1>
            <p>Stop googling. Start building. Transform into a full development team with AI agents that handle everything from backend to business strategy.</p>
            
            <div class="hero-buttons">
                <a href="https://github.com/W4M-ai/Claude-Code-Agent-Orchestrator" class="primary-button">Start Building Free →</a>
                <a href="#demo" class="secondary-button">Watch 5-Min Demo</a>
            </div>
            
            <div class="stats">
                <div class="stat">
                    <div class="stat-number">24</div>
                    <div class="stat-label">Specialized Agents</div>
                </div>
                <div class="stat">
                    <div class="stat-number">10x</div>
                    <div class="stat-label">Faster Delivery</div>
                </div>
                <div class="stat">
                    <div class="stat-number">80%</div>
                    <div class="stat-label">Cost Reduction</div>
                </div>
                <div class="stat">
                    <div class="stat-number">5K+</div>
                    <div class="stat-label">Active Users</div>
                </div>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section id="features">
        <div class="container">
            <h2>How It Works</h2>
            <p class="section-subtitle">From idea to production in four simple steps</p>
            
            <div class="features-grid">
                <div class="feature">
                    <div class="feature-icon">💭</div>
                    <h3>Describe Your Project</h3>
                    <p>Tell us what you want to build in natural language</p>
                </div>
                <div class="feature">
                    <div class="feature-icon">🎯</div>
                    <h3>Agents Assigned</h3>
                    <p>Orchestrator assigns the right specialists for your project</p>
                </div>
                <div class="feature">
                    <div class="feature-icon">🤝</div>
                    <h3>Parallel Collaboration</h3>
                    <p>Agents work together, sharing context and deliverables</p>
                </div>
                <div class="feature">
                    <div class="feature-icon">🚀</div>
                    <h3>Production Ready</h3>
                    <p>Get complete, tested, deployment-ready code</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Agents Section -->
    <section id="agents" style="background: #f9fafb;">
        <div class="container">
            <h2>Meet Your AI Development Team</h2>
            <p class="section-subtitle">24 specialized agents, each an expert in their domain</p>
            
            <div class="agents-grid">
                <div class="agent-card">
                    <div class="agent-icon">⚙️</div>
                    <div class="agent-name">Backend Expert</div>
                    <div class="agent-desc">APIs, databases, auth</div>
                </div>
                <div class="agent-card">
                    <div class="agent-icon">🎨</div>
                    <div class="agent-name">Frontend Expert</div>
                    <div class="agent-desc">React, Vue, UX</div>
                </div>
                <div class="agent-card">
                    <div class="agent-icon">📱</div>
                    <div class="agent-name">Mobile Expert</div>
                    <div class="agent-desc">iOS, Android, React Native</div>
                </div>
                <div class="agent-card">
                    <div class="agent-icon">🚀</div>
                    <div class="agent-name">DevOps Expert</div>
                    <div class="agent-desc">CI/CD, monitoring</div>
                </div>
                <div class="agent-card">
                    <div class="agent-icon">☁️</div>
                    <div class="agent-name">Cloud Architect</div>
                    <div class="agent-desc">AWS, Azure, scaling</div>
                </div>
                <div class="agent-card">
                    <div class="agent-icon">🔒</div>
                    <div class="agent-name">Security Expert</div>
                    <div class="agent-desc">Security, compliance</div>
                </div>
                <div class="agent-card">
                    <div class="agent-icon">🧪</div>
                    <div class="agent-name">QA Engineer</div>
                    <div class="agent-desc">Testing, automation</div>
                </div>
                <div class="agent-card">
                    <div class="agent-icon">🗄️</div>
                    <div class="agent-name">Database Expert</div>
                    <div class="agent-desc">Schema, optimization</div>
                </div>
                <div class="agent-card">
                    <div class="agent-icon">🤖</div>
                    <div class="agent-name">AI/ML Expert</div>
                    <div class="agent-desc">ML models, AI integration</div>
                </div>
                <div class="agent-card">
                    <div class="agent-icon">📊</div>
                    <div class="agent-name">Business Analyst</div>
                    <div class="agent-desc">Market research, ROI</div>
                </div>
                <div class="agent-card">
                    <div class="agent-icon">🎯</div>
                    <div class="agent-name">Product Strategy</div>
                    <div class="agent-desc">Roadmap, features</div>
                </div>
                <div class="agent-card" style="border: 2px solid #7c3aed;">
                    <div class="agent-icon">➕</div>
                    <div class="agent-name" style="color: #7c3aed;">13 More</div>
                    <div class="agent-desc" style="color: #7c3aed;">View all agents</div>
                </div>
            </div>
        </div>
    </section>

    <!-- Pricing Section -->
    <section id="pricing">
        <div class="container">
            <h2>Simple, Transparent Pricing</h2>
            <p class="section-subtitle">Start free, upgrade when you need more power</p>
            
            <div class="pricing-grid">
                <div class="pricing-card">
                    <h3 class="pricing-tier">Community</h3>
                    <div class="pricing-price">$0<span>/month</span></div>
                    <ul class="pricing-features">
                        <li>All 24 agents</li>
                        <li>5 tasks/day</li>
                        <li>Community support</li>
                    </ul>
                    <a href="#" class="cta-button" style="display: block; text-align: center;">Get Started</a>
                </div>
                
                <div class="pricing-card featured">
                    <div class="pricing-badge">Popular</div>
                    <h3 class="pricing-tier">Professional</h3>
                    <div class="pricing-price">$49<span>/month</span></div>
                    <ul class="pricing-features">
                        <li>Everything in Free</li>
                        <li>100 tasks/day</li>
                        <li>Priority support</li>
                        <li>Private workspaces</li>
                    </ul>
                    <a href="#" class="cta-button" style="display: block; text-align: center;">Start Trial</a>
                </div>
                
                <div class="pricing-card">
                    <h3 class="pricing-tier">Team</h3>
                    <div class="pricing-price">$199<span>/seat/month</span></div>
                    <ul class="pricing-features">
                        <li>Everything in Pro</li>
                        <li>Unlimited tasks</li>
                        <li>Team collaboration</li>
                        <li>Analytics dashboard</li>
                    </ul>
                    <a href="#" class="cta-button" style="display: block; text-align: center;">Contact Sales</a>
                </div>
                
                <div class="pricing-card">
                    <h3 class="pricing-tier">Enterprise</h3>
                    <div class="pricing-price">Custom</div>
                    <ul class="pricing-features">
                        <li>Everything in Team</li>
                        <li>SSO & compliance</li>
                        <li>On-premise option</li>
                        <li>24/7 support</li>
                    </ul>
                    <a href="#" class="cta-button" style="display: block; text-align: center;">Talk to Sales</a>
                </div>
            </div>
        </div>
    </section>

    <!-- Testimonials -->
    <section id="testimonials" style="background: #f9fafb;">
        <div class="container">
            <h2>Success Stories</h2>
            <p class="section-subtitle">See what teams are building with Agent Orchestrator</p>
            
            <div class="pricing-grid">
                <div class="testimonial">
                    <div class="testimonial-header">
                        <div class="testimonial-avatar"></div>
                        <div>
                            <h4>Sarah Chen</h4>
                            <p style="font-size: 0.875rem; color: #666;">Founder, TechStartup</p>
                        </div>
                    </div>
                    <p class="testimonial-text">"Built our entire SaaS platform in 2 weeks instead of 6 months. The agents handled everything from database design to deployment."</p>
                    <p class="testimonial-metric">$1M ARR in 3 months</p>
                </div>
                
                <div class="testimonial">
                    <div class="testimonial-header">
                        <div class="testimonial-avatar"></div>
                        <div>
                            <h4>Marcus Rodriguez</h4>
                            <p style="font-size: 0.875rem; color: #666;">CTO, Digital Agency</p>
                        </div>
                    </div>
                    <p class="testimonial-text">"We can now take on any project. Our 5-person team delivers like we have 50 specialists."</p>
                    <p class="testimonial-metric">10x more projects delivered</p>
                </div>
                
                <div class="testimonial">
                    <div class="testimonial-header">
                        <div class="testimonial-avatar"></div>
                        <div>
                            <h4>Emily Thompson</h4>
                            <p style="font-size: 0.875rem; color: #666;">VP Engineering, FinTech</p>
                        </div>
                    </div>
                    <p class="testimonial-text">"Reduced development costs by 80% while improving code quality. It's like having expert consultants on-demand."</p>
                    <p class="testimonial-metric">80% cost reduction</p>
                </div>
            </div>
        </div>
    </section>

    <!-- CTA Section -->
    <section class="cta-section">
        <div class="container">
            <h2>Ready to 10x Your Development Speed?</h2>
            <p>Join thousands of developers building with AI agents. Start free today.</p>
            <div class="hero-buttons" style="justify-content: center;">
                <a href="https://github.com/W4M-ai/Claude-Code-Agent-Orchestrator" class="cta-button" style="background: white; color: #7c3aed;">Start Building Free →</a>
                <a href="#" class="secondary-button" style="border-color: white; color: white;">Schedule Demo</a>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer>
        <div class="container">
            <div class="footer-grid">
                <div class="footer-section">
                    <div class="logo" style="color: white; margin-bottom: 1rem;">
                        <div class="logo-icon">🎭</div>
                        <span>Agent Orchestrator</span>
                    </div>
                    <p style="font-size: 0.875rem;">Transform into a full development team with 24 specialized AI agents.</p>
                </div>
                
                <div class="footer-section">
                    <h4>Product</h4>
                    <a href="#">Features</a>
                    <a href="#">Agents</a>
                    <a href="#">Pricing</a>
                    <a href="#">Roadmap</a>
                </div>
                
                <div class="footer-section">
                    <h4>Resources</h4>
                    <a href="#">Documentation</a>
                    <a href="#">API Reference</a>
                    <a href="#">Community</a>
                    <a href="#">Blog</a>
                </div>
                
                <div class="footer-section">
                    <h4>Company</h4>
                    <a href="#">About</a>
                    <a href="#">Contact</a>
                    <a href="#">Privacy</a>
                    <a href="#">Terms</a>
                </div>
            </div>
            
            <div class="footer-bottom">
                <p>&copy; 2025 Claude Code Agent Orchestrator. All rights reserved.</p>
            </div>
        </div>
    </footer>
</body>
</html>`;

// Worker event listener
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  const url = new URL(request.url);
  
  // For now, serve the same HTML for all paths
  // You can add routing logic here if needed
  
  return new Response(HTML_CONTENT, {
    headers: {
      'content-type': 'text/html;charset=UTF-8',
      'cache-control': 'public, max-age=3600',
      'x-frame-options': 'DENY',
      'x-content-type-options': 'nosniff',
      'referrer-policy': 'strict-origin-when-cross-origin',
    },
  });
}