const API = 'api.php';
let isLoggedIn = false;

async function loadDepots() {
  const res = await fetch(`${API}?module=depots&action=list`);
  return res.json();
}

async function loadStocks() {
  const res = await fetch(`${API}?module=stocks&action=overview`);
  return res.json();
}

async function loadAlerts() {
  const res = await fetch(`${API}?module=stocks&action=alerts`);
  return res.json();
}

async function loadTransfers() {
  const res = await fetch(`${API}?module=transferts&action=list`);
  return res.json();
}

async function checkAuth() {
  const res = await fetch(`${API}?module=auth&action=check`);
  return res.json();
}

function renderStockTable(stocks) {
  const tbody = document.querySelector('#stockTable tbody');
  tbody.innerHTML = stocks.map(s => `
    <tr>
      <td>${s.depot_nom}</td>
      <td>${s.reference}</td>
      <td>${s.produit_nom}</td>
      <td>${s.categorie ?? '—'}</td>
      <td class="${s.quantite <= s.seuil_alerte ? 'low-stock' : ''}">${s.quantite}</td>
    </tr>
  `).join('');
}

function renderDepotTotals(stocks, depots) {
  depots.forEach(d => {
    const total = stocks
      .filter(s => s.depot_id == d.id)
      .reduce((sum, s) => sum + parseInt(s.quantite), 0);
    const el = document.getElementById(`val-${d.id}`);
    if (el) el.textContent = total.toLocaleString('fr-FR');
  });
}

function renderAlerts(alerts) {
  const banner = document.getElementById('alertsBanner');
  const summary = document.getElementById('alertsSummary');
  const list = document.getElementById('alertsList');

  if (!alerts.length) {
    banner.hidden = true;
    return;
  }

  banner.hidden = false;
  summary.textContent = alerts.length === 1
    ? '1 produit en stock bas'
    : `${alerts.length} produits en stock bas`;

  list.innerHTML = alerts.map(a => `
    <li>${a.depot_nom} — ${a.reference} (${a.produit_nom}) : ${a.quantite} restant, seuil ${a.seuil_alerte}</li>
  `).join('');
}

function renderTransferTable(transfers) {
  const tbody = document.querySelector('#transferTable tbody');
  tbody.innerHTML = transfers.map(t => `
    <tr>
      <td>${new Date(t.date_transfert).toLocaleString('fr-FR')}</td>
      <td>${t.produit}</td>
      <td>${t.source}</td>
      <td>${t.destination}</td>
      <td>${t.quantite}</td>
      <td>${t.statut}</td>
    </tr>
  `).join('');
}

function populateSelects(depots, stocks) {
  const produitSelect = document.getElementById('produitSelect');
  const sourceSelect = document.getElementById('sourceSelect');
  const destSelect = document.getElementById('destSelect');

  const uniqueProducts = [...new Map(stocks.map(s => [s.produit_id, s])).values()];
  produitSelect.innerHTML = uniqueProducts.map(p =>
    `<option value="${p.produit_id}">${p.reference} — ${p.produit_nom}</option>`).join('');

  const depotOptions = depots.map(d => `<option value="${d.id}">${d.nom}</option>`).join('');
  sourceSelect.innerHTML = depotOptions;
  destSelect.innerHTML = depotOptions;
}

function applyAuthState(loggedIn, username) {
  isLoggedIn = loggedIn;

  const loginBtn = document.getElementById('loginBtn');
  const loggedInBox = document.getElementById('authLoggedIn');
  const usernameEl = document.getElementById('authUsername');
  const transferForm = document.getElementById('transferForm');
  const authRequiredMsg = document.getElementById('authRequiredMsg');
  const exportBtn = document.getElementById('exportBtn');

  if (loggedIn) {
    loginBtn.hidden = true;
    loggedInBox.hidden = false;
    usernameEl.textContent = username;
    transferForm.hidden = false;
    authRequiredMsg.hidden = true;
    exportBtn.style.opacity = '1';
    exportBtn.style.pointerEvents = 'auto';
    exportBtn.title = '';
  } else {
    loginBtn.hidden = false;
    loggedInBox.hidden = true;
    transferForm.hidden = true;
    authRequiredMsg.hidden = false;
    exportBtn.style.opacity = '0.4';
    exportBtn.style.pointerEvents = 'none';
    exportBtn.title = 'Connectez-vous pour exporter';
  }
}

async function refreshAll() {
  const [depots, stocks, transfers, alerts] = await Promise.all([
    loadDepots(), loadStocks(), loadTransfers(), loadAlerts()
  ]);
  renderStockTable(stocks);
  renderDepotTotals(stocks, depots);
  renderTransferTable(transfers);
  renderAlerts(alerts);
  populateSelects(depots, stocks);
}

// --- Auth wiring ---
document.getElementById('loginBtn').addEventListener('click', () => {
  document.getElementById('loginModal').hidden = false;
});

document.getElementById('loginCancel').addEventListener('click', () => {
  document.getElementById('loginModal').hidden = true;
});

document.getElementById('loginForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const msg = document.getElementById('loginMsg');
  msg.textContent = '';
  msg.className = 'form-msg';

  const username = document.getElementById('loginUsername').value;
  const password = document.getElementById('loginPassword').value;

  try {
    const res = await fetch(`${API}?module=auth&action=login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Erreur de connexion');

    // Apply auth state and hide modal
    applyAuthState(true, data.username);
    document.getElementById('loginModal').hidden = true;
    document.getElementById('loginForm').reset();
    
    // Refresh data after login
    refreshAll();
  } catch (err) {
    msg.textContent = err.message;
    msg.classList.add('error');
  }
});

document.getElementById('logoutBtn').addEventListener('click', async () => {
  await fetch(`${API}?module=auth&action=logout`);
  applyAuthState(false, null);
});

// --- Transfer form ---
document.getElementById('transferForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const msg = document.getElementById('formMsg');
  msg.textContent = '';
  msg.className = 'form-msg';

  const payload = {
    produit_id: document.getElementById('produitSelect').value,
    depot_source: document.getElementById('sourceSelect').value,
    depot_dest: document.getElementById('destSelect').value,
    quantite: document.getElementById('qteInput').value
  };

  try {
    const res = await fetch(`${API}?module=transferts&action=create`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Erreur inconnue');

    msg.textContent = 'Transfert effectue avec succes.';
    msg.classList.add('success');
    e.target.reset();
    refreshAll();
  } catch (err) {
    msg.textContent = err.message;
    msg.classList.add('error');
  }
});

// --- Init ---
(async () => {
  const auth = await checkAuth();
  applyAuthState(auth.logged_in, auth.username);
  await refreshAll();
})();
