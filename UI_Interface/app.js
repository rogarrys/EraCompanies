/* ══════════════════════════════════════════
   EraCompanies — UI Application
   Single-file SPA: router, sidebar, 7 tabs, modals, toasts, Lua bridge
   ══════════════════════════════════════════ */

// ─── State ───
let S = {};          // Server state
let currentTab = ''; // Current active tab
let clientSettings = { notifSound: true, reduceAnimations: false };
let threadData = null; // Currently viewed thread

const $ = (id) => document.getElementById(id);
const esc = (str) => {
    const d = document.createElement('div');
    d.textContent = str || '';
    return d.innerHTML;
};
const asArray = (v) => {
    if (!v) return [];
    if (Array.isArray(v)) return v;
    return Object.values(v);
};
const attr = (v) => JSON.stringify(v || '').replace(/"/g, '&quot;');

// ─── Icons (inline SVG) ───
const ICONS = {
    home: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>',
    list: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" rx="2" width="7" height="7"/><rect x="14" y="3" rx="2" width="7" height="7"/><rect x="3" y="14" rx="2" width="7" height="7"/><rect x="14" y="14" rx="2" width="7" height="7"/></svg>',
    mail: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>',
    users: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>',
    shield: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>',
    bank: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>',
    settings: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>',
    inbox: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="22 12 16 12 14 15 10 15 8 12 2 12"/><path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/></svg>',
    send: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>',
    x: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>',
    check: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>',
    plus: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>',
    trash: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>',
    edit: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>',
    arrowUp: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="18 15 12 9 6 15"/></svg>',
    arrowDown: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>',
    arrowLeft: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>',
    userPlus: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/></svg>',
    crown: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M2 20h20L19 8l-5 5-2-7-2 7-5-5z"/></svg>',
};

// ─── Permission labels ───
const PERM_LABELS = {
    invite: 'Inviter des joueurs',
    review_apps: 'Gérer les candidatures',
    msg_access: 'Accéder à la messagerie',
    msg_write: 'Écrire des messages',
    kick: 'Expulser un membre',
    promote: 'Promouvoir un membre',
    demote: 'Rétrograder un membre',
    set_grade: 'Définir le grade',
    edit_grades: 'Gérer les grades',
    bank_deposit: 'Déposer en banque',
    bank_withdraw: 'Retirer de la banque',
    rename_company: 'Renommer l\'entreprise',
};

const ALL_PERMS = Object.keys(PERM_LABELS);

// ═══════════════════════════════════════
// BRIDGE: Lua → JS
// ═══════════════════════════════════════

window.receiveState = function (jsonStr) {
    try {
        S = JSON.parse(jsonStr);
    } catch (e) {
        S = {};
    }
    buildSidebar();
    if (currentTab) renderTab(currentTab);
    else navigateDefault();
};

window.receiveClientSettings = function (obj) {
    clientSettings = obj || clientSettings;
    if (clientSettings.reduceAnimations) document.body.classList.add('reduce-animations');
    else document.body.classList.remove('reduce-animations');
};

window.receiveThreadMessages = function (jsonStr) {
    try {
        threadData = JSON.parse(jsonStr);
    } catch (e) { return; }
    if (currentTab === 'messagerie') renderThreadView();
};

window.showToast = function (msg, isError) {
    const c = document.getElementById('toasts');
    const el = document.createElement('div');
    el.className = 'toast' + (isError ? ' error' : ' success');
    el.textContent = msg;
    c.appendChild(el);
    setTimeout(() => { el.remove(); }, 3500);
};

// ═══════════════════════════════════════
// UTILS
// ═══════════════════════════════════════

function $(id) { return document.getElementById(id); }
// ═══════════════════════════════════════
//   LUA BRIDGE & MOCKING
// ═══════════════════════════════════════

// Detect if we are in a Garry's Mod environment
const IS_GMOD = typeof window.lua !== 'undefined';

// If not in GMod, create a mock lua object for testing
if (!IS_GMOD) {
    console.log("%c [EraCompanies] Running in standalone mode - Hooking mock Lua bridge", "color: #3498db; font-weight: bold;");
    window.lua = {
        createCompany: (name, sector) => {
            console.log(`[MOCK] createCompany: ${name} (${sector})`);
            showToast(`Entreprise "${name}" créée (MOCK)`);
            // Simulate state update after a short delay
            setTimeout(() => {
                window.receiveState(JSON.stringify({
                    ...S,
                    myCompany: { id: 99, name: name, sector: sector, owner_steamid: S.mySteamID, owner_name: S.myName },
                    myGrade: { name: "Patron", permissions: ALL_PERMS },
                    allCompanies: [...(S.allCompanies || []), { id: 99, name: name, sector: sector, owner_name: S.myName, member_count: 1 }]
                }));
            }, 500);
        },
        acceptInvite: (id) => {
            console.log(`[MOCK] acceptInvite: ${id}`);
            showToast(`Invitation acceptée (MOCK)`);
            setTimeout(() => {
                window.receiveState(JSON.stringify({
                    ...S,
                    myCompany: { id: 1, name: "Era Corp", sector: "Technologie", owner_steamid: "76561198000000001", owner_name: "Noah" },
                    myGrade: { name: "Employé", permissions: ["msg_access", "bank_deposit"] },
                    invites: S.invites.filter(inv => inv.id !== id)
                }));
            }, 500);
        },
        declineInvite: (id) => {
            console.log(`[MOCK] declineInvite: ${id}`);
            showToast(`Invitation refusée (MOCK)`);
            setTimeout(() => {
                window.receiveState(JSON.stringify({
                    ...S,
                    invites: S.invites.filter(inv => inv.id !== id)
                }));
            }, 500);
        },
        cancelApplication: (id) => {
            console.log(`[MOCK] cancelApplication: ${id}`);
            showToast(`Candidature annulée (MOCK)`);
            setTimeout(() => {
                window.receiveState(JSON.stringify({
                    ...S,
                    myApplications: S.myApplications.filter(app => app.id !== id)
                }));
            }, 500);
        },
        applyToCompany: (id) => {
            console.log(`[MOCK] applyToCompany: ${id}`);
            showToast(`Candidature envoyée à l'entreprise ${id} (MOCK)`);
            setTimeout(() => {
                window.receiveState(JSON.stringify({
                    ...S,
                    myApplications: [...(S.myApplications || []), { id: Math.floor(Math.random() * 1000), company_id: id, company_name: `Mock Company ${id}`, created_at: Date.now() / 1000 }]
                }));
            }, 500);
        },
        toggleDuty: () => {
            console.log("[MOCK] toggleDuty");
            showToast(`Service ${S.onDuty ? 'désactivé' : 'activé'} (MOCK)`);
            setTimeout(() => {
                window.receiveState(JSON.stringify({
                    ...S,
                    onDuty: !S.onDuty,
                    serviceTimeAccumulated: (S.serviceTimeAccumulated || 0) + (S.onDuty ? 0 : 15 * 60) // Add 15 min if going on duty
                }));
            }, 500);
        },
        closeMenu: () => console.log("[MOCK] closeMenu"),
        getClientSettings: () => {
            console.log("[MOCK] getClientSettings");
            window.receiveClientSettings({ notifSound: true, reduceAnimations: false });
        },
        adminRenameCompany: (id, name) => {
            console.log(`[MOCK] adminRenameCompany: ${id} -> ${name}`);
            showToast(`[ADMIN] Entreprise #${id} renommée en "${name}"`);
            setTimeout(() => {
                window.receiveState(JSON.stringify({
                    ...S,
                    allCompanies: asArray(S.allCompanies).map(c => c.id === id ? { ...c, name: name } : c)
                }));
            }, 500);
        },
        adminDeleteCompany: (id) => {
            console.log(`[MOCK] adminDeleteCompany: ${id}`);
            showToast(`[ADMIN] Entreprise #${id} supprimée`);
            setTimeout(() => {
                window.receiveState(JSON.stringify({
                    ...S,
                    allCompanies: S.allCompanies.filter(c => c.id !== id)
                }));
            }, 500);
        },
        // Add other bridge functions as needed
    };

    // Initialize initial state for standalone preview
    setTimeout(() => {
        if (typeof window.receiveState === 'function') {
            window.receiveState(JSON.stringify({
                myName: "Développeur",
                mySteamID: "76561198000000000",
                isSuperAdmin: true,
                myCompany: null,
                allCompanies: [
                    { id: 1, name: "Era Corp", sector: "Technologie", owner_name: "Noah", member_count: 5 },
                    { id: 2, name: "Los Santos Custom", sector: "Mécano", owner_name: "Franklin", member_count: 2 }
                ],
                invites: [
                    { id: 101, company_id: 1, company_name: "Era Corp", company_sector: "Technologie", inviter_name: "Noah" }
                ],
                myApplications: [
                    { id: 201, company_id: 3, company_name: "Burger Shot", created_at: Date.now() / 1000 - 3600 }
                ],
                config: {
                    Sectors: ["Commerçant", "Mécano", "Restaurateur", "Sécurité", "Transport", "Médical", "Artisan", "Légal", "Autre"]
                }
            }));
        }
    }, 100);
}

function formatDate(ts) {
    if (!ts) return '—';
    const d = new Date(ts * 1000);
    return d.toLocaleDateString('fr-FR') + ' ' + d.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
}
function formatMoney(n) { return '$' + (Number(n) || 0).toLocaleString('fr-FR'); }

function hasPermission(key) {
    if (!S.myCompany) return false;
    if (S.myCompany.owner_steamid === S.mySteamID) return true;
    if (!S.myGrade) return false;
    return (S.myGrade.permissions || []).includes(key);
}

function isOwner() {
    return S.myCompany && S.myCompany.owner_steamid === S.mySteamID;
}

function emptyState(icon, text) {
    return `<div class="empty-state">${ICONS[icon] || ICONS.inbox}<p>${esc(text)}</p></div>`;
}

function showModal(html) {
    $('modal-content').innerHTML = html;
    $('modal-overlay').classList.remove('hidden');
}

function closeModal() {
    $('modal-overlay').classList.add('hidden');
}

// Close modal on overlay click
document.addEventListener('DOMContentLoaded', () => {
    $('modal-overlay').addEventListener('click', (e) => {
        if (e.target === $('modal-overlay')) closeModal();
    });
    // Request settings from Lua
    if (typeof lua !== 'undefined') lua.getClientSettings();
});

// ═══════════════════════════════════════
// SIDEBAR
// ═══════════════════════════════════════

function buildSidebar() {
    const nav = $('sidebar-nav');
    if (!nav) return;
    nav.innerHTML = '';

    const inCompany = !!S.myCompany;
    const onDuty = !!S.onDuty;
    const serviceMin = Math.floor((S.serviceTimeAccumulated || 0) / 60);

    const dutyEl = $('sidebar-duty');
    if (dutyEl) {
        if (inCompany) {
            dutyEl.innerHTML = `
                <div class="duty-toggle-row">
                    <div class="duty-toggle-info">
                        <span class="duty-label">${onDuty ? 'En service' : 'Hors service'}</span>
                        <span class="duty-time">${serviceMin} min accumulées</span>
                    </div>
                    <label class="toggle-switch duty-switch">
                        <input type="checkbox" ${onDuty ? 'checked' : ''} onchange="lua.toggleDuty()"/>
                        <span class="toggle-slider"></span>
                    </label>
                </div>
            `;
            dutyEl.style.display = '';
        } else {
            dutyEl.innerHTML = '';
            dutyEl.style.display = 'none';
        }
    }

    const tabs = [];

    if (!inCompany) {
        tabs.push({ id: 'accueil', label: 'Accueil', icon: 'home', badge: (S.invites || []).length || 0 });
    }

    if (inCompany) {
        tabs.push({ id: 'messagerie', label: 'Messagerie', icon: 'mail', badge: ((S.applications || []).length + (S.threads || []).length) || 0 });
        tabs.push({ id: 'employes', label: 'Employés', icon: 'users' });
        tabs.push({ id: 'grades', label: 'Grades', icon: 'shield' });
        tabs.push({ id: 'banque', label: 'Banque', icon: 'bank' });
    }

    tabs.push({ id: 'liste', label: 'Entreprises', icon: 'list' });
    tabs.push({ id: 'parametres', label: 'Paramètres', icon: 'settings' });

    tabs.forEach(t => {
        const btn = document.createElement('button');
        btn.className = 'nav-item' + (currentTab === t.id ? ' active' : '');
        btn.innerHTML = ICONS[t.icon] + '<span>' + esc(t.label) + '</span>' +
            (t.badge ? '<span class="nav-badge">' + t.badge + '</span>' : '');
        btn.onclick = () => navigateTo(t.id);
        nav.appendChild(btn);
    });
}

function navigateDefault() {
    if (S.myCompany) navigateTo('messagerie');
    else navigateTo('accueil');
}

function navigateTo(tabId) {
    currentTab = tabId;
    threadData = null;
    buildSidebar();
    renderTab(tabId);
}

function renderTab(tabId) {
    const content = $('content');
    switch (tabId) {
        case 'accueil': renderAccueil(content); break;
        case 'liste': renderListe(content); break;
        case 'messagerie': renderMessagerie(content); break;
        case 'employes': renderEmployes(content); break;
        case 'grades': renderGrades(content); break;
        case 'banque': renderBanque(content); break;
        case 'parametres': renderParametres(content); break;
        default: content.innerHTML = emptyState('inbox', 'Onglet inconnu');
    }
}

// ═══════════════════════════════════════
// TAB: ACCUEIL (no company)
// ═══════════════════════════════════════

function renderAccueil(el) {
    const invites = asArray(S.invites);
    const myApps = asArray(S.myApplications);

    let html = `<h1 class="page-title">Bienvenue, ${esc(S.myName || 'Joueur')}</h1>
    <p class="page-subtitle">Créez ou rejoignez une entreprise pour commencer.</p>
    <div class="card-duo">`;

    // Create company
    const sectorOptions = (S.config && S.config.Sectors) || [
        "Commerçant", "Mécano", "Restaurateur", "Sécurité", "Transport", "Médical", "Artisan", "Légal", "Autre"
    ];

    html += `<div class="card">
        <div class="card-title">Créer une entreprise</div>
        
        <div class="form-group mt-16">
            <label class="form-label">Nom de l'entreprise</label>
            <input class="input" id="create-name" type="text" placeholder="3 à 24 caractères" maxlength="24" />
        </div>

        <div class="form-group mt-12">
            <label class="form-label">Secteur d'activité</label>
            <select class="input" id="create-sector">
                ${sectorOptions.map(s => `<option value="${esc(s)}">${esc(s)}</option>`).join('')}
            </select>
        </div>

        <div class="mt-16">
            <button class="btn btn-primary w-full" onclick="doCreateCompany()">Créer l'entreprise</button>
        </div>
    </div>`;

    // Invitations
    html += `<div class="card">
        <div class="card-title">Invitations reçues</div>
        <div class="mt-12">`;

    if (invites.length === 0) {
        html += emptyState('mail', 'Aucune invitation en attente.');
    } else {
        invites.forEach(inv => {
            html += `<div class="list-item">
                <div class="list-item-info">
                    <div class="list-item-title">${esc(inv.company_name)}</div>
                    <div class="list-item-sub">${esc(inv.company_sector || 'Autre')} • Invité par ${esc(inv.inviter_name)}</div>
                </div>
                <div class="btn-group">
                    <button class="btn btn-success btn-sm" onclick="lua.acceptInvite(${inv.id})">Accepter</button>
                    <button class="btn btn-danger btn-sm" onclick="lua.declineInvite(${inv.id})">Refuser</button>
                </div>
            </div>`;
        });
    }
    html += `</div></div></div>`;

    // My applications
    html += `<div class="card mt-16">
        <div class="card-title">Mes candidatures</div>
        <div class="mt-12">`;

    if (myApps.length === 0) {
        html += emptyState('send', 'Aucune candidature envoyée.');
    } else {
        myApps.forEach(app => {
            html += `<div class="list-item">
                <div class="list-item-info">
                    <div class="list-item-title">${esc(app.company_name)}</div>
                    <div class="list-item-sub">${formatDate(app.created_at)}</div>
                </div>
                <button class="btn btn-ghost btn-sm" onclick="lua.cancelApplication(${app.id})">Annuler</button>
            </div>`;
        });
    }
    html += `</div></div>`;

    el.innerHTML = html;
}

function doCreateCompany() {
    const input = $('create-name');
    const sectorInput = $('create-sector');
    if (!input || !sectorInput) return;
    const name = input.value.trim();
    const sector = sectorInput.value;
    if (name.length < 3 || name.length > 24) {
        showToast('Le nom doit contenir entre 3 et 24 caractères.', true);
        return;
    }
    lua.createCompany(name, sector);
}

function doAdminRename(id, oldName) {
    const newName = prompt("Nouveau nom pour l'entreprise :", oldName);
    if (!newName) return;
    const name = newName.trim();
    if (name.length < 3 || name.length > 24) {
        showToast('Le nom doit contenir entre 3 et 24 caractères.', true);
        return;
    }
    lua.adminRenameCompany(id, name);
}

function doAdminDelete(id, name) {
    if (!confirm(`Êtes-vous sûr de vouloir supprimer l'entreprise "${name}" ? Cette action est irréversible.`)) return;
    lua.adminDeleteCompany(id);
}

// ═══════════════════════════════════════
// TAB: LISTE DES ENTREPRISES
// ═══════════════════════════════════════

function renderListe(el) {
    const companies = asArray(S.allCompanies);

    let html = `<h1 class="page-title">Entreprises</h1>
    <p class="page-subtitle">${companies.length} entreprise${companies.length !== 1 ? 's' : ''} enregistrée${companies.length !== 1 ? 's' : ''}</p>`;

    if (companies.length === 0) {
        html += `<div class="card">${emptyState('list', 'Aucune entreprise enregistrée.')}</div>`;
    } else {
        html += `<div class="card-grid">`;
        companies.forEach(c => {
            const isMember = S.myCompany && S.myCompany.id === c.id;
            const alreadyApplied = asArray(S.myApplications).some(a => a.company_id === c.id);
            const inAnyCompany = !!S.myCompany;

            html += `<div class="company-card">
                <div class="company-name">${esc(c.name)}</div>
                <div class="company-meta">
                    <span>${ICONS.crown} ${esc(c.owner_name)}</span>
                    <span>${esc(c.sector || 'Autre')}</span>
                    <span>${ICONS.users} ${c.member_count} membre${c.member_count != 1 ? 's' : ''}</span>
                </div>
                <div class="company-actions">
                    ${S.isSuperAdmin ? `
                        <button class="btn btn-warning btn-sm" onclick="doAdminRename(${c.id}, ${attr(c.name)})">Renommer</button>
                        <button class="btn btn-danger btn-sm" onclick="doAdminDelete(${c.id}, ${attr(c.name)})">Supprimer</button>
                    ` : ''}
                    <button class="btn btn-ghost btn-sm" onclick="openContactModal(${c.id}, ${attr(c.name)})">${ICONS.mail} Contacter</button>`;

            if (isMember) {
                html += `<span class="badge badge-accent">Votre entreprise</span>`;
            } else if (alreadyApplied) {
                html += `<span class="badge badge-muted">Candidature envoyée</span>`;
            } else if (inAnyCompany) {
                html += `<button class="btn btn-primary btn-sm disabled" disabled data-tooltip="Vous êtes déjà dans une entreprise">${ICONS.send} Postuler</button>`;
            } else {
                html += `<button class="btn btn-primary btn-sm" onclick="openApplyModal(${c.id}, ${attr(c.name)})">${ICONS.send} Postuler</button>`;
            }

            html += `</div></div>`;
        });
        html += `</div>`;
    }

    el.innerHTML = html;
}

function openContactModal(companyId, companyName) {
    showModal(`
        <div class="modal-title">Contacter ${esc(companyName)}</div>
        <div class="form-group">
            <label class="form-label">Sujet</label>
            <input class="input" id="contact-subject" placeholder="Objet du message" maxlength="64"/>
        </div>
        <div class="form-group">
            <label class="form-label">Message</label>
            <textarea class="textarea" id="contact-body" placeholder="Votre message..." maxlength="1000"></textarea>
        </div>
        <div class="modal-actions">
            <button class="btn btn-ghost" onclick="closeModal()">Annuler</button>
            <button class="btn btn-primary" onclick="doSendContact(${companyId})">Envoyer</button>
        </div>
    `);
}

function doSendContact(companyId) {
    const subject = $('contact-subject').value.trim();
    const body = $('contact-body').value.trim();
    if (!subject || !body) { showToast('Remplissez tous les champs.', true); return; }
    lua.sendContact(companyId, subject, body);
    closeModal();
}

function openApplyModal(companyId, companyName) {
    const company = asArray(S.allCompanies).find(c => c.id === companyId);
    const form = (company && company.form && asArray(company.form).length > 0) ? asArray(company.form) : null;

    let fields = '';
    if (form) {
        form.forEach((f, i) => {
            fields += `<div class="form-group">
                <label class="form-label">${esc(f.label)}${f.required ? ' *' : ''}</label>
                <input class="input apply-field" data-key="${esc(f.key)}" data-required="${f.required ? '1' : '0'}" placeholder="${esc(f.label)}" maxlength="${f.max || 256}"/>
            </div>`;
        });
    } else {
        fields = `<div class="form-group">
            <label class="form-label">Motivation</label>
            <textarea class="textarea" id="apply-motivation" placeholder="Pourquoi souhaitez-vous rejoindre ?" maxlength="500"></textarea>
        </div>`;
    }

    showModal(`
        <div class="modal-title">Postuler chez ${esc(companyName)}</div>
        ${fields}
        <div class="modal-actions">
            <button class="btn btn-ghost" onclick="closeModal()">Annuler</button>
            <button class="btn btn-primary" onclick="doApply(${companyId})">Envoyer</button>
        </div>
    `);
}

function doApply(companyId) {
    const fields = document.querySelectorAll('.apply-field');
    const payload = {};

    if (fields.length > 0) {
        let valid = true;
        fields.forEach(f => {
            const key = f.getAttribute('data-key');
            const req = f.getAttribute('data-required') === '1';
            const val = f.value.trim();
            if (req && !val) valid = false;
            payload[key] = val;
        });
        if (!valid) { showToast('Remplissez tous les champs obligatoires.', true); return; }
    } else {
        const mot = $('apply-motivation');
        payload.motivation = mot ? mot.value.trim() : '';
        if (!payload.motivation) { showToast('Veuillez écrire une motivation.', true); return; }
    }

    lua.apply(companyId, JSON.stringify(payload));
    closeModal();
}

// ═══════════════════════════════════════
// TAB: MESSAGERIE
// ═══════════════════════════════════════

let msgSubTab = 'recrutement';

function renderMessagerie(el) {
    if (threadData) { renderThreadView(); return; }

    const canReview = hasPermission('review_apps');
    const canRead = hasPermission('msg_access');

    let html = `<h1 class="page-title">Messagerie</h1>
    <p class="page-subtitle">${esc(S.myCompany ? S.myCompany.name : '')}</p>`;

    // Sub-tabs
    html += `<div class="sub-tabs">
        <button class="sub-tab ${msgSubTab === 'recrutement' ? 'active' : ''}" onclick="msgSubTab='recrutement';renderTab('messagerie')">Recrutement${(S.applications || []).length ? ' (' + S.applications.length + ')' : ''}</button>
        <button class="sub-tab ${msgSubTab === 'mails' ? 'active' : ''}" onclick="msgSubTab='mails';renderTab('messagerie')">Mails${(S.threads || []).length ? ' (' + S.threads.length + ')' : ''}</button>
    </div>`;

    if (msgSubTab === 'recrutement') {
        html += renderRecrutement(canReview);
    } else {
        html += renderMails(canRead);
    }

    el.innerHTML = html;
}

function renderRecrutement(canReview) {
    const apps = asArray(S.applications);
    if (!canReview) return `<div class="card">${emptyState('shield', 'Vous n\'avez pas la permission de gérer les candidatures.')}</div>`;
    if (apps.length === 0) return `<div class="card">${emptyState('inbox', 'Aucune candidature en attente.')}</div>`;

    let html = `<div class="card">`;
    apps.forEach(app => {
        const payload = app.payload || {};
        const answers = Object.entries(payload).map(([k, v]) => `<span class="text-sm"><strong>${esc(k)}:</strong> ${esc(v)}</span>`).join('<br/>');

        html += `<div class="list-item" style="flex-direction:column;align-items:stretch;gap:8px;">
            <div class="flex justify-between items-center">
                <div class="list-item-info">
                    <div class="list-item-title">${esc(app.name)}</div>
                    <div class="list-item-sub">${esc(app.steamid)} — ${formatDate(app.created_at)}</div>
                </div>
                <div class="btn-group">
                    <button class="btn btn-success btn-sm" onclick="lua.acceptApplication(${app.id})">Accepter</button>
                    <button class="btn btn-danger btn-sm" onclick="lua.denyApplication(${app.id})">Refuser</button>
                </div>
            </div>
            ${answers ? '<div class="mt-8" style="padding-left:4px;">' + answers + '</div>' : ''}
        </div>`;
    });
    html += `</div>`;
    return html;
}

function renderMails(canRead) {
    if (!canRead) return `<div class="card">${emptyState('shield', 'Vous n\'avez pas la permission d\'accéder à la messagerie.')}</div>`;

    const threads = asArray(S.threads);
    if (threads.length === 0) return `<div class="card">${emptyState('mail', 'Aucun message reçu.')}</div>`;

    let html = `<div class="card" style="padding:0;">`;
    threads.forEach(t => {
        html += `<div class="thread-item" onclick="openThread(${t.id})">
            <div>
                <div class="thread-subject">${esc(t.subject)}</div>
                <div class="thread-meta">De ${esc(t.author_name)} · ${t.msg_count} message${t.msg_count != 1 ? 's' : ''} · ${formatDate(t.updated_at)}</div>
            </div>
            <span class="badge badge-accent">${t.msg_count}</span>
        </div>`;
    });
    html += `</div>`;
    return html;
}

function openThread(threadId) {
    lua.getThread(threadId);
}

function renderThreadView() {
    if (!threadData) return;
    const el = $('content');
    const canWrite = hasPermission('msg_write');

    let html = `<div class="flex items-center gap-12 mb-16">
        <button class="btn-icon" onclick="threadData=null;renderTab('messagerie')">${ICONS.arrowLeft}</button>
        <div>
            <h1 class="page-title" style="margin-bottom:0">${esc(threadData.subject)}</h1>
        </div>
    </div>`;

    asArray(threadData.messages).forEach(m => {
        html += `<div class="message-bubble">
            <div class="message-author">${esc(m.name)}</div>
            <div class="message-body">${esc(m.body)}</div>
            <div class="message-time">${formatDate(m.created_at)}</div>
        </div>`;
    });

    if (canWrite) {
        html += `<div class="mt-16 flex gap-8" style="align-items:flex-end;">
            <textarea class="textarea" id="reply-body" placeholder="Votre réponse..." style="flex:1;min-height:60px;" maxlength="1000"></textarea>
            <button class="btn btn-primary" onclick="doReply(${threadData.threadId})">Envoyer</button>
        </div>`;
    }

    el.innerHTML = html;
}

function doReply(threadId) {
    const b = $('reply-body');
    if (!b || !b.value.trim()) return;
    lua.replyThread(threadId, b.value.trim());
}

// ═══════════════════════════════════════
// TAB: EMPLOYÉS
// ═══════════════════════════════════════

function renderEmployes(el) {
    const members = asArray(S.members);
    const grades = asArray(S.grades);

    let html = `<h1 class="page-title">Employés</h1>
    <p class="page-subtitle">${members.length} membre${members.length !== 1 ? 's' : ''} dans ${esc(S.myCompany ? S.myCompany.name : '')}</p>`;

    if (members.length === 0) {
        html += `<div class="card">${emptyState('users', 'Aucun membre.')}</div>`;
    } else {
        html += `<div class="table-wrap"><table>
            <thead><tr><th>Joueur</th><th>Grade</th><th>Actions</th></tr></thead><tbody>`;

        members.forEach(m => {
            const isMe = m.steamid === S.mySteamID;
            const isTarget = !isMe;
            const myWeight = S.myGrade ? S.myGrade.weight : 0;
            const canAct = isOwner() || (!isMe && myWeight > m.grade_weight);
            const isCompOwner = S.myCompany && S.myCompany.owner_steamid === m.steamid;

            html += `<tr>
                <td>
                    <div class="list-item-title">${esc(m.name)}${isMe ? ' <span class="badge badge-accent">Vous</span>' : ''}${isCompOwner ? ' <span class="badge badge-success">Patron</span>' : ''}</div>
                    <div class="text-sm text-muted">${esc(m.steamid)}</div>
                </td>
                <td><span class="badge badge-muted">${esc(m.grade_name)}</span></td>
                <td>`;

            if (isTarget && canAct && !isCompOwner) {
                if (hasPermission('promote'))
                    html += `<button class="btn btn-sm btn-ghost" onclick="lua.promote('${m.steamid}')" data-tooltip="Promouvoir">${ICONS.arrowUp}</button> `;
                if (hasPermission('demote'))
                    html += `<button class="btn btn-sm btn-ghost" onclick="lua.demote('${m.steamid}')" data-tooltip="Rétrograder">${ICONS.arrowDown}</button> `;
                if (hasPermission('set_grade'))
                    html += `<button class="btn btn-sm btn-ghost" onclick="openSetGradeModal('${m.steamid}', '${esc(m.name)}')" data-tooltip="Changer le grade">${ICONS.shield}</button> `;
                if (hasPermission('kick'))
                    html += `<button class="btn btn-sm btn-danger" onclick="confirmKick('${m.steamid}', '${esc(m.name)}')" data-tooltip="Expulser">${ICONS.x}</button>`;
            } else if (isTarget && isCompOwner && !isOwner()) {
                html += `<span class="text-sm text-muted">—</span>`;
            } else if (isMe) {
                html += `<span class="text-sm text-muted">—</span>`;
            } else {
                html += `<span class="text-sm text-muted">Rang insuffisant</span>`;
            }

            html += `</td></tr>`;
        });

        html += `</tbody></table></div>`;
    }

    el.innerHTML = html;
}

function openSetGradeModal(steamid, name) {
    const grades = asArray(S.grades).filter(g => g.name !== 'Patron');
    let opts = '';
    grades.forEach(g => {
        opts += `<option value="${g.id}">${esc(g.name)} (poids: ${g.weight})</option>`;
    });

    showModal(`
        <div class="modal-title">Changer le grade de ${esc(name)}</div>
        <div class="form-group">
            <label class="form-label">Nouveau grade</label>
            <select class="input" id="grade-select">${opts}</select>
        </div>
        <div class="modal-actions">
            <button class="btn btn-ghost" onclick="closeModal()">Annuler</button>
            <button class="btn btn-primary" onclick="doSetGrade('${steamid}')">Appliquer</button>
        </div>
    `);
}

function doSetGrade(steamid) {
    const sel = $('grade-select');
    if (!sel) return;
    lua.setGrade(steamid, parseInt(sel.value));
    closeModal();
}

function confirmKick(steamid, name) {
    showModal(`
        <div class="modal-title">Expulser ${esc(name)} ?</div>
        <p class="text-sm text-muted">Cette action est irréversible.</p>
        <div class="modal-actions">
            <button class="btn btn-ghost" onclick="closeModal()">Annuler</button>
            <button class="btn btn-danger" onclick="lua.kick('${steamid}');closeModal()">Expulser</button>
        </div>
    `);
}

// ═══════════════════════════════════════
// TAB: GRADES
// ═══════════════════════════════════════

let selectedGradeId = null;

function renderGrades(el) {
    const grades = asArray(S.grades);
    const canEdit = isOwner() || hasPermission('edit_grades');

    let html = `<h1 class="page-title">Grades</h1>
    <p class="page-subtitle">Gérez les rôles et permissions de votre entreprise.</p>`;

    html += `<div class="card-duo">`;

    // Grade list
    html += `<div class="card">
        <div class="card-header">
            <span class="card-title">Liste des grades</span>
            ${canEdit ? '<button class="btn btn-primary btn-sm" onclick="openGradeEditor(null)">' + ICONS.plus + ' Nouveau</button>' : ''}
        </div>
        <div>`;

    grades.forEach(g => {
        const isSystem = g.is_system;
        const active = selectedGradeId === g.id;
        html += `<div class="list-item${active ? ' active' : ''}" onclick="selectedGradeId=${g.id};renderTab('grades')" style="cursor:pointer;${active ? 'background:var(--accent-soft)' : ''}">
            <div class="list-item-info">
                <div class="list-item-title">${esc(g.name)} ${isSystem ? '<span class="badge badge-muted">Système</span>' : ''}</div>
                <div class="list-item-sub">Poids: ${g.weight} · ${(g.permissions || []).length} permissions</div>
            </div>
        </div>`;
    });

    html += `</div></div>`;

    // Grade detail / editor
    html += `<div class="card">`;
    const selGrade = grades.find(g => g.id === selectedGradeId);
    if (selGrade) {
        html += renderGradeDetail(selGrade, canEdit);
    } else {
        html += emptyState('shield', 'Sélectionnez un grade pour voir les détails.');
    }
    html += `</div></div>`;

    el.innerHTML = html;
}

function renderGradeDetail(grade, canEdit) {
    const isSystem = grade.is_system;
    const owner = isOwner();
    let html = `<div class="card-header">
        <span class="card-title">${esc(grade.name)}</span>
        <div class="btn-group">`;

    if (!isSystem && canEdit) {
        html += `<button class="btn btn-sm btn-ghost" onclick="openGradeEditor(${grade.id})">${ICONS.edit} Modifier</button>`;
        html += `<button class="btn btn-sm btn-danger" onclick="confirmDeleteGrade(${grade.id})">${ICONS.trash} Supprimer</button>`;
    } else if (isSystem) {
        if (grade.name === 'Patron' && owner) {
            html += `<button class="btn btn-sm btn-ghost" onclick="openSalaryEditor(${grade.id}, '${esc(grade.name)}', ${grade.salary || 0})">${ICONS.edit} Modifier le salaire</button>`;
        } else if (grade.name !== 'Patron' && (owner || canEdit)) {
            html += `<button class="btn btn-sm btn-ghost" onclick="openGradeEditor(${grade.id})">${ICONS.edit} Modifier</button>`;
        }
    }

    html += `</div></div>`;

    html += `<div class="form-group">
        <span class="form-label">Poids</span>
        <div class="text-sm">${grade.weight}</div>
    </div>`;

    html += `<div class="form-group">
        <span class="form-label">Salaire (par 60 min de service)</span>
        <div class="text-sm">${formatMoney(grade.salary || 0)}</div>
    </div>`;

    html += `<div class="form-group">
        <span class="form-label">Permissions</span>
        <div class="perm-grid">`;

    ALL_PERMS.forEach(p => {
        const active = (grade.permissions || []).includes(p) || (grade.name === 'Patron');
        html += `<div class="perm-item${active ? ' active' : ''}">
            <div class="perm-check"></div>
            <span>${esc(PERM_LABELS[p] || p)}</span>
        </div>`;
    });

    html += `</div></div>`;
    return html;
}

function openSalaryEditor(gradeId, gradeName, currentSalary) {
    showModal(`
        <div class="modal-title">Modifier le salaire — ${esc(gradeName)}</div>
        <div class="form-group">
            <label class="form-label">Salaire par 60 min de service ($)</label>
            <input class="input" id="grade-salary" type="number" value="${currentSalary || 0}" min="0" max="999999999" placeholder="0"/>
        </div>
        <div class="modal-actions">
            <button class="btn btn-ghost" onclick="closeModal()">Annuler</button>
            <button class="btn btn-primary" onclick="doSaveSalary(${gradeId})">Enregistrer</button>
        </div>
    `);
}

function doSaveSalary(gradeId) {
    const salEl = document.getElementById('grade-salary');
    const salary = salEl ? (parseInt(salEl.value, 10) || 0) : 0;
    lua.editGrade(gradeId, '', 0, '[]', salary);
    closeModal();
}

function openGradeEditor(gradeId) {
    const grade = gradeId ? asArray(S.grades).find(g => g.id === gradeId) : null;
    const isNew = !grade;
    const perms = grade ? (grade.permissions || []) : [];

    let permChecks = '';
    ALL_PERMS.forEach(p => {
        const checked = perms.includes(p);
        permChecks += `<div class="perm-item${checked ? ' active' : ''}" onclick="this.classList.toggle('active')" data-perm="${p}">
            <div class="perm-check"></div>
            <span>${esc(PERM_LABELS[p] || p)}</span>
        </div>`;
    });

    showModal(`
        <div class="modal-title">${isNew ? 'Créer un grade' : 'Modifier ' + esc(grade.name)}</div>
        <div class="form-group">
            <label class="form-label">Nom</label>
            <input class="input" id="grade-name" value="${esc(grade ? grade.name : '')}" maxlength="24" placeholder="Nom du grade"/>
        </div>
        <div class="form-group">
            <label class="form-label">Poids (importance)</label>
            <input class="input" id="grade-weight" type="number" value="${grade ? grade.weight : 10}" min="0" max="999"/>
        </div>
        <div class="form-group">
            <label class="form-label">Salaire par 60 min de service ($)</label>
            <input class="input" id="grade-salary" type="number" value="${grade ? (grade.salary || 0) : 0}" min="0" max="999999999" placeholder="0"/>
        </div>
        <div class="form-group">
            <div class="flex justify-between items-center mb-10">
                <label class="form-label mb-0">Permissions</label>
                <div class="btn-group">
                    <button class="btn btn-sm btn-ghost" style="padding: 2px 8px; font-size: 10px;" onclick="toggleAllPerms(true)">Tout cocher</button>
                    <button class="btn btn-sm btn-ghost" style="padding: 2px 8px; font-size: 10px;" onclick="toggleAllPerms(false)">Tout décocher</button>
                </div>
            </div>
            <div class="perm-grid" id="grade-perms">${permChecks}</div>
        </div>
        <div class="modal-actions">
            <button class="btn btn-ghost" onclick="closeModal()">Annuler</button>
            <button class="btn btn-primary" onclick="doSaveGrade(${gradeId || 'null'})">${isNew ? 'Créer' : 'Sauvegarder'}</button>
        </div>
    `);
}

function doSaveGrade(gradeId) {
    const nameEl = $('grade-name');
    const name = nameEl ? nameEl.value.trim() : '';
    const weightEl = $('grade-weight');
    const weight = weightEl ? (parseInt(weightEl.value, 10) || 0) : 0;
    const salEl = $('grade-salary');
    const salary = salEl ? (parseInt(salEl.value, 10) || 0) : 0;
    const permEls = document.querySelectorAll('#grade-perms .perm-item.active');
    const perms = [];
    permEls.forEach(el => perms.push(el.getAttribute('data-perm')));
    const permsJson = JSON.stringify(perms);

    if (!name) { showToast('Entrez un nom de grade.', true); return; }

    if (gradeId) {
        lua.editGrade(gradeId, name, weight, permsJson, salary);
    } else {
        lua.createGrade(name, weight, permsJson, salary);
    }
    closeModal();
}

function confirmDeleteGrade(gradeId) {
    const grade = asArray(S.grades).find(g => g.id === gradeId);
    const name = grade ? grade.name : '';
    showModal(`
        <div class="modal-title">Supprimer le grade "${esc(name)}" ?</div>
        <p class="text-sm text-muted">Les membres avec ce grade seront migrés vers "Membre".</p>
        <div class="modal-actions">
            <button class="btn btn-ghost" onclick="closeModal()">Annuler</button>
            <button class="btn btn-danger" onclick="doDeleteGrade(${gradeId})">Supprimer</button>
        </div>
    `);
}

function doDeleteGrade(gradeId) {
    if (typeof lua !== 'undefined') lua.deleteGrade(gradeId);
    closeModal();
}

// ═══════════════════════════════════════
// TAB: BANQUE
// ═══════════════════════════════════════

function renderBanque(el) {
    const balance = S.myCompany ? S.myCompany.balance : 0;
    const ledger = asArray(S.ledger);
    const canDeposit = hasPermission('bank_deposit');
    const canWithdraw = hasPermission('bank_withdraw');
    const isDarkRP = S.isDarkRP;

    let html = `<h1 class="page-title">Banque</h1>
    <p class="page-subtitle">${esc(S.myCompany ? S.myCompany.name : '')}</p>`;

    // Balance card
    html += `<div class="stat-card mb-16">
        <div class="stat-value">${formatMoney(balance)}</div>
        <div class="stat-label">Solde de l'entreprise</div>
    </div>`;

    // Deposit / Withdraw
    html += `<div class="card-duo mb-16">
        <div class="card">
            <div class="card-title">Déposer</div>
            <div class="form-group mt-12">
                <input class="input" id="bank-deposit" type="number" placeholder="Montant" min="1" ${!canDeposit || !isDarkRP ? 'disabled' : ''}/>
            </div>
            <button class="btn btn-primary w-full ${!canDeposit || !isDarkRP ? 'disabled' : ''}" ${!canDeposit || !isDarkRP ? 'disabled' : ''}
                ${!canDeposit ? 'data-tooltip="Permission requise: bank_deposit"' : (!isDarkRP ? 'data-tooltip="DarkRP requis"' : '')}
                onclick="doBankDeposit()">Déposer</button>
        </div>
        <div class="card">
            <div class="card-title">Retirer</div>
            <div class="form-group mt-12">
                <input class="input" id="bank-withdraw" type="number" placeholder="Montant" min="1" ${!canWithdraw || !isDarkRP ? 'disabled' : ''}/>
            </div>
            <button class="btn btn-primary w-full ${!canWithdraw || !isDarkRP ? 'disabled' : ''}" ${!canWithdraw || !isDarkRP ? 'disabled' : ''}
                ${!canWithdraw ? 'data-tooltip="Permission requise: bank_withdraw"' : (!isDarkRP ? 'data-tooltip="DarkRP requis"' : '')}
                onclick="doBankWithdraw()">Retirer</button>
        </div>
    </div>`;

    // Ledger
    html += `<div class="card">
        <div class="card-title">Journal des opérations</div>
        <div class="mt-12">`;

    if (ledger.length === 0) {
        html += emptyState('bank', 'Aucune opération enregistrée.');
    } else {
        html += `<div class="table-wrap"><table>
            <thead><tr><th>Date</th><th>Auteur</th><th>Action</th><th>Montant</th><th>Note</th></tr></thead><tbody>`;
        ledger.forEach(l => {
            const color = l.amount >= 0 ? 'text-success' : 'text-danger';
            html += `<tr>
                <td class="text-sm">${formatDate(l.created_at)}</td>
                <td>${esc(l.name)}</td>
                <td><span class="badge badge-muted">${esc(l.action)}</span></td>
                <td class="${color} font-bold">${l.amount >= 0 ? '+' : ''}${formatMoney(l.amount)}</td>
                <td class="text-sm text-muted">${esc(l.note)}</td>
            </tr>`;
        });
        html += `</tbody></table></div>`;
    }

    html += `</div></div>`;

    el.innerHTML = html;
}

function doBankDeposit() {
    const v = parseInt($('bank-deposit').value);
    if (!v || v <= 0) { showToast('Montant invalide.', true); return; }
    lua.bankDeposit(v);
}

function doBankWithdraw() {
    const v = parseInt($('bank-withdraw').value);
    if (!v || v <= 0) { showToast('Montant invalide.', true); return; }
    lua.bankWithdraw(v);
}

// ═══════════════════════════════════════
// TAB: PARAMÈTRES
// ═══════════════════════════════════════

function renderParametres(el) {
    const inCompany = !!S.myCompany;

    let html = `<h1 class="page-title">Paramètres</h1>
    <p class="page-subtitle">Configuration client et entreprise.</p>`;

    // Client settings
    html += `<div class="card mb-16">
        <div class="card-title">Paramètres client</div>
        <div class="mt-12">
            <div class="toggle-row">
                <span class="toggle-label">Son des notifications</span>
                <label class="toggle-switch">
                    <input type="checkbox" id="toggle-sound" ${clientSettings.notifSound ? 'checked' : ''} onchange="toggleClientSetting('notifSound')"/>
                    <span class="toggle-slider"></span>
                </label>
            </div>
            <div class="toggle-row">
                <span class="toggle-label">Réduire les animations</span>
                <label class="toggle-switch">
                    <input type="checkbox" id="toggle-anim" ${clientSettings.reduceAnimations ? 'checked' : ''} onchange="toggleClientSetting('reduceAnimations')"/>
                    <span class="toggle-slider"></span>
                </label>
            </div>
        </div>
    </div>`;

    if (inCompany) {
        // Company settings
        html += `<div class="card mb-16">
            <div class="card-title">Paramètres de l'entreprise</div>
            <div class="mt-12">`;

        // Rename
        if (hasPermission('rename_company')) {
            html += `<div class="form-group">
                <label class="form-label">Renommer l'entreprise</label>
                <div class="input-with-btn">
                    <input class="input" id="rename-input" placeholder="${esc(S.myCompany.name)}" maxlength="24"/>
                    <button class="btn btn-primary" onclick="doRename()">Renommer</button>
                </div>
            </div>`;
        }

        // Invite
        if (hasPermission('invite')) {
            html += `<div class="form-group">
                <label class="form-label">Inviter un joueur</label>
                <div class="input-with-btn">
                    <select class="input" id="invite-select">
                        <option value="">— Sélectionnez —</option>`;
            asArray(S.onlinePlayers).forEach(p => {
                if (p.steamid !== S.mySteamID) {
                    html += `<option value="${p.steamid}">${esc(p.name)}</option>`;
                }
            });
            html += `</select>
                    <button class="btn btn-primary" onclick="doInvite()">Inviter</button>
                </div>
            </div>`;
        }

        html += `</div></div>`;

        // Owner settings
        if (isOwner()) {
            html += `<div class="card mb-16">
                <div class="card-title">Actions du patron</div>
                <div class="mt-12">`;

            // Transfer
            html += `<div class="form-group">
                <label class="form-label">Transférer la propriété</label>
                <div class="input-with-btn">
                    <select class="input" id="transfer-select">
                        <option value="">— Sélectionnez un membre —</option>`;
            asArray(S.members).forEach(m => {
                if (m.steamid !== S.mySteamID) {
                    html += `<option value="${m.steamid}">${esc(m.name)}</option>`;
                }
            });
            html += `</select>
                    <button class="btn btn-primary" onclick="doTransfer()">Transférer</button>
                </div>
            </div>`;

            // Application form builder
            html += renderFormBuilder();

            // Delete
            html += `<div class="form-group mt-20">
                <button class="btn btn-danger w-full" onclick="confirmDelete()">Supprimer l'entreprise</button>
            </div>`;

            html += `</div></div>`;
        }

        // Leave
        if (!isOwner()) {
            html += `<div class="card">
                <button class="btn btn-danger w-full" onclick="confirmLeave()">Quitter l'entreprise</button>
            </div>`;
        }
    }

    el.innerHTML = html;
}

function renderFormBuilder() {
    const currentForm = (S.settings && S.settings.form_json) ? S.settings.form_json : [];

    let html = `<div class="form-group mt-16">
        <label class="form-label">Formulaire de candidature</label>
        <div class="text-sm text-muted mb-8">Définissez les champs affichés aux candidats (max 6).</div>
        <div id="form-fields">`;

    currentForm.forEach((f, i) => {
        html += renderFormField(i, f);
    });

    html += `</div>
        <div class="btn-group mt-8">
            <button class="btn btn-ghost btn-sm" onclick="addFormField()">${ICONS.plus} Ajouter un champ</button>
            <button class="btn btn-primary btn-sm" onclick="saveFormBuilder()">Sauvegarder le formulaire</button>
        </div>
    </div>`;

    return html;
}

function renderFormField(index, field) {
    return `<div class="flex gap-8 items-center mb-8 form-field-row" data-index="${index}">
        <input class="input" placeholder="Clé" value="${esc(field.key || '')}" data-role="key" style="flex:0.5;"/>
        <input class="input" placeholder="Label" value="${esc(field.label || '')}" data-role="label" style="flex:1;"/>
        <input class="input" type="number" placeholder="Max" value="${field.max || 256}" data-role="max" style="flex:0.3;"/>
        <label class="text-sm" style="white-space:nowrap;display:flex;align-items:center;gap:4px;">
            <input type="checkbox" data-role="required" ${field.required ? 'checked' : ''}/> Requis
        </label>
        <button class="btn-icon" onclick="this.parentElement.remove()" data-tooltip="Supprimer">${ICONS.x}</button>
    </div>`;
}

function addFormField() {
    const container = document.getElementById('form-fields');
    if (!container) return;
    const rows = container.querySelectorAll('.form-field-row');
    if (rows.length >= 6) { showToast('Maximum 6 champs.', true); return; }
    const idx = rows.length;
    const div = document.createElement('div');
    div.innerHTML = renderFormField(idx, {});
    container.appendChild(div.firstElementChild);
}

function saveFormBuilder() {
    const rows = document.querySelectorAll('.form-field-row');
    const fields = [];
    rows.forEach(row => {
        const key = row.querySelector('[data-role="key"]').value.trim();
        const label = row.querySelector('[data-role="label"]').value.trim();
        const max = parseInt(row.querySelector('[data-role="max"]').value) || 256;
        const required = row.querySelector('[data-role="required"]').checked;
        if (key && label) {
            fields.push({ key, label, max, required });
        }
    });
    lua.setApplicationForm(JSON.stringify(fields));
}

function toggleClientSetting(key) {
    clientSettings[key] = !clientSettings[key];
    if (key === 'reduceAnimations') {
        if (clientSettings.reduceAnimations) document.body.classList.add('reduce-animations');
        else document.body.classList.remove('reduce-animations');
    }
    lua.saveClientSettings(JSON.stringify(clientSettings));
}

function doRename() {
    const v = $('rename-input').value.trim();
    if (!v || v.length < 3 || v.length > 24) { showToast('Nom invalide (3–24 caractères).', true); return; }
    lua.renameCompany(v);
}

function doInvite() {
    const sel = $('invite-select');
    if (!sel || !sel.value) { showToast('Sélectionnez un joueur.', true); return; }
    lua.invite(sel.value);
}

function doTransfer() {
    const sel = $('transfer-select');
    if (!sel || !sel.value) { showToast('Sélectionnez un membre.', true); return; }
    showModal(`
        <div class="modal-title">Transférer la propriété ?</div>
        <p class="text-sm text-muted">Vous perdrez vos droits de patron. Cette action est irréversible.</p>
        <div class="modal-actions">
            <button class="btn btn-ghost" onclick="closeModal()">Annuler</button>
            <button class="btn btn-danger" onclick="lua.transferOwnership('${sel.value}');closeModal()">Confirmer</button>
        </div>
    `);
}

function confirmDelete() {
    showModal(`
        <div class="modal-title">Supprimer l'entreprise ?</div>
        <p class="text-sm text-muted">Toutes les données seront perdues : membres, grades, messages, banque, candidatures. Cette action est irréversible.</p>
        <div class="modal-actions">
            <button class="btn btn-ghost" onclick="closeModal()">Annuler</button>
            <button class="btn btn-danger" onclick="lua.deleteCompany();closeModal()">Supprimer définitivement</button>
        </div>
    `);
}

function confirmLeave() {
    showModal(`
        <div class="modal-title">Quitter l'entreprise ?</div>
        <p class="text-sm text-muted">Vous ne pourrez plus accéder aux données de l'entreprise.</p>
        <div class="modal-actions">
            <button class="btn btn-ghost" onclick="closeModal()">Annuler</button>
            <button class="btn btn-danger" onclick="lua.leaveCompany();closeModal()">Quitter</button>
        </div>
    `);
}

// ═══════════════════════════════════════
// INIT
// ═══════════════════════════════════════

// Request initial state on load
if (typeof lua !== 'undefined') {
    lua.requestState();
    lua.getClientSettings();
}
function toggleAllPerms(state) {
    const perms = document.querySelectorAll('#grade-perms .perm-item');
    perms.forEach(p => {
        if (state) p.classList.add('active');
        else p.classList.remove('active');
    });
}
