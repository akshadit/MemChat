/**
 * MemChat Tester Hub — Logic & State Management
 */

const STORAGE_KEY = 'memchat_beta_testers';

// Initialize with default developer account if empty
function getStoredTesters() {
  const data = localStorage.getItem(STORAGE_KEY);
  if (!data) {
    const initial = [
      {
        id: '1',
        name: 'Akshay Aditya (Developer)',
        email: 'akshayaditya1976@gmail.com',
        device: 'Xiaomi / POCO (Android 16)',
        role: 'Personal & Family Files',
        timestamp: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
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
  updateTesterCount();
}

function updateTesterCount() {
  const testers = getStoredTesters();
  const countBadge = document.getElementById('testerCountBadge');
  if (countBadge) {
    countBadge.textContent = `Testers (${testers.length})`;
  }
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

// Form Submission
function handleTesterSubmit(e) {
  e.preventDefault();

  const name = document.getElementById('testerName').value.trim();
  const email = document.getElementById('testerEmail').value.trim().toLowerCase();
  const device = document.getElementById('testerDevice').value.trim() || 'Android Device';
  const role = document.getElementById('testerRole').value;

  if (!email.includes('@')) {
    alert('Please enter a valid Gmail address.');
    return;
  }

  const testers = getStoredTesters();
  
  // Check if already registered
  const existing = testers.find(t => t.email === email);
  if (existing) {
    alert(`This Gmail (${email}) is already registered! Proceeding to download.`);
    document.getElementById('registeredEmailDisplay').textContent = email;
    document.getElementById('submitSuccessToast').style.display = 'flex';
    document.getElementById('testerForm').style.display = 'none';
    return;
  }

  const newTester = {
    id: Date.now().toString(),
    name,
    email,
    device,
    role,
    timestamp: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
  };

  testers.unshift(newTester);
  saveTesters(testers);

  // Show success and transition
  document.getElementById('registeredEmailDisplay').textContent = email;
  document.getElementById('submitSuccessToast').style.display = 'flex';
  document.getElementById('testerForm').style.display = 'none';
}

// Admin Modal
function openAdminModal() {
  renderTestersTable();
  document.getElementById('adminModal').style.display = 'flex';
}

function closeAdminModal() {
  document.getElementById('adminModal').style.display = 'none';
}

function renderTestersTable() {
  const testers = getStoredTesters();
  const tbody = document.getElementById('testersTableBody');
  const noTesters = document.getElementById('noTestersNotice');

  tbody.innerHTML = '';

  if (testers.length === 0) {
    noTesters.style.display = 'block';
    return;
  }

  noTesters.style.display = 'none';

  testers.forEach((t) => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td><strong>${escapeHtml(t.name)}</strong></td>
      <td><code style="color: #25D366">${escapeHtml(t.email)}</code></td>
      <td>${escapeHtml(t.device)}</td>
      <td>${escapeHtml(t.role)}</td>
      <td>${escapeHtml(t.timestamp)}</td>
    `;
    tbody.appendChild(tr);
  });
}

function copyAllEmails() {
  const testers = getStoredTesters();
  if (testers.length === 0) {
    alert('No tester emails to copy.');
    return;
  }

  const emails = testers.map(t => t.email).join(', ');
  navigator.clipboard.writeText(emails).then(() => {
    const btn = document.getElementById('copyAllEmailsBtn');
    const originalText = btn.innerHTML;
    btn.innerHTML = '✓ Copied to Clipboard!';
    btn.style.backgroundColor = '#25D366';
    setTimeout(() => {
      btn.innerHTML = originalText;
      btn.style.backgroundColor = '';
    }, 2500);
  }).catch(() => {
    prompt('Copy these emails:', emails);
  });
}

function exportTestersCSV() {
  const testers = getStoredTesters();
  if (testers.length === 0) {
    alert('No testers to export.');
    return;
  }

  let csv = 'Name,Gmail,Device,Use Case,Registration Date\n';
  testers.forEach(t => {
    csv += `"${t.name}","${t.email}","${t.device}","${t.role}","${t.timestamp}"\n`;
  });

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `memchat_beta_testers_${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

function clearTestersList() {
  if (confirm('Are you sure you want to clear all registered testers?')) {
    localStorage.removeItem(STORAGE_KEY);
    updateTesterCount();
    renderTestersTable();
  }
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text || '';
  return div.innerHTML;
}

// Event Listeners
document.addEventListener('DOMContentLoaded', () => {
  updateTesterCount();

  const adminBtn = document.getElementById('adminToggleBtn');
  if (adminBtn) {
    adminBtn.addEventListener('click', openAdminModal);
  }

  // Close modal when clicking outside
  const modal = document.getElementById('adminModal');
  if (modal) {
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        closeAdminModal();
      }
    });
  }
});
