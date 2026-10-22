/**
 * MemChat Tester Hub — Frontend Logic
 * Sends registration to Google Sheets webhook and dispatches email alert to developer.
 * Includes Thank You Popup from Akshayaditya K R and celebratory confetti.
 */

// ============================================================================
// CONFIGURATION (DO NOT MODIFY UNLESS DEPLOYING NEW WEBHOOK)
// ============================================================================
const GOOGLE_SHEET_WEBHOOK_URL = 'https://script.google.com/macros/s/AKfycbwJdOlR-2Us1zgSb-UJfZuVqywFNNHJvDzd8_IdNBCux073VF1w3Hx3nJYgIw7_SUKd/exec';
const DEVELOPER_EMAIL = 'akshayaditya1976@gmail.com';
// ============================================================================

// Hub Tab Switching
function switchHubTab(tab) {
  const tabRegister = document.getElementById('tabRegister');
  const tabDownload = document.getElementById('tabDownload');
  const viewRegister = document.getElementById('hubRegisterView');
  const viewDownload = document.getElementById('hubDownloadView');

  if (!tabRegister || !tabDownload || !viewRegister || !viewDownload) return;

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

  // 1. Send to Google Sheets Webhook
  if (GOOGLE_SHEET_WEBHOOK_URL) {
    promises.push(
      fetch(GOOGLE_SHEET_WEBHOOK_URL, {
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

  // Wait max 1.5 seconds so tester is never blocked
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
  }, 800);
}

// APK Download Handler & Thank You Modal Trigger
function handleApkDownload(e) {
  // Let the native browser download proceed naturally via the href/download attribute
  setTimeout(() => {
    openThankYouModal();
  }, 400);
}

function openThankYouModal() {
  const modal = document.getElementById('thankYouModal');
  if (modal) {
    modal.style.display = 'flex';
    fireConfetti();
  }
}

function closeThankYouModal() {
  const modal = document.getElementById('thankYouModal');
  if (modal) {
    modal.style.display = 'none';
  }
}

// Close modal when clicking outside of the card
window.addEventListener('click', (e) => {
  const modal = document.getElementById('thankYouModal');
  if (e.target === modal) {
    closeThankYouModal();
  }
});

// ESC key to close modal
window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    closeThankYouModal();
  }
});

// Celebratory Confetti System
function fireConfetti() {
  const canvas = document.getElementById('confettiCanvas');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;

  const colors = ['#00F298', '#00A884', '#25D366', '#38BDF8', '#F59E0B', '#FFFFFF'];
  const confettiCount = 80;
  const confetti = [];

  for (let i = 0; i < confettiCount; i++) {
    confetti.push({
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height * 0.4 - canvas.height * 0.2,
      w: Math.random() * 8 + 5,
      h: Math.random() * 6 + 4,
      color: colors[Math.floor(Math.random() * colors.length)],
      vy: Math.random() * 3 + 2,
      vx: (Math.random() - 0.5) * 3,
      rotation: Math.random() * 360,
      vRot: (Math.random() - 0.5) * 8,
      opacity: 1
    });
  }

  let animationFrame;
  let startTime = Date.now();

  function render() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    const elapsed = Date.now() - startTime;

    let activeParticles = 0;
    confetti.forEach(p => {
      p.y += p.vy;
      p.x += p.vx;
      p.rotation += p.vRot;

      if (elapsed > 2000) {
        p.opacity = Math.max(0, p.opacity - 0.02);
      }

      if (p.opacity > 0 && p.y < canvas.height + 20) {
        activeParticles++;
        ctx.save();
        ctx.translate(p.x, p.y);
        ctx.rotate((p.rotation * Math.PI) / 180);
        ctx.fillStyle = p.color;
        ctx.globalAlpha = p.opacity;
        ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
        ctx.restore();
      }
    });

    if (activeParticles > 0 && elapsed < 4500) {
      animationFrame = requestAnimationFrame(render);
    } else {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      cancelAnimationFrame(animationFrame);
    }
  }

  render();
}
