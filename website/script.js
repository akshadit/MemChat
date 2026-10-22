/**
 * MemChat Tester Hub — Frontend Logic
 * Sends registration to Google Sheets webhook and dispatches email alert to developer.
 */

// ============================================================================
// CONFIGURATION
// ============================================================================
// 1. Paste your deployed Google Apps Script Web App URL below:
const GOOGLE_SHEET_WEBHOOK_URL = 'https://script.google.com/macros/s/AKfycbwJdOlR-2Us1zgSb-UJfZuVqywFNNHJvDzd8_IdNBCux073VF1w3Hx3nJYgIw7_SUKd/exec';

// 2. Your email address for direct alerts (used as instant notification fallback):
const DEVELOPER_EMAIL = 'akshayaditya1976@gmail.com';
// ============================================================================

// Hub Tab Switching
function switchHubTab(tab) {
  const tabRegister = document.getElementById('tabRegister');
  const tabDownload = document.getElementById('tabDownload');
  const viewRegister = document.getElementById('hubRegisterView');
  const viewDownload = document.getElementById('hubDownloadView');

  if (tab === 'register') {
    tabRegister.classList.add('active');
    tabDownload.classList.remove('active');
    viewRegister.style.display = 'block';
    viewDownload.style.display = 'none';
  } else {
    tabRegister.classList.remove('active');
    tabDownload.classList.add('active');
    viewRegister.style.display = 'none';
    viewDownload.style.display = 'block';
  }
}

// Form Submission
async function handleTesterSubmit(e) {
  e.preventDefault();

  const name = document.getElementById('testerName').value.trim();
  const email = document.getElementById('testerEmail').value.trim().toLowerCase();
  const device = document.getElementById('testerDevice').value.trim() || 'Android Device';
  const role = document.getElementById('testerRole').value;
  const submitBtn = document.getElementById('submitTesterBtn') || e.target.querySelector('button[type="submit"]');

  if (!email.includes('@')) {
    alert('Please enter a valid Gmail address.');
    return;
  }

  const timestamp = new Date().toLocaleString('en-US', {
    timeZone: 'Asia/Kolkata',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });

  const payload = {
    name: name,
    email: email,
    device: device,
    role: role,
    timestamp: timestamp,
    _subject: `🚀 [MemChat Beta] New Tester Registration: ${email}`,
    _template: 'table',
    _captcha: 'false'
  };

  // UI Loading State
  const originalBtnContent = submitBtn ? submitBtn.innerHTML : '';
  if (submitBtn) {
    submitBtn.disabled = true;
    submitBtn.innerHTML = `
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="spin">
        <circle cx="12" cy="12" r="10" stroke-opacity="0.25"/>
        <path d="M12 2a10 10 0 0 1 10 10"/>
      </svg>
      <span>Registering & Unlocking APK...</span>
    `;
  }

  const promises = [];

  // 1. Send to Google Sheets Webhook (if URL configured)
  const webhookUrl = GOOGLE_SHEET_WEBHOOK_URL || localStorage.getItem('memchat_google_sheet_webhook');
  if (webhookUrl) {
    promises.push(
      fetch(webhookUrl, {
        method: 'POST',
        mode: 'no-cors',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      }).catch(err => console.warn('Google Sheet webhook error:', err))
    );
  }

  // 2. Send instant email notification via FormSubmit
  if (DEVELOPER_EMAIL) {
    promises.push(
      fetch(`https://formsubmit.co/ajax/${DEVELOPER_EMAIL}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify(payload)
      }).catch(err => console.warn('Email dispatch error:', err))
    );
  }

  // Wait max 1.5 seconds for network requests so tester is never kept waiting
  await Promise.race([
    Promise.allSettled(promises),
    new Promise(resolve => setTimeout(resolve, 1500))
  ]);

  // Restore button
  if (submitBtn) {
    submitBtn.disabled = false;
    submitBtn.innerHTML = originalBtnContent;
  }

  // Show success feedback
  document.getElementById('registeredEmailDisplay').textContent = email;
  document.getElementById('submitSuccessToast').style.display = 'flex';
  document.getElementById('testerForm').style.display = 'none';

  // Automatically transition to Download tab
  setTimeout(() => {
    switchHubTab('download');
    const card = document.querySelector('.apk-card');
    if (card) {
      card.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }, 900);
}
