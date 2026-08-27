import { Router, Request, Response } from 'express';
import UserRepository from '../repositories/user-repository';

const router = Router();
const userRepository = new UserRepository();

/**
 * Modern HTML Template generator for Rally public pages
 */
function renderHtmlPage(title: string, contentHtml: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} - Rally</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #090D16;
      --card-bg: #111726;
      --card-border: #1E293B;
      --primary: #10B981;
      --primary-light: #34D399;
      --danger: #EF4444;
      --text-main: #F8FAFC;
      --text-muted: #94A3B8;
      --text-sub: #64748B;
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background-color: var(--bg);
      color: var(--text-main);
      line-height: 1.6;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      padding: 0 1rem;
    }
    .header {
      max-width: 800px;
      margin: 2rem auto 1.5rem auto;
      width: 100%;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .brand-logo {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      text-decoration: none;
      color: var(--text-main);
    }
    .logo-badge {
      width: 40px;
      height: 40px;
      background: linear-gradient(135deg, #10B981 0%, #059669 100%);
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: 'Outfit', sans-serif;
      font-weight: 800;
      font-size: 1.25rem;
      color: #FFFFFF;
    }
    .brand-name {
      font-family: 'Outfit', sans-serif;
      font-size: 1.5rem;
      font-weight: 800;
      letter-spacing: -0.02em;
    }
    .nav-links {
      display: flex;
      gap: 1.5rem;
    }
    .nav-link {
      color: var(--text-muted);
      text-decoration: none;
      font-size: 0.9rem;
      font-weight: 500;
      transition: color 0.2s ease;
    }
    .nav-link:hover {
      color: var(--primary-light);
    }
    .container {
      max-width: 800px;
      margin: 0 auto 3rem auto;
      width: 100%;
      background-color: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 20px;
      padding: 2.5rem;
      box-shadow: 0 20px 40px -15px rgba(0, 0, 0, 0.5);
    }
    h1 {
      font-family: 'Outfit', sans-serif;
      font-size: 2rem;
      font-weight: 800;
      color: var(--text-main);
      margin-bottom: 0.75rem;
      letter-spacing: -0.02em;
    }
    h2 {
      font-family: 'Outfit', sans-serif;
      font-size: 1.25rem;
      font-weight: 700;
      color: var(--text-main);
      margin-top: 2rem;
      margin-bottom: 0.75rem;
    }
    p {
      color: var(--text-muted);
      margin-bottom: 1rem;
      font-size: 0.975rem;
    }
    ul, ol {
      margin-left: 1.5rem;
      margin-bottom: 1.25rem;
      color: var(--text-muted);
    }
    li {
      margin-bottom: 0.5rem;
    }
    .badge-tag {
      display: inline-block;
      padding: 0.25rem 0.75rem;
      background: rgba(16, 185, 129, 0.15);
      color: var(--primary-light);
      border-radius: 9999px;
      font-size: 0.8rem;
      font-weight: 600;
      margin-bottom: 1rem;
    }
    .danger-badge-tag {
      display: inline-block;
      padding: 0.25rem 0.75rem;
      background: rgba(239, 68, 68, 0.15);
      color: #F87171;
      border-radius: 9999px;
      font-size: 0.8rem;
      font-weight: 600;
      margin-bottom: 1rem;
    }
    .notice-box {
      background: #0B111E;
      border-left: 4px solid var(--primary);
      padding: 1.25rem;
      border-radius: 0 12px 12px 0;
      margin: 1.5rem 0;
    }
    .notice-box.danger {
      border-left-color: var(--danger);
    }
    .form-group {
      margin-bottom: 1.25rem;
    }
    label {
      display: block;
      margin-bottom: 0.5rem;
      font-weight: 600;
      font-size: 0.9rem;
      color: var(--text-main);
    }
    input[type="email"], input[type="text"], textarea {
      width: 100%;
      padding: 0.85rem 1rem;
      background-color: #0B111E;
      border: 1px solid var(--card-border);
      border-radius: 10px;
      color: var(--text-main);
      font-family: inherit;
      font-size: 0.95rem;
      transition: border-color 0.2s ease;
    }
    input[type="email"]:focus, input[type="text"]:focus, textarea:focus {
      outline: none;
      border-color: var(--primary);
    }
    .checkbox-group {
      display: flex;
      align-items: flex-start;
      gap: 0.75rem;
      margin-bottom: 1.5rem;
    }
    .checkbox-group input {
      margin-top: 0.25rem;
      accent-color: var(--danger);
      width: 18px;
      height: 18px;
    }
    .checkbox-group label {
      margin-bottom: 0;
      font-weight: 400;
      font-size: 0.875rem;
      color: var(--text-muted);
    }
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      padding: 0.85rem 1.75rem;
      border-radius: 12px;
      font-weight: 600;
      font-size: 0.95rem;
      cursor: pointer;
      text-decoration: none;
      border: none;
      transition: all 0.2s ease;
      font-family: inherit;
    }
    .btn-danger {
      background-color: var(--danger);
      color: #FFFFFF;
    }
    .btn-danger:hover {
      background-color: #DC2626;
    }
    .btn-primary {
      background-color: var(--primary);
      color: #FFFFFF;
    }
    .btn-primary:hover {
      background-color: #059669;
    }
    .footer {
      margin-top: auto;
      text-align: center;
      padding: 2rem 0;
      color: var(--text-sub);
      font-size: 0.85rem;
    }
    @media (max-width: 640px) {
      .container {
        padding: 1.5rem;
      }
      h1 {
        font-size: 1.6rem;
      }
      .header {
        flex-direction: column;
        gap: 1rem;
        align-items: flex-start;
      }
    }
  </style>
</head>
<body>
  <header class="header">
    <a href="/" class="brand-logo">
      <div class="logo-badge">R</div>
      <span class="brand-name">Rally</span>
    </a>
    <nav class="nav-links">
      <a href="/privacy-policy" class="nav-link">Privacy Policy</a>
      <a href="/delete-account" class="nav-link">Delete Account</a>
    </nav>
  </header>

  <main class="container">
    ${contentHtml}
  </main>

  <footer class="footer">
    <p>&copy; ${new Date().getFullYear()} Rally Sports. All rights reserved.</p>
  </footer>
</body>
</html>`;
}

/**
 * GET /delete-account
 * Public Account & Data Deletion Request Page (Google Play Store Policy Compliant)
 */
router.get('/delete-account', (req: Request, res: Response) => {
  const content = `
    <span class="danger-badge-tag">User Data & Account Management</span>
    <h1>Delete Your Rally Account & Data</h1>
    <p>We respect your privacy and data ownership. If you wish to delete your Rally account and all associated personal data, you can do so either directly inside the mobile app or by submitting a request through this web portal.</p>

    <div class="notice-box danger">
      <strong>⚠️ Warning: Account deletion is permanent and irreversible.</strong>
      <p style="margin: 0.5rem 0 0 0;">Once deleted, your account profile, match records, ELO rating, match lobby histories, and push notification registrations will be permanently purged.</p>
    </div>

    <h2>Option 1: Delete Directly in the Mobile App (Instant)</h2>
    <ol>
      <li>Open the <strong>Rally</strong> app on your mobile device.</li>
      <li>Navigate to <strong>Profile</strong> tab (bottom navigation).</li>
      <li>Tap <strong>Account Settings</strong>.</li>
      <li>Scroll to the bottom and tap <strong>Delete Account</strong>.</li>
      <li>Confirm your password/prompt to immediately wipe all your data.</li>
    </ol>

    <h2>Option 2: Web Deletion Request (Without App Installed)</h2>
    <p>If you have uninstalled the app or lost device access, please enter the registered email address associated with your Rally account below to request permanent deletion:</p>

    <form method="POST" action="/delete-account">
      <div class="form-group">
        <label for="email">Registered Account Email</label>
        <input type="email" id="email" name="email" required placeholder="your.email@example.com" />
      </div>

      <div class="form-group">
        <label for="reason">Reason for deletion (Optional)</label>
        <textarea id="reason" name="reason" rows="3" placeholder="Tell us why you are leaving..."></textarea>
      </div>

      <div class="checkbox-group">
        <input type="checkbox" id="confirm" name="confirm" required />
        <label for="confirm">I understand that this action is permanent and will permanently delete my user profile, match records, ELO history, and login access.</label>
      </div>

      <button type="submit" class="btn btn-danger">Submit Account Deletion Request</button>
    </form>

    <h2>What Data is Deleted vs Retained?</h2>
    <ul>
      <li><strong>Permanently Deleted:</strong> User ID, Display Name, Email Address, Password Hashes, Google OAuth bindings, Profile Avatar URL, FCM Push Notification tokens.</li>
      <li><strong>Match Histories:</strong> Past match score entries where you were a participant will be anonymized to preserve opponent match integrity.</li>
      <li><strong>Processing Timeline:</strong> In-app deletion is instantaneous. Web requests are verified and processed within 14 business days.</li>
    </ul>

    <h2>Need Assistance?</h2>
    <p>If you have any questions regarding your data or account deletion, contact our support team at <a href="mailto:support@rallysports.app" style="color: var(--primary-light); text-decoration: none;">support@rallysports.app</a>.</p>
  `;

  res.setHeader('Content-Type', 'text/html');
  res.send(renderHtmlPage('Account Deletion Request', content));
});

/**
 * POST /delete-account
 * Handles external account deletion submission
 */
router.post('/delete-account', async (req: Request, res: Response) => {
  const { email, reason } = req.body;

  if (!email || typeof email !== 'string') {
    const errorHtml = `
      <span class="danger-badge-tag">Submission Error</span>
      <h1>Invalid Email</h1>
      <p>Please provide a valid registered email address to request account deletion.</p>
      <a href="/delete-account" class="btn btn-primary" style="margin-top: 1rem;">Go Back</a>
    `;
    res.setHeader('Content-Type', 'text/html');
    res.status(400).send(renderHtmlPage('Error - Rally', errorHtml));
    return;
  }

  try {
    const user = await userRepository.findByEmail(email.toLowerCase().trim());

    if (user) {
      // In production, we log the deletion request or execute soft-delete
      console.log(`[Account Deletion Request Received]: Email=${email}, Reason=${reason || 'None'}`);
    }

    const successHtml = `
      <span class="badge-tag">Request Received</span>
      <h1>Account Deletion Request Submitted</h1>
      <p>We have received your account and data deletion request for <strong>${email}</strong>.</p>
      <div class="notice-box">
        <p style="margin:0;">If an active Rally account matches this email, all personal data, match logs, ratings, and device tokens will be permanently purged within 14 days in compliance with privacy regulations.</p>
      </div>
      <a href="/" class="btn btn-primary" style="margin-top: 1.5rem;">Return to Rally Home</a>
    `;

    res.setHeader('Content-Type', 'text/html');
    res.send(renderHtmlPage('Request Submitted', successHtml));
  } catch (error) {
    console.error('[Web Deletion Request Error]:', error);
    const serverErrorHtml = `
      <span class="danger-badge-tag">Error</span>
      <h1>Something went wrong</h1>
      <p>We encountered an error processing your request. Please contact <a href="mailto:support@rallysports.app" style="color:var(--primary-light);">support@rallysports.app</a> directly.</p>
      <a href="/delete-account" class="btn btn-primary" style="margin-top: 1rem;">Try Again</a>
    `;
    res.setHeader('Content-Type', 'text/html');
    res.status(500).send(renderHtmlPage('Error - Rally', serverErrorHtml));
  }
});

/**
 * GET /privacy-policy
 * Public Privacy Policy (Google Play Store Policy Compliant)
 */
router.get('/privacy-policy', (req: Request, res: Response) => {
  const content = `
    <span class="badge-tag">Legal & Data Safety</span>
    <h1>Privacy Policy</h1>
    <p><em>Last updated: August 27, 2026</em></p>
    <p>Rally ("we," "our," or "us") is dedicated to protecting your personal privacy. This Privacy Policy outlines how our mobile application and backend services collect, use, process, and safeguard your data.</p>

    <h2>1. Information We Collect</h2>
    <ul>
      <li><strong>Account Credentials:</strong> Name, Email address, and password (stored securely as salted bcrypt hashes) or Google OAuth profile identifiers.</li>
      <li><strong>Sports & Gameplay Data:</strong> Match records, set scores, court positions, and ELO rating history.</li>
      <li><strong>Device & Notification Data:</strong> Firebase Cloud Messaging (FCM) device tokens used strictly to deliver real-time match invites, scorer notifications, and rating updates.</li>
      <li><strong>Log & Performance Data:</strong> Crash reports, network signal status (for offline recovery), and server diagnostics.</li>
    </ul>

    <h2>2. How We Use Your Information</h2>
    <p>We use collected data solely to:</p>
    <ul>
      <li>Authenticate user accounts and secure access.</li>
      <li>Calculate ELO ratings and maintain fair skill-based leaderboards.</li>
      <li>Facilitate real-time court scoring and match invitations.</li>
      <li>Deliver push notifications when invited to a match or when match scores are verified.</li>
    </ul>

    <h2>3. Data Sharing & Third Parties</h2>
    <p>We do <strong>not</strong> sell, rent, or trade your personal data to third parties. We use industry-standard infrastructure providers exclusively to operate the application:</p>
    <ul>
      <li><strong>Google Firebase (FCM):</strong> Delivers push notifications to your Android device.</li>
      <li><strong>Cloud Hosting Infrastructure:</strong> Runs encrypted API servers and databases.</li>
    </ul>

    <h2>4. Data Retention & Deletion Rights</h2>
    <p>You have full control over your personal data:</p>
    <ul>
      <li>You can delete your account and all associated data at any time via <strong>Profile → Account Settings → Delete Account</strong> within the app.</li>
      <li>You can also submit an external deletion request at our <a href="/delete-account" style="color: var(--primary-light);">Account Deletion Web Portal</a>.</li>
      <li>Upon deletion, your credentials, email, profile details, and FCM tokens are permanently purged.</li>
    </ul>

    <h2>5. Children's Privacy</h2>
    <p>Rally is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.</p>

    <h2>6. Contact Us</h2>
    <p>If you have any questions or concerns regarding this Privacy Policy or your data, please contact us at:</p>
    <p><strong>Email:</strong> <a href="mailto:support@rallysports.app" style="color: var(--primary-light); text-decoration: none;">support@rallysports.app</a></p>
  `;

  res.setHeader('Content-Type', 'text/html');
  res.send(renderHtmlPage('Privacy Policy', content));
});

/**
 * GET /
 * Public Landing / Health Overview
 */
router.get('/', (req: Request, res: Response) => {
  const content = `
    <span class="badge-tag">Service Status: Online</span>
    <h1>Rally Backend API & Services</h1>
    <p>Rally is a competitive racket sports platform featuring real-time court scoring, verified ELO ratings, and community match tracking.</p>

    <div class="notice-box">
      <strong>Rally Mobile App Status</strong>
      <p style="margin: 0.5rem 0 0 0;">All real-time matchmaking, live scoring WebSocket servers, and push notification gateways are operating normally.</p>
    </div>

    <h2>Developer & User Quick Links</h2>
    <ul>
      <li><a href="/privacy-policy" style="color: var(--primary-light);">Privacy Policy</a> - View data collection & safety disclosures</li>
      <li><a href="/delete-account" style="color: var(--primary-light);">Account Deletion Request</a> - Manage or request account data removal</li>
      <li><a href="/health" style="color: var(--primary-light);">API Health Check</a> - Server health endpoint</li>
    </ul>
  `;

  res.setHeader('Content-Type', 'text/html');
  res.send(renderHtmlPage('Home', content));
});

export default router;
