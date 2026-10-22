/**
 * MemChat Developer Admin Portal — Logic & Integrations
 */

const STORAGE_KEY = 'memchat_beta_testers';
const AUTH_KEY = 'memchat_admin_authenticated';
const PASS_KEY = 'memchat_admin_pass';
const WEBHOOK_KEY = 'memchat_google_sheet_webhook';
const DEFAULT_PASS = 'memchat2026';
const DEVELOPER_EMAIL = 'akshayaditya1976@gmail.com';

let currentFilter = 'all';
let currentSearch = '';

// Check Auth on Page Load
document.addEventListener('DOMContentLoaded', () => {
  const isAuth = sessionStorage.getItem(AUTH_KEY) === 'true';
  if (isAuth) {
    showDashboard();
  } else {
    showAuthGate();
  }

  // Load saved webhook URL in settings if exists
  const savedWebhook = localStorage.getItem(WEBHOOK_KEY);
  if (savedWebhook) {
    const input = document.getElementById('webhookUrlInput');
    if (input) input.value = savedWebhook;
    updateSyncBadge(true);
  }
});

// Authentication Handling
function handleAdminLogin(e) {
  e.preventDefault();
  const input = document.getElementById('adminPassInput').value;
  const currentPass = localStorage.getItem(PASS_KEY) || DEFAULT_PASS;
  const errorMsg = document.getElementById('authErrorMsg');
  const card = document.querySelector('.auth-card');

  if (input === currentPass) {
    sessionStorage.setItem(AUTH_KEY, 'true');
    errorMsg.style.display = 'none';
    showDashboard();
    showToast('Unlocked Developer Admin Portal');
  } else {
    errorMsg.style.display = 'flex';
    card.classList.remove('shake');
    void card.offsetWidth; // Force reflow
    card.classList.add('shake');
    document.getElementById('adminPassInput').focus();
  }
}

function adminLogout() {
  sessionStorage.removeItem(AUTH_KEY);
  showAuthGate();
  showToast('Admin Portal Locked');
}

function showAuthGate() {
  document.getElementById('authGateView').style.display = 'flex';
  document.getElementById('adminDashboardView').style.display = 'none';
  document.getElementById('logoutBtn').style.display = 'none';
  const passInput = document.getElementById('adminPassInput');
  if (passInput) {
    passInput.value = '';
    passInput.focus();
  }
}

function showDashboard() {
  document.getElementById('authGateView').style.display = 'none';
  document.getElementById('adminDashboardView').style.display = 'block';
  document.getElementById('logoutBtn').style.display = 'inline-flex';
  renderDashboard();
}

function togglePassVisibility() {
  const input = document.getElementById('adminPassInput');
  input.type = input.type === 'password' ? 'text' : 'password';
}

// Data Store Helpers
function getTesters() {
  const data = localStorage.getItem(STORAGE_KEY);
  if (!data) {
    // Default initial developer registration
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
    const parsed = JSON.parse(data);
    // Ensure each tester has a status field
    return parsed.map(t => ({
      ...t,
      status: t.status || 'Pending Google Cloud'
    }));
  } catch (e) {
    return [];
  }
}

function saveTesters(testers) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(testers));
  renderDashboard();
}

