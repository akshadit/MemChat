/**
 * MemChat Tester Hub — Frontend Logic & Serverless Dispatch
 */

const STORAGE_KEY = 'memchat_beta_testers';
const WEBHOOK_KEY = 'memchat_google_sheet_webhook';
const DEVELOPER_EMAIL = 'akshayaditya1976@gmail.com';

// Initialize default developer account if empty
function getStoredTesters() {
  const data = localStorage.getItem(STORAGE_KEY);
  if (!data) {
    const initial = [
      {
        id: '1',
        name: 'Akshay Aditya (Developer)',
        email: DEVELOPER_EMAIL,
        device: 'Xiaomi / POCO (Android 16)',
        role: 'Personal & Family Files',
        timestamp: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
        status: 'Approved in Cloud'
      }
    ];
    localStorage.setItem(STORAGE_KEY, JSON.stringify(initial));
    return initial;
  }
  try {
    return JSON.parse(data);
  } catch (e) {
    return [];
  }
}

function saveTesters(testers) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(testers));
}

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

// Form Submission with Instant Email Alert & Cloud Webhook
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

  const testers = getStoredTesters();
  
  // Check if already registered
  const existing = testers.find(t => t.email === email);
  if (existing) {
    document.getElementById('registeredEmailDisplay').textContent = email;
    document.getElementById('submitSuccessToast').style.display = 'flex';
    document.getElementById('testerForm').style.display = 'none';
    switchHubTab('download');
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

  const newTester = {
    id: Date.now().toString(),
    name,
    email,
    device,
    role,
    timestamp,
    status: 'Pending Google Cloud'
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
      <span>Submitting & Notifying Developer...</span>
    `;
  }

  // 1. Prepare Email Payload for Developer (FormSubmit AJAX)
  const emailPayload = {
    name: name,
    email: email,
    device: device,
    use_case: role,
    registered_at: timestamp,
    _subject: `🚀 [MemChat Beta] New Tester Registration: ${email}`,
    _template: 'table',
    _captcha: 'false'
  };

  // Dispatch Email Notification in background
  const emailPromise = fetch(`https://formsubmit.co/ajax/${DEVELOPER_EMAIL}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    body: JSON.stringify(emailPayload)
  }).catch(err => {
    console.warn('FormSubmit email alert caught:', err);
  });

  // 2. Dispatch to Google Sheets Webhook (if developer configured it)
  const webhookUrl = localStorage.getItem(WEBHOOK_KEY);
  if (webhookUrl) {
    fetch(webhookUrl, {
      method: 'POST',
      mode: 'no-cors',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(newTester)
    }).catch(err => console.warn('Google Sheet webhook caught:', err));
  }

  // 3. Save locally in client storage
  testers.unshift(newTester);
  saveTesters(testers);

  // Wait max 1.8 seconds for email dispatch to complete so user experience is snappy
  await Promise.race([
    emailPromise,
    new Promise(resolve => setTimeout(resolve, 1800))
  ]);

  // Restore button state & show success toast
  if (submitBtn) {
    submitBtn.disabled = false;
    submitBtn.innerHTML = originalBtnContent;
  }

  document.getElementById('registeredEmailDisplay').textContent = email;
  document.getElementById('submitSuccessToast').style.display = 'flex';
  document.getElementById('testerForm').style.display = 'none';

  // Automatically switch to download tab after brief delay
  setTimeout(() => {
    switchHubTab('download');
    // Scroll smoothly to download card
    const card = document.querySelector('.apk-card');
    if (card) {
      card.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }, 1000);
}

// Utility Escaper
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text || '';
  return div.innerHTML;
}
