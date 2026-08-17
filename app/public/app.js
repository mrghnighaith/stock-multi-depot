const API = 'api.php';

async function loadDepots() {
  const res = await fetch(`${API}?module=depots&action=list`);
  return res.json();
}

async function loadStocks() {
  const res = await fetch(`${API}?module=stocks&action=overview`);
  return res.json();
}

async function loadTransfers() {
  const res = await fetch(`${API}?module=transferts&action=list`);
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

async function refreshAll() {
  const [depots, stocks, transfers] = await Promise.all([loadDepots(), loadStocks(), loadTransfers()]);
  renderStockTable(stocks);
  renderDepotTotals(stocks, depots);
  renderTransferTable(transfers);
  populateSelects(depots, stocks);
}

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

refreshAll();