// Render Dashboard & Metrics
function renderDashboard() {
  const testers = getTesters();
  
  // Metrics
  const total = testers.length;
  const pending = testers.filter(t => t.status === 'Pending Google Cloud').length;
  const approved = testers.filter(t => t.status === 'Approved in Cloud').length;

  document.getElementById('metricTotal').textContent = total;
  document.getElementById('metricPending').textContent = pending;
  document.getElementById('metricApproved').textContent = approved;
  document.getElementById('copyPendingText').textContent = `Copy ${pending} Pending Gmails`;

  // Render Table Rows with filters
  const tbody = document.getElementById('adminTableBody');
  const emptyState = document.getElementById('tableEmptyState');
  tbody.innerHTML = '';

  let filtered = testers.filter(t => {
    // Status Filter
    if (currentFilter === 'pending' && t.status !== 'Pending Google Cloud') return false;
    if (currentFilter === 'approved' && t.status !== 'Approved in Cloud') return false;

    // Search Query
    if (currentSearch) {
      const q = currentSearch.toLowerCase();
      const matchName = (t.name || '').toLowerCase().includes(q);
      const matchEmail = (t.email || '').toLowerCase().includes(q);
      const matchDevice = (t.device || '').toLowerCase().includes(q);
      const matchRole = (t.role || '').toLowerCase().includes(q);
      return matchName || matchEmail || matchDevice || matchRole;
    }
    return true;
  });

  document.getElementById('tableCountDisplay').textContent = filtered.length;

  if (filtered.length === 0) {
    emptyState.style.display = 'block';
    return;
  }

  emptyState.style.display = 'none';

  filtered.forEach(t => {
    const tr = document.createElement('tr');
    const isPending = t.status === 'Pending Google Cloud';
    const badgeClass = isPending ? 'status-pending' : 'status-approved';
    const badgeText = isPending ? 'Pending Cloud Setup' : 'Approved in Cloud';

    tr.innerHTML = `
      <td><strong>${escapeHtml(t.name)}</strong></td>
      <td>
        <span class="email-cell">
          ${escapeHtml(t.email)}
          <button class="copy-mini-btn" title="Copy email" onclick="copySingleEmail('${escapeHtml(t.email)}')">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
          </button>
        </span>
      </td>
      <td>${escapeHtml(t.device || 'Android Device')}</td>
      <td>${escapeHtml(t.role || 'General')}</td>
      <td style="color: var(--text-secondary); font-size: 0.85rem;">${escapeHtml(t.timestamp)}</td>
      <td>
        <span class="badge-status ${badgeClass}" onclick="toggleTesterStatus('${t.id}')" title="Click to toggle status">
          <span class="badge-dot"></span>
          ${badgeText}
        </span>
      </td>
      <td style="text-align: right;">
        <div class="row-actions" style="justify-content: flex-end;">
          <button class="btn-icon-danger" title="Remove tester" onclick="deleteTester('${t.id}')">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
          </button>
        </div>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

// Quick Actions
function toggleTesterStatus(id) {
  const testers = getTesters();
  const index = testers.findIndex(t => t.id === id);
  if (index !== -1) {
    testers[index].status = testers[index].status === 'Pending Google Cloud' ? 'Approved in Cloud' : 'Pending Google Cloud';
    saveTesters(testers);
    showToast(`Updated status for ${testers[index].email}`);
  }
}

function markAllAsApproved() {
  const testers = getTesters();
  let count = 0;
  testers.forEach(t => {
    if (t.status === 'Pending Google Cloud') {
      t.status = 'Approved in Cloud';
      count++;
    }
  });

  if (count === 0) {
    showToast('No pending testers to approve');
    return;
  }

  saveTesters(testers);
  showToast(`Marked ${count} tester(s) as Approved in Google Cloud`);
}

function deleteTester(id) {
  const testers = getTesters();
  const tester = testers.find(t => t.id === id);
  if (!tester) return;

  if (confirm(`Remove ${tester.name} (${tester.email}) from registered testers?`)) {
    const updated = testers.filter(t => t.id !== id);
    saveTesters(updated);
    showToast(`Removed ${tester.email}`);
  }
}

// Copy Handlers
function copySingleEmail(email) {
  navigator.clipboard.writeText(email).then(() => {
    showToast(`Copied ${email}`);
  });
}

function copyPendingEmails() {
  const testers = getTesters();
  const pending = testers.filter(t => t.status === 'Pending Google Cloud');
  
  if (pending.length === 0) {
    showToast('All registered testers are already approved!');
    return;
  }

  const emailList = pending.map(t => t.email).join(', ');
  navigator.clipboard.writeText(emailList).then(() => {
    showToast(`Copied ${pending.length} pending emails for Google Cloud!`);
  }).catch(() => {
    prompt('Copy pending emails for Google Cloud:', emailList);
  });
}

// Search and Filter
function handleSearch() {
  currentSearch = document.getElementById('adminSearchInput').value.trim();
  renderDashboard();
}

function handleFilterChange() {
  currentFilter = document.getElementById('adminStatusFilter').value;
  renderDashboard();
}

// Export CSV
function exportTestersCSV() {
  const testers = getTesters();
  if (testers.length === 0) {
    showToast('No testers to export');
    return;
  }

  let csv = 'ID,Name,Gmail Address,Device Model,Primary Use Case,Registration Date,Google Cloud Status\n';
  testers.forEach(t => {
    csv += `"${t.id}","${escapeCsv(t.name)}","${escapeCsv(t.email)}","${escapeCsv(t.device)}","${escapeCsv(t.role)}","${escapeCsv(t.timestamp)}","${escapeCsv(t.status)}"\n`;
  });

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `memchat_beta_testers_${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
  showToast('Downloaded CSV export');
}

// Manual Add Tester
function openAddTesterModal() {
  document.getElementById('addTesterModal').style.display = 'flex';
  document.getElementById('manualName').focus();
}

function closeAddTesterModal() {
  document.getElementById('addTesterModal').style.display = 'none';
  document.getElementById('manualAddForm').reset();
}

function handleManualAdd(e) {
  e.preventDefault();
  const name = document.getElementById('manualName').value.trim();
  const email = document.getElementById('manualEmail').value.trim().toLowerCase();
  const device = document.getElementById('manualDevice').value.trim() || 'Android Device';
  const role = document.getElementById('manualRole').value;

  const testers = getTesters();
  if (testers.some(t => t.email === email)) {
    alert(`The email ${email} is already in the registry.`);
    return;
  }

  const newTester = {
    id: Date.now().toString(),
    name,
    email,
    device,
    role,
    timestamp: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
    status: 'Pending Google Cloud'
  };

  testers.unshift(newTester);
  saveTesters(testers);
  closeAddTesterModal();
  showToast(`Added ${email} to registry`);
}

// Settings Modal & Integrations
function openSettingsModal() {
  document.getElementById('settingsModal').style.display = 'flex';
}

function closeSettingsModal() {
  document.getElementById('settingsModal').style.display = 'none';
}

function saveWebhookUrl() {
  const url = document.getElementById('webhookUrlInput').value.trim();
  if (url && !url.startsWith('https://script.google.com/')) {
    alert('Please enter a valid Google Apps Script Web App URL starting with https://script.google.com/');
    return;
  }

  if (url) {
    localStorage.setItem(WEBHOOK_KEY, url);
    updateSyncBadge(true);
    showToast('Saved Google Sheet Webhook URL!');
  } else {
    localStorage.removeItem(WEBHOOK_KEY);
    updateSyncBadge(false);
    showToast('Cleared Webhook URL (Local Only)');
  }
  closeSettingsModal();
}

function updateSyncBadge(isConnected) {
  const syncLabel = document.getElementById('metricSyncStatus');
  if (syncLabel) {
    syncLabel.textContent = isConnected ? 'Google Sheet & Gmail Connected' : 'Instant Gmail Alerts';
  }
}

function syncGoogleSheet() {
  const webhookUrl = localStorage.getItem(WEBHOOK_KEY);
  if (!webhookUrl) {
    alert('No Google Sheet Webhook URL configured. Click "Settings" to link your Google Sheet.');
    openSettingsModal();
    return;
  }

  showToast('Connecting to Google Sheet...');

  fetch(webhookUrl)
    .then(res => res.json())
    .then(data => {
      if (data && data.success && Array.isArray(data.testers)) {
        const localTesters = getTesters();
        const mergedMap = new Map();

        // Load existing local testers
        localTesters.forEach(t => mergedMap.set(t.email.toLowerCase(), t));

        // Merge from Google Sheet
        data.testers.forEach(sheetTester => {
          const key = sheetTester.email.toLowerCase();
          if (mergedMap.has(key)) {
            // Keep local status if newer or already modified
            mergedMap.set(key, { ...sheetTester, ...mergedMap.get(key) });
          } else {
            mergedMap.set(key, sheetTester);
          }
        });

        const mergedList = Array.from(mergedMap.values());
        saveTesters(mergedList);
        showToast(`Synced ${mergedList.length} testers from Google Sheet!`);
      } else {
        showToast('Google Sheet responded, but returned no tester array.');
      }
    })
    .catch(err => {
      console.error(err);
      alert('Could not sync with Google Sheet. Make sure your Apps Script Web App is deployed with access set to "Anyone".');
    });
}

function sendTestEmail() {
  showToast('Dispatching test email to your Gmail...');
  const payload = {
    name: 'Akshay Aditya (Test)',
    email: DEVELOPER_EMAIL,
    device: 'Admin Console Test',
    role: 'System Test',
    timestamp: new Date().toLocaleString(),
    _subject: '🔔 [MemChat] Test Notification Alert',
    _template: 'table',
    _captcha: 'false'
  };

  fetch(`https://formsubmit.co/ajax/${DEVELOPER_EMAIL}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    body: JSON.stringify(payload)
  })
  .then(res => res.json())
  .then(() => {
    showToast(`Test email sent! Check inbox at ${DEVELOPER_EMAIL}`);
  })
  .catch(err => {
    console.error(err);
    alert('Error dispatching test email. Please check internet connection.');
  });
}

function changeAdminPasscode() {
  const newPass = document.getElementById('newPasscodeInput').value.trim();
  if (newPass.length < 4) {
    alert('Passcode must be at least 4 characters long.');
    return;
  }

  localStorage.setItem(PASS_KEY, newPass);
  document.getElementById('newPasscodeInput').value = '';
  showToast('Developer passcode updated successfully!');
  closeSettingsModal();
}

// Toast Helper
function showToast(message) {
  const toast = document.getElementById('adminToast');
  const toastMsg = document.getElementById('adminToastMessage');
  if (!toast || !toastMsg) return;

  toastMsg.textContent = message;
  toast.style.display = 'flex';

  if (window._toastTimeout) clearTimeout(window._toastTimeout);
  window._toastTimeout = setTimeout(() => {
    toast.style.display = 'none';
  }, 3000);
}

// Utility Escapers
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text || '';
  return div.innerHTML;
}

function escapeCsv(text) {
  return (text || '').replace(/"/g, '""');
}

// Close modals when clicking outside
window.addEventListener('click', (e) => {
  const addModal = document.getElementById('addTesterModal');
  const setModal = document.getElementById('settingsModal');
  if (e.target === addModal) closeAddTesterModal();
  if (e.target === setModal) closeSettingsModal();
});
