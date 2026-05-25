import React, { useState, useEffect, useMemo, useRef } from 'react';
import { Plus, TrendingUp, TrendingDown, Wallet, Trash2, X, Check, Search, Download, Upload, Sun, Moon, Plane, Target, Repeat, BarChart3, Home, Settings, ChevronRight, ChevronLeft, AlertCircle, Edit3, Calendar, ArrowUpRight, ArrowDownRight, CreditCard, Banknote, PiggyBank, Sparkles } from 'lucide-react';

const CURRENCIES = [
  { code: 'USD', symbol: '$', name: 'US Dollar', position: 'before' },
  { code: 'EUR', symbol: '€', name: 'Euro', position: 'before' },
  { code: 'GBP', symbol: '£', name: 'British Pound', position: 'before' },
  { code: 'AED', symbol: 'AED', name: 'UAE Dirham', position: 'before' },
  { code: 'RUB', symbol: '₽', name: 'Russian Ruble', position: 'after' },
  { code: 'JPY', symbol: '¥', name: 'Japanese Yen', position: 'before' },
  { code: 'CNY', symbol: '¥', name: 'Chinese Yuan', position: 'before' },
  { code: 'KZT', symbol: '₸', name: 'Tenge', position: 'after' },
  { code: 'TRY', symbol: '₺', name: 'Turkish Lira', position: 'before' },
  { code: 'INR', symbol: '₹', name: 'Indian Rupee', position: 'before' },
  { code: 'CHF', symbol: 'CHF', name: 'Swiss Franc', position: 'before' },
  { code: 'CAD', symbol: 'C$', name: 'Canadian Dollar', position: 'before' },
  { code: 'AUD', symbol: 'A$', name: 'Australian Dollar', position: 'before' },
  { code: 'THB', symbol: '฿', name: 'Thai Baht', position: 'before' },
];

const DEFAULT_CATEGORIES = {
  expense: [
    { id: 'food', label: 'Food', emoji: '🍕', color: '#e07060', isDefault: true },
    { id: 'transport', label: 'Transport', emoji: '🚌', color: '#7a9cc6', isDefault: true },
    { id: 'home', label: 'Home', emoji: '🏠', color: '#a67ac9', isDefault: true },
    { id: 'fun', label: 'Fun', emoji: '🎬', color: '#c97aaf', isDefault: true },
    { id: 'health', label: 'Health', emoji: '💊', color: '#7ac9a6', isDefault: true },
    { id: 'shop', label: 'Shopping', emoji: '🛍️', color: '#d4a574', isDefault: true },
    { id: 'travel', label: 'Travel', emoji: '✈️', color: '#6ab4d4', isDefault: true },
    { id: 'other_e', label: 'Other', emoji: '📌', color: '#8a7a66', isDefault: true },
  ],
  income: [
    { id: 'salary', label: 'Salary', emoji: '💼', color: '#7a9c7a', isDefault: true },
    { id: 'freelance', label: 'Freelance', emoji: '💻', color: '#9ac97a', isDefault: true },
    { id: 'gift', label: 'Gift', emoji: '🎁', color: '#c9b87a', isDefault: true },
    { id: 'invest', label: 'Investment', emoji: '📈', color: '#7ac9b8', isDefault: true },
    { id: 'other_i', label: 'Other', emoji: '✨', color: '#b8a87a', isDefault: true },
  ],
};

const DEFAULT_WALLETS = [
  { id: 'cash', name: 'Cash', emoji: '💵', color: '#7ac9a6', isDefault: true },
  { id: 'card', name: 'Card', emoji: '💳', color: '#7a9cc6', isDefault: true },
  { id: 'savings', name: 'Savings', emoji: '🐷', color: '#d4a574', isDefault: true },
];

const EMOJI_CHOICES = ['🍕','🍔','🥗','☕','🍷','🚌','🚗','✈️','🏠','🛏️','🎬','🎮','🎵','💊','🏥','🏋️','🛍️','👕','💄','📚','💼','💻','🎁','📈','💰','🐷','💵','💳','✨','📌','🐶','⚡','🌍','🍎','📱','🎓','💎','🔧','🚀','💡'];
const COLOR_CHOICES = ['#e07060','#c97a6a','#d4a574','#c9b87a','#7ac9a6','#7a9c7a','#9ac97a','#7ac9b8','#7a9cc6','#6ab4d4','#a67ac9','#c97aaf','#8a7a66','#b8a87a'];

const THEMES = {
  dark: {
    bg: 'linear-gradient(180deg, #0a0a0a 0%, #1a1410 100%)',
    surface: '#1a1410', surfaceAlt: '#0a0a0a',
    border: '#2a1f15', borderAlt: '#3a2f25',
    text: '#f5f0e8', textMute: '#8a7a66', textDim: '#5a4a3a',
    accent: '#d4a574', accentAlt: '#b88a5a',
    income: '#7a9c7a', expense: '#c97a6a', danger: '#e07060',
  },
  light: {
    bg: 'linear-gradient(180deg, #faf6f0 0%, #f0e8dc 100%)',
    surface: '#ffffff', surfaceAlt: '#faf6f0',
    border: '#e8dccc', borderAlt: '#d4c4ac',
    text: '#2a1f15', textMute: '#8a7a66', textDim: '#b8a890',
    accent: '#b88a5a', accentAlt: '#9a6f3f',
    income: '#5a8c5a', expense: '#b86a5a', danger: '#c95a4a',
  },
};

export default function App() {
  // State
  const [transactions, setTransactions] = useState([]);
  const [budgets, setBudgets] = useState({});
  const [trips, setTrips] = useState([]);
  const [goals, setGoals] = useState([]);
  const [subscriptions, setSubscriptions] = useState([]);
  const [quickActions, setQuickActions] = useState([]);
  const [categories, setCategories] = useState(DEFAULT_CATEGORIES);
  const [wallets, setWallets] = useState(DEFAULT_WALLETS);
  const [recurring, setRecurring] = useState([]);
  const [currencyCode, setCurrencyCode] = useState('USD');
  const [theme, setTheme] = useState('dark');
  const [activeTrip, setActiveTrip] = useState(null);
  const [onboarded, setOnboarded] = useState(false);
  const [loading, setLoading] = useState(true);

  const [tab, setTab] = useState('home');
  const [modal, setModal] = useState(null);
  const [editingTx, setEditingTx] = useState(null);
  const [editingCat, setEditingCat] = useState(null);
  const [editingWallet, setEditingWallet] = useState(null);
  const [statsPeriod, setStatsPeriod] = useState('month');
  const [searchQ, setSearchQ] = useState('');
  const [calMonth, setCalMonth] = useState(new Date());

  const currency = useMemo(() => CURRENCIES.find((c) => c.code === currencyCode) || CURRENCIES[0], [currencyCode]);
  const t = THEMES[theme];

  // Load
  useEffect(() => {
    (async () => {
      const keys = ['transactions','budgets','trips','goals','subscriptions','quickActions','categories','wallets','recurring','currency','theme','activeTrip','onboarded'];
      const setters = {
        transactions: setTransactions, budgets: setBudgets, trips: setTrips, goals: setGoals,
        subscriptions: setSubscriptions, quickActions: setQuickActions, categories: setCategories,
        wallets: setWallets, recurring: setRecurring,
        currency: setCurrencyCode, theme: setTheme, activeTrip: setActiveTrip,
        onboarded: (v) => setOnboarded(v === 'true' || v === true),
      };
      for (const k of keys) {
        try {
          const r = await window.storage.get(k);
          if (r && r.value) {
            const v = ['currency','theme','activeTrip','onboarded'].includes(k) ? r.value : JSON.parse(r.value);
            setters[k](v);
          }
        } catch (e) {}
      }
      setLoading(false);
    })();
  }, []);

  // Process recurring on load
  useEffect(() => {
    if (loading || !recurring.length) return;
    const now = new Date();
    let needSave = false;
    const newTx = [...transactions];
    const updRec = recurring.map((r) => {
      let last = new Date(r.lastRun || r.startDate);
      const next = new Date(last);
      // Forward through missed intervals
      while (true) {
        if (r.freq === 'monthly') next.setMonth(next.getMonth() + 1);
        else if (r.freq === 'weekly') next.setDate(next.getDate() + 7);
        else if (r.freq === 'yearly') next.setFullYear(next.getFullYear() + 1);
        else break;
        if (next > now) break;
        newTx.unshift({
          id: Date.now() + Math.random(),
          type: r.type, amount: r.amount, currency: currencyCode,
          category: r.category, walletId: r.walletId,
          note: r.note + ' (auto)', tags: [], tripId: null,
          date: new Date(next).toISOString(),
          fromRecurring: r.id,
        });
        last = new Date(next);
        needSave = true;
      }
      return { ...r, lastRun: last.toISOString() };
    });
    if (needSave) {
      setTransactions(newTx);
      persist('transactions', newTx);
      setRecurring(updRec);
      persist('recurring', updRec);
    }
  }, [loading]);

  const persist = async (key, val) => {
    try { await window.storage.set(key, typeof val === 'string' || typeof val === 'boolean' ? String(val) : JSON.stringify(val)); } catch (e) {}
  };
  const savedSet = (key, setter, val) => { setter(val); persist(key, val); };

  const allCats = [...categories.expense, ...categories.income];
  const getCat = (id) => allCats.find((c) => c.id === id) || { emoji: '📌', label: '—', color: '#8a7a66' };
  const getWallet = (id) => wallets.find((w) => w.id === id) || wallets[0];

  // Format
  const fmt = (n) => new Intl.NumberFormat('en-US', { maximumFractionDigits: 2 }).format(n);
  const formatMoney = (n, sign = '') => {
    const num = fmt(Math.abs(n));
    return currency.position === 'before' ? `${sign}${currency.symbol}${num}` : `${sign}${num} ${currency.symbol}`;
  };
  const fmtDate = (iso) => {
    const d = new Date(iso);
    const today = new Date();
    const yest = new Date(); yest.setDate(yest.getDate() - 1);
    if (d.toDateString() === today.toDateString()) return 'Today';
    if (d.toDateString() === yest.toDateString()) return 'Yesterday';
    return d.toLocaleDateString('en-US', { day: 'numeric', month: 'short' });
  };

  // Calculations
  const monthTx = useMemo(() => {
    const now = new Date();
    return transactions.filter((tr) => {
      const d = new Date(tr.date);
      return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
    });
  }, [transactions]);

  const prevMonthTx = useMemo(() => {
    const now = new Date();
    const p = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    return transactions.filter((tr) => {
      const d = new Date(tr.date);
      return d.getMonth() === p.getMonth() && d.getFullYear() === p.getFullYear();
    });
  }, [transactions]);

  const income = monthTx.filter((tr) => tr.type === 'income').reduce((s, tr) => s + tr.amount, 0);
  const expense = monthTx.filter((tr) => tr.type === 'expense').reduce((s, tr) => s + tr.amount, 0);
  const balance = income - expense;
  const prevExpense = prevMonthTx.filter((tr) => tr.type === 'expense').reduce((s, tr) => s + tr.amount, 0);
  const expenseChange = prevExpense > 0 ? ((expense - prevExpense) / prevExpense) * 100 : 0;

  // Total balance across all wallets all time
  const totalBalance = useMemo(() => {
    return transactions.reduce((s, tr) => s + (tr.type === 'income' ? tr.amount : -tr.amount), 0);
  }, [transactions]);

  const walletBalances = useMemo(() => {
    const map = {};
    wallets.forEach((w) => { map[w.id] = 0; });
    transactions.forEach((tr) => {
      const wid = tr.walletId || 'cash';
      if (!(wid in map)) map[wid] = 0;
      map[wid] += tr.type === 'income' ? tr.amount : -tr.amount;
    });
    return map;
  }, [transactions, wallets]);

  const byCategory = useMemo(() => {
    const map = {};
    let source = monthTx;
    if (statsPeriod === 'week') {
      const wk = new Date(); wk.setDate(wk.getDate() - 7);
      source = transactions.filter((tr) => new Date(tr.date) >= wk);
    } else if (statsPeriod === 'year') {
      const yr = new Date().getFullYear();
      source = transactions.filter((tr) => new Date(tr.date).getFullYear() === yr);
    }
    source.filter((tr) => tr.type === 'expense').forEach((tr) => {
      map[tr.category] = (map[tr.category] || 0) + tr.amount;
    });
    return Object.entries(map).map(([id, total]) => ({ id, total, ...getCat(id) })).sort((a, b) => b.total - a.total);
  }, [monthTx, transactions, statsPeriod, categories]);

  const budgetProgress = useMemo(() => {
    return Object.entries(budgets).map(([catId, limit]) => {
      const spent = monthTx.filter((tr) => tr.type === 'expense' && tr.category === catId).reduce((s, tr) => s + tr.amount, 0);
      return { catId, limit, spent, pct: limit > 0 ? (spent / limit) * 100 : 0, ...getCat(catId) };
    });
  }, [budgets, monthTx, categories]);

  const filteredTx = useMemo(() => {
    if (!searchQ.trim()) return transactions;
    const q = searchQ.toLowerCase();
    return transactions.filter((tr) => {
      const c = getCat(tr.category);
      const w = getWallet(tr.walletId);
      return tr.note.toLowerCase().includes(q) || c.label.toLowerCase().includes(q) || w.name.toLowerCase().includes(q) || String(tr.amount).includes(q) || (tr.tags || []).some((tg) => tg.toLowerCase().includes(q));
    });
  }, [transactions, searchQ, categories, wallets]);

  const grouped = useMemo(() => filteredTx.reduce((acc, tr) => {
    const key = fmtDate(tr.date);
    if (!acc[key]) acc[key] = [];
    acc[key].push(tr);
    return acc;
  }, {}), [filteredTx]);

  // Actions
  const saveTransactions = (list) => savedSet('transactions', setTransactions, list);
  const removeTransaction = (id) => saveTransactions(transactions.filter((x) => x.id !== id));

  const upsertTransaction = (tx) => {
    if (transactions.find((x) => x.id === tx.id)) {
      saveTransactions(transactions.map((x) => x.id === tx.id ? tx : x));
    } else {
      saveTransactions([tx, ...transactions]);
    }
  };

  const useQuick = (q) => {
    const tx = {
      id: Date.now() + Math.random(),
      type: q.type, amount: q.amount, currency: currencyCode,
      category: q.category, walletId: q.walletId || wallets[0].id,
      note: q.note, tags: [], tripId: q.type === 'expense' && activeTrip ? activeTrip : null,
      date: new Date().toISOString(),
    };
    upsertTransaction(tx);
  };

  const exportBackup = () => {
    const data = { transactions, budgets, trips, goals, subscriptions, quickActions, categories, wallets, recurring, currencyCode, theme };
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = `finance_backup_${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const exportCSV = () => {
    const header = 'Date,Type,Category,Wallet,Amount,Currency,Note,Tags\n';
    const rows = transactions.map((tr) => {
      const c = getCat(tr.category);
      const w = getWallet(tr.walletId);
      const safeNote = (tr.note || '').replace(/"/g, '""');
      const tags = (tr.tags || []).join(';');
      return `${tr.date},${tr.type},${c.label},${w.name},${tr.amount},${currencyCode},"${safeNote}","${tags}"`;
    }).join('\n');
    const blob = new Blob([header + rows], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = `finances_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const importBackup = (file) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = JSON.parse(e.target.result);
        if (!data.transactions) throw new Error('invalid');
        if (!confirm('This will replace all your current data. Continue?')) return;
        if (data.transactions) savedSet('transactions', setTransactions, data.transactions);
        if (data.budgets) savedSet('budgets', setBudgets, data.budgets);
        if (data.trips) savedSet('trips', setTrips, data.trips);
        if (data.goals) savedSet('goals', setGoals, data.goals);
        if (data.subscriptions) savedSet('subscriptions', setSubscriptions, data.subscriptions);
        if (data.quickActions) savedSet('quickActions', setQuickActions, data.quickActions);
        if (data.categories) savedSet('categories', setCategories, data.categories);
        if (data.wallets) savedSet('wallets', setWallets, data.wallets);
        if (data.recurring) savedSet('recurring', setRecurring, data.recurring);
        if (data.currencyCode) savedSet('currency', setCurrencyCode, data.currencyCode);
        if (data.theme) savedSet('theme', setTheme, data.theme);
        alert('Backup restored!');
      } catch (err) { alert('Invalid backup file.'); }
    };
    reader.readAsText(file);
  };

  const finishOnboarding = () => savedSet('onboarded', setOnboarded, true);

  if (loading) {
    return <div style={{ minHeight: '100vh', background: t.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', color: t.textMute, fontFamily: 'Georgia, serif' }}>Loading...</div>;
  }

  if (!onboarded) return <Onboarding t={t} onFinish={finishOnboarding} />;

  return (
    <div style={{ minHeight: '100vh', background: t.bg, color: t.text, fontFamily: '"SF Pro Display", -apple-system, system-ui, sans-serif', paddingBottom: '100px', transition: 'background 0.3s, color 0.3s' }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,600;9..144,700&display=swap');
        * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
        button { font-family: inherit; cursor: pointer; border: none; }
        input, select, textarea { font-family: inherit; }
        @keyframes slideUp { from { transform: translateY(100%); } to { transform: translateY(0); } }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes pop { 0% { transform: scale(0.95); opacity: 0; } 100% { transform: scale(1); opacity: 1; } }
      `}</style>

      {/* Header */}
      <div style={{ padding: '28px 20px 12px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{ fontSize: '12px', letterSpacing: '2px', color: t.textMute, textTransform: 'uppercase', marginBottom: '4px' }}>
            {activeTrip ? `Trip: ${trips.find((tp) => tp.id === activeTrip)?.name}` : 'My Finances'}
          </div>
          <div style={{ fontFamily: '"Fraunces", Georgia, serif', fontSize: '24px', fontWeight: 600 }}>
            {new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}
          </div>
        </div>
        <div style={{ display: 'flex', gap: '6px' }}>
          <IconButton t={t} onClick={() => setModal('search')}><Search size={18} /></IconButton>
          <IconButton t={t} onClick={() => setModal('settings')}><Settings size={18} /></IconButton>
        </div>
      </div>

      {/* HOME */}
      {tab === 'home' && (
        <>
          {activeTrip && (
            <div style={{ padding: '0 20px', marginBottom: '10px' }}>
              <div onClick={() => savedSet('activeTrip', setActiveTrip, null)} style={{
                background: 'rgba(106,180,212,0.1)', border: '1px solid rgba(106,180,212,0.3)',
                borderRadius: '12px', padding: '10px 14px', display: 'flex', alignItems: 'center', gap: '10px', cursor: 'pointer',
              }}>
                <Plane size={16} color="#6ab4d4" />
                <div style={{ flex: 1, fontSize: '13px', color: '#6ab4d4' }}>
                  Logging to "{trips.find((tp) => tp.id === activeTrip)?.name}". Tap to exit.
                </div>
              </div>
            </div>
          )}

          {/* Balance card */}
          <div style={{ padding: '0 20px', marginBottom: '14px' }}>
            <div style={{
              background: theme === 'dark' ? 'linear-gradient(135deg, #2a1f15 0%, #1a1410 100%)' : 'linear-gradient(135deg, #fff8ee 0%, #faf0e0 100%)',
              border: `1px solid ${t.borderAlt}`, borderRadius: '20px', padding: '20px', position: 'relative', overflow: 'hidden',
            }}>
              <div style={{ position: 'absolute', top: '-40px', right: '-40px', width: '160px', height: '160px',
                background: 'radial-gradient(circle, rgba(212,165,116,0.15) 0%, transparent 70%)' }} />
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <div style={{ fontSize: '11px', letterSpacing: '1.5px', color: t.textMute, textTransform: 'uppercase' }}>This Month</div>
                <button onClick={() => setModal('currency')} style={{ background: t.surface, border: `1px solid ${t.border}`, borderRadius: '8px', padding: '4px 10px', color: t.accent, fontWeight: 600, fontSize: '12px' }}>
                  {currency.symbol} {currency.code}
                </button>
              </div>
              <div style={{ fontFamily: '"Fraunces", serif', fontSize: '36px', fontWeight: 600, color: balance >= 0 ? t.accent : t.danger, lineHeight: 1.1 }}>
                {formatMoney(balance, balance < 0 ? '−' : '')}
              </div>
              {prevExpense > 0 && (
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px', marginTop: '6px', fontSize: '12px', color: expenseChange > 0 ? t.danger : t.income }}>
                  {expenseChange > 0 ? <ArrowUpRight size={12} /> : <ArrowDownRight size={12} />}
                  <span>{Math.abs(expenseChange).toFixed(0)}% {expenseChange > 0 ? 'more' : 'less'} spent vs last month</span>
                </div>
              )}
              <div style={{ display: 'flex', gap: '14px', marginTop: '16px' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: t.income, fontSize: '11px', marginBottom: '2px' }}>
                    <TrendingUp size={12} /> Income
                  </div>
                  <div style={{ fontFamily: '"Fraunces", serif', fontSize: '16px', fontWeight: 600 }}>{formatMoney(income)}</div>
                </div>
                <div style={{ width: '1px', background: t.borderAlt }} />
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: t.expense, fontSize: '11px', marginBottom: '2px' }}>
                    <TrendingDown size={12} /> Expenses
                  </div>
                  <div style={{ fontFamily: '"Fraunces", serif', fontSize: '16px', fontWeight: 600 }}>{formatMoney(expense)}</div>
                </div>
              </div>
            </div>
          </div>

          {/* Wallets */}
          <div style={{ padding: '0 20px', marginBottom: '14px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
              <div style={{ fontSize: '11px', letterSpacing: '1.5px', color: t.textMute, textTransform: 'uppercase' }}>Wallets · {formatMoney(totalBalance)}</div>
              <button onClick={() => { setEditingWallet({ id: 'new_' + Date.now(), name: '', emoji: '💵', color: COLOR_CHOICES[0] }); setModal('wallet'); }} style={{ background: 'transparent', color: t.accent, fontSize: '12px', fontWeight: 600 }}>+ Add</button>
            </div>
            <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', paddingBottom: '4px' }}>
              {wallets.map((w) => (
                <div key={w.id} onClick={() => { setEditingWallet(w); setModal('wallet'); }} style={{
                  flexShrink: 0, background: t.surface, border: `1px solid ${t.border}`, borderRadius: '14px',
                  padding: '12px 14px', minWidth: '120px', cursor: 'pointer',
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '4px' }}>
                    <span style={{ fontSize: '18px' }}>{w.emoji}</span>
                    <span style={{ fontSize: '12px', color: t.textMute, fontWeight: 500 }}>{w.name}</span>
                  </div>
                  <div style={{ fontFamily: '"Fraunces", serif', fontWeight: 600, fontSize: '15px', color: (walletBalances[w.id] || 0) >= 0 ? t.text : t.danger }}>
                    {formatMoney(walletBalances[w.id] || 0, (walletBalances[w.id] || 0) < 0 ? '−' : '')}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Quick actions */}
          {quickActions.length > 0 && (
            <div style={{ padding: '0 20px', marginBottom: '14px' }}>
              <div style={{ fontSize: '11px', letterSpacing: '1.5px', color: t.textMute, textTransform: 'uppercase', marginBottom: '8px' }}>Quick Actions</div>
              <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', paddingBottom: '4px' }}>
                {quickActions.map((q) => {
                  const c = getCat(q.category);
                  return (
                    <div key={q.id} style={{ position: 'relative', flexShrink: 0 }}>
                      <button onClick={() => useQuick(q)} style={{
                        background: t.surface, border: `1px solid ${t.border}`, borderRadius: '12px',
                        padding: '8px 12px', display: 'flex', alignItems: 'center', gap: '8px', color: t.text,
                      }}>
                        <span style={{ fontSize: '16px' }}>{c.emoji}</span>
                        <div style={{ textAlign: 'left' }}>
                          <div style={{ fontSize: '10px', color: t.textMute }}>{q.note || c.label}</div>
                          <div style={{ fontFamily: '"Fraunces", serif', fontWeight: 600, fontSize: '13px' }}>{formatMoney(q.amount)}</div>
                        </div>
                      </button>
                      <button onClick={() => savedSet('quickActions', setQuickActions, quickActions.filter((x) => x.id !== q.id))} style={{
                        position: 'absolute', top: '-4px', right: '-4px', width: '16px', height: '16px',
                        background: t.danger, color: '#fff', borderRadius: '50%', display: 'flex',
                        alignItems: 'center', justifyContent: 'center', fontSize: '9px',
                      }}>×</button>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Budget alerts */}
          {budgetProgress.filter((b) => b.pct >= 80).map((b) => (
            <div key={b.catId} style={{ padding: '0 20px', marginBottom: '8px' }}>
              <div style={{
                background: b.pct >= 100 ? 'rgba(224,112,96,0.1)' : 'rgba(212,165,116,0.1)',
                border: `1px solid ${b.pct >= 100 ? 'rgba(224,112,96,0.3)' : 'rgba(212,165,116,0.3)'}`,
                borderRadius: '12px', padding: '10px 12px', display: 'flex', alignItems: 'center', gap: '10px',
              }}>
                <AlertCircle size={16} color={b.pct >= 100 ? t.danger : t.accent} />
                <div style={{ flex: 1, fontSize: '12px', color: b.pct >= 100 ? t.danger : t.accent }}>
                  {b.emoji} <strong>{b.label}</strong> {b.pct >= 100 ? 'exceeded' : `${Math.round(b.pct)}% used`} — {formatMoney(b.spent)} / {formatMoney(b.limit)}
                </div>
              </div>
            </div>
          ))}

          {/* Recent */}
          <div style={{ padding: '0 20px' }}>
            <div style={{ fontSize: '11px', letterSpacing: '1.5px', color: t.textMute, textTransform: 'uppercase', marginBottom: '10px', marginTop: '6px' }}>Recent</div>
            {transactions.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '40px 20px', color: t.textDim }}>
                <Wallet size={44} style={{ opacity: 0.3, marginBottom: '12px' }} />
                <div style={{ fontFamily: '"Fraunces", serif', fontSize: '16px', marginBottom: '6px', color: t.textMute }}>No entries yet</div>
                <div style={{ fontSize: '13px' }}>Tap + to add your first record</div>
              </div>
            ) : (
              Object.entries(grouped).slice(0, 3).map(([day, items]) => (
                <DayGroup key={day} day={day} items={items} t={t} theme={theme} getCat={getCat} getWallet={getWallet} formatMoney={formatMoney}
                  onEdit={(tr) => { setEditingTx(tr); setModal('add'); }}
                  onDelete={removeTransaction}
                  onSaveQuick={(tr) => {
                    if (quickActions.find((q) => q.category === tr.category && q.amount === tr.amount && q.note === tr.note)) return;
                    if (quickActions.length >= 6) return;
                    savedSet('quickActions', setQuickActions, [...quickActions, { id: Date.now(), category: tr.category, amount: tr.amount, note: tr.note, type: tr.type, walletId: tr.walletId }]);
                  }}
                />
              ))
            )}
          </div>
        </>
      )}

      {/* STATS */}
      {tab === 'stats' && (
        <div style={{ padding: '0 20px' }}>
          <div style={{ display: 'flex', background: t.surface, borderRadius: '12px', padding: '4px', marginBottom: '14px', border: `1px solid ${t.border}` }}>
            {['week','month','year'].map((p) => (
              <button key={p} onClick={() => setStatsPeriod(p)} style={{
                flex: 1, padding: '8px', borderRadius: '8px',
                background: statsPeriod === p ? t.accent : 'transparent',
                color: statsPeriod === p ? (theme === 'dark' ? '#1a1410' : '#fff') : t.textMute,
                fontWeight: 600, fontSize: '12px', textTransform: 'capitalize',
              }}>{p}</button>
            ))}
          </div>

          <Card t={t}>
            <CardTitle t={t}>{statsPeriod === 'week' ? 'Last 7 days' : statsPeriod === 'year' ? 'This year' : 'This month'}</CardTitle>
            {byCategory.length === 0 ? (
              <Empty t={t} icon={BarChart3} text="No expenses yet" />
            ) : (
              <>
                <PieChartView data={byCategory} total={byCategory.reduce((s, c) => s + c.total, 0)} t={t} formatMoney={formatMoney} />
                <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', marginTop: '14px' }}>
                  {byCategory.map((c) => {
                    const total = byCategory.reduce((s, x) => s + x.total, 0);
                    const pct = total > 0 ? (c.total / total) * 100 : 0;
                    return (
                      <div key={c.id} style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '6px 0' }}>
                        <div style={{ width: '10px', height: '10px', background: c.color, borderRadius: '3px' }} />
                        <span style={{ fontSize: '18px' }}>{c.emoji}</span>
                        <div style={{ flex: 1, fontSize: '13px', fontWeight: 500 }}>{c.label}</div>
                        <div style={{ fontSize: '11px', color: t.textMute }}>{pct.toFixed(0)}%</div>
                        <div style={{ fontFamily: '"Fraunces", serif', fontWeight: 600, fontSize: '13px', minWidth: '60px', textAlign: 'right' }}>
                          {formatMoney(c.total)}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </>
            )}
          </Card>

          <Card t={t}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <CardTitle t={t} noMargin>Budgets</CardTitle>
              <button onClick={() => setModal('budget')} style={{ background: t.accent, color: theme === 'dark' ? '#1a1410' : '#fff', borderRadius: '8px', padding: '5px 10px', fontSize: '12px', fontWeight: 600 }}>Manage</button>
            </div>
            {budgetProgress.length === 0 ? (
              <div style={{ fontSize: '13px', color: t.textMute, textAlign: 'center', padding: '16px 0' }}>Set monthly limits per category</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                {budgetProgress.map((b) => (
                  <div key={b.catId}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '4px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ fontSize: '14px' }}>{b.emoji}</span>
                        <span style={{ fontSize: '13px', fontWeight: 500 }}>{b.label}</span>
                      </div>
                      <div style={{ fontSize: '11px', color: t.textMute, fontFamily: '"Fraunces", serif' }}>
                        {formatMoney(b.spent)} / {formatMoney(b.limit)}
                      </div>
                    </div>
                    <div style={{ height: '5px', background: t.surfaceAlt, borderRadius: '3px', overflow: 'hidden' }}>
                      <div style={{ height: '100%', width: `${Math.min(b.pct, 100)}%`, background: b.pct >= 100 ? t.danger : b.pct >= 80 ? t.accent : b.color, transition: 'width 0.3s' }} />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Card>
        </div>
      )}

      {/* CALENDAR */}
      {tab === 'calendar' && (
        <CalendarView calMonth={calMonth} setCalMonth={setCalMonth} transactions={transactions} t={t} formatMoney={formatMoney} getCat={getCat} theme={theme} />
      )}

      {/* PLANS */}
      {tab === 'plans' && (
        <div style={{ padding: '0 20px' }}>
          {/* Recurring */}
          <Card t={t}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Repeat size={16} color={t.accent} />
                <CardTitle t={t} noMargin>Recurring</CardTitle>
              </div>
              <button onClick={() => setModal('recurring')} style={{ background: t.accent, color: theme === 'dark' ? '#1a1410' : '#fff', borderRadius: '8px', padding: '5px 10px', fontSize: '12px', fontWeight: 600 }}>+ Add</button>
            </div>
            {recurring.length === 0 ? (
              <div style={{ fontSize: '13px', color: t.textMute, textAlign: 'center', padding: '12px 0' }}>Salary, rent — auto-added on schedule</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                {recurring.map((r) => {
                  const c = getCat(r.category);
                  return (
                    <div key={r.id} style={{ background: t.surfaceAlt, border: `1px solid ${t.border}`, borderRadius: '10px', padding: '10px 12px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                      <span style={{ fontSize: '18px' }}>{c.emoji}</span>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontSize: '13px', fontWeight: 500 }}>{r.note || c.label}</div>
                        <div style={{ fontSize: '11px', color: t.textMute, textTransform: 'capitalize' }}>{r.freq}</div>
                      </div>
                      <div style={{ fontFamily: '"Fraunces", serif', fontWeight: 600, fontSize: '13px', color: r.type === 'income' ? t.income : t.expense }}>
                        {r.type === 'income' ? '+' : '−'}{formatMoney(r.amount)}
                      </div>
                      <button onClick={() => savedSet('recurring', setRecurring, recurring.filter((x) => x.id !== r.id))} style={{ background: 'transparent', color: t.textDim, padding: '3px', display: 'flex' }}>
                        <Trash2 size={14} />
                      </button>
                    </div>
                  );
                })}
              </div>
            )}
          </Card>

          <Card t={t}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Plane size={16} color={t.accent} />
                <CardTitle t={t} noMargin>Trips</CardTitle>
              </div>
              <button onClick={() => setModal('trip')} style={{ background: t.accent, color: theme === 'dark' ? '#1a1410' : '#fff', borderRadius: '8px', padding: '5px 10px', fontSize: '12px', fontWeight: 600 }}>+ Add</button>
            </div>
            {trips.length === 0 ? (
              <div style={{ fontSize: '13px', color: t.textMute, textAlign: 'center', padding: '12px 0' }}>Track expenses per trip</div>
            ) : trips.map((tp) => {
              const tpExp = transactions.filter((tr) => tr.tripId === tp.id).reduce((s, tr) => s + tr.amount, 0);
              const isActive = activeTrip === tp.id;
              const pct = tp.budget > 0 ? (tpExp / tp.budget) * 100 : 0;
              return (
                <div key={tp.id} style={{
                  background: isActive ? 'rgba(106,180,212,0.1)' : t.surfaceAlt,
                  border: `1px solid ${isActive ? 'rgba(106,180,212,0.4)' : t.border}`,
                  borderRadius: '12px', padding: '10px 12px', marginBottom: '6px',
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: tp.budget > 0 ? '6px' : 0 }}>
                    <div>
                      <div style={{ fontWeight: 600, fontSize: '14px' }}>{tp.name}</div>
                      <div style={{ fontSize: '11px', color: t.textMute }}>
                        {formatMoney(tpExp)}{tp.budget > 0 && ` / ${formatMoney(tp.budget)}`}
                      </div>
                    </div>
                    <div style={{ display: 'flex', gap: '4px' }}>
                      <button onClick={() => savedSet('activeTrip', setActiveTrip, isActive ? null : tp.id)} style={{
                        background: isActive ? t.danger : t.accent, color: '#fff',
                        borderRadius: '6px', padding: '4px 8px', fontSize: '11px', fontWeight: 600,
                      }}>{isActive ? 'Stop' : 'Start'}</button>
                      <button onClick={() => savedSet('trips', setTrips, trips.filter((x) => x.id !== tp.id))} style={{ background: 'transparent', color: t.textDim, padding: '3px', display: 'flex' }}>
                        <Trash2 size={13} />
                      </button>
                    </div>
                  </div>
                  {tp.budget > 0 && (
                    <div style={{ height: '4px', background: t.surface, borderRadius: '2px', overflow: 'hidden' }}>
                      <div style={{ height: '100%', width: `${Math.min(pct, 100)}%`, background: pct >= 100 ? t.danger : '#6ab4d4' }} />
                    </div>
                  )}
                </div>
              );
            })}
          </Card>

          <Card t={t}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Target size={16} color={t.accent} />
                <CardTitle t={t} noMargin>Savings Goals</CardTitle>
              </div>
              <button onClick={() => setModal('goal')} style={{ background: t.accent, color: theme === 'dark' ? '#1a1410' : '#fff', borderRadius: '8px', padding: '5px 10px', fontSize: '12px', fontWeight: 600 }}>+ Add</button>
            </div>
            {goals.length === 0 ? (
              <div style={{ fontSize: '13px', color: t.textMute, textAlign: 'center', padding: '12px 0' }}>Set a saving target</div>
            ) : goals.map((g) => {
              const pct = g.target > 0 ? (g.saved / g.target) * 100 : 0;
              return (
                <div key={g.id} style={{ marginBottom: '10px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span style={{ fontSize: '16px' }}>{g.emoji}</span>
                      <span style={{ fontWeight: 500, fontSize: '13px' }}>{g.name}</span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <span style={{ fontSize: '11px', color: t.textMute, fontFamily: '"Fraunces", serif' }}>
                        {formatMoney(g.saved)} / {formatMoney(g.target)}
                      </span>
                      <button onClick={() => {
                        const a = prompt('Add to savings:');
                        const n = parseFloat((a || '').replace(',', '.'));
                        if (n > 0) savedSet('goals', setGoals, goals.map((x) => x.id === g.id ? { ...x, saved: x.saved + n } : x));
                      }} style={{ background: t.accent, color: '#fff', borderRadius: '5px', padding: '2px 6px', fontSize: '11px' }}>+</button>
                      <button onClick={() => savedSet('goals', setGoals, goals.filter((x) => x.id !== g.id))} style={{ background: 'transparent', color: t.textDim, padding: '2px', display: 'flex' }}>
                        <Trash2 size={13} />
                      </button>
                    </div>
                  </div>
                  <div style={{ height: '5px', background: t.surfaceAlt, borderRadius: '3px', overflow: 'hidden' }}>
                    <div style={{ height: '100%', width: `${Math.min(pct, 100)}%`, background: t.accent }} />
                  </div>
                </div>
              );
            })}
          </Card>

          <Card t={t}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Sparkles size={16} color={t.accent} />
                <CardTitle t={t} noMargin>Subscriptions</CardTitle>
              </div>
              <button onClick={() => setModal('sub')} style={{ background: t.accent, color: theme === 'dark' ? '#1a1410' : '#fff', borderRadius: '8px', padding: '5px 10px', fontSize: '12px', fontWeight: 600 }}>+ Add</button>
            </div>
            {subscriptions.length === 0 ? (
              <div style={{ fontSize: '13px', color: t.textMute, textAlign: 'center', padding: '12px 0' }}>Netflix, Spotify, gym...</div>
            ) : (
              <>
                {subscriptions.map((s) => (
                  <div key={s.id} style={{ background: t.surfaceAlt, border: `1px solid ${t.border}`, borderRadius: '10px', padding: '8px 12px', display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '6px' }}>
                    <span style={{ fontSize: '18px' }}>{s.emoji || '📺'}</span>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 500, fontSize: '13px' }}>{s.name}</div>
                      <div style={{ fontSize: '10px', color: t.textMute }}>{s.period}</div>
                    </div>
                    <div style={{ fontFamily: '"Fraunces", serif', fontWeight: 600, fontSize: '13px' }}>{formatMoney(s.amount)}</div>
                    <button onClick={() => savedSet('subscriptions', setSubscriptions, subscriptions.filter((x) => x.id !== s.id))} style={{ background: 'transparent', color: t.textDim, padding: '3px', display: 'flex' }}>
                      <Trash2 size={13} />
                    </button>
                  </div>
                ))}
                <div style={{ padding: '8px 12px', background: t.surfaceAlt, borderRadius: '10px', display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginTop: '4px' }}>
                  <span style={{ color: t.textMute }}>Monthly total</span>
                  <span style={{ fontFamily: '"Fraunces", serif', fontWeight: 600, color: t.expense }}>
                    {formatMoney(subscriptions.reduce((s, x) => s + (x.period === 'Monthly' ? x.amount : x.amount / 12), 0))}
                  </span>
                </div>
              </>
            )}
          </Card>
        </div>
      )}

      {/* ALL */}
      {tab === 'all' && (
        <div style={{ padding: '0 20px' }}>
          {Object.entries(grouped).length === 0 ? (
            <Empty t={t} icon={Wallet} text="No transactions" />
          ) : Object.entries(grouped).map(([day, items]) => (
            <DayGroup key={day} day={day} items={items} t={t} theme={theme} getCat={getCat} getWallet={getWallet} formatMoney={formatMoney}
              onEdit={(tr) => { setEditingTx(tr); setModal('add'); }}
              onDelete={removeTransaction}
              onSaveQuick={(tr) => {
                if (quickActions.find((q) => q.category === tr.category && q.amount === tr.amount && q.note === tr.note)) return;
                if (quickActions.length >= 6) return;
                savedSet('quickActions', setQuickActions, [...quickActions, { id: Date.now(), category: tr.category, amount: tr.amount, note: tr.note, type: tr.type, walletId: tr.walletId }]);
              }}
            />
          ))}
        </div>
      )}

      {/* Bottom nav */}
      <div style={{
        position: 'fixed', bottom: 0, left: 0, right: 0, background: t.surface, borderTop: `1px solid ${t.border}`,
        display: 'flex', justifyContent: 'space-around', padding: '6px 0 22px', zIndex: 50,
      }}>
        {[
          { id: 'home', icon: Home, label: 'Home' },
          { id: 'stats', icon: BarChart3, label: 'Stats' },
          { id: 'calendar', icon: Calendar, label: 'Calendar' },
          { id: 'plans', icon: Target, label: 'Plans' },
          { id: 'all', icon: Wallet, label: 'All' },
        ].map((nav) => (
          <button key={nav.id} onClick={() => setTab(nav.id)} style={{
            background: 'transparent', color: tab === nav.id ? t.accent : t.textMute,
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '2px', padding: '4px 8px',
          }}>
            <nav.icon size={18} />
            <span style={{ fontSize: '9px', fontWeight: 500 }}>{nav.label}</span>
          </button>
        ))}
      </div>

      {/* FAB */}
      <button onClick={() => { setEditingTx(null); setModal('add'); }} style={{
        position: 'fixed', bottom: '84px', right: '20px',
        width: '56px', height: '56px', borderRadius: '50%',
        background: `linear-gradient(135deg, ${t.accent} 0%, ${t.accentAlt} 100%)`,
        color: theme === 'dark' ? '#1a1410' : '#fff',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 8px 24px rgba(212,165,116,0.4)', zIndex: 51,
      }}>
        <Plus size={24} strokeWidth={2.5} />
      </button>

      {/* Modals */}
      {modal === 'add' && <AddModal t={t} theme={theme} editingTx={editingTx} categories={categories} wallets={wallets} currency={currency} currencyCode={currencyCode} activeTrip={activeTrip} onClose={() => { setModal(null); setEditingTx(null); }} onSave={(tx) => { upsertTransaction(tx); setModal(null); setEditingTx(null); }} onAddCategory={(type) => { setEditingCat({ id: 'new_' + Date.now(), label: '', emoji: '📌', color: COLOR_CHOICES[0], type }); setModal('category'); }} />}
      {modal === 'category' && <CategoryModal t={t} theme={theme} cat={editingCat} categories={categories} onSaveCat={(newCat) => {
        const isExpense = newCat.type === 'expense' || categories.expense.find((c) => c.id === newCat.id);
        const key = isExpense ? 'expense' : 'income';
        const list = categories[key];
        const newList = list.find((c) => c.id === newCat.id) ? list.map((c) => c.id === newCat.id ? newCat : c) : [...list, newCat];
        savedSet('categories', setCategories, { ...categories, [key]: newList });
        setModal('add');
      }} onDeleteCat={(id) => {
        const expHas = categories.expense.find((c) => c.id === id);
        const key = expHas ? 'expense' : 'income';
        const cat = categories[key].find((c) => c.id === id);
        if (cat?.isDefault) return alert("Can't delete default categories");
        savedSet('categories', setCategories, { ...categories, [key]: categories[key].filter((c) => c.id !== id) });
        setModal('add');
      }} onClose={() => setModal('add')} />}
      {modal === 'wallet' && <WalletModal t={t} theme={theme} wallet={editingWallet} onSave={(w) => {
        const newList = wallets.find((x) => x.id === w.id) ? wallets.map((x) => x.id === w.id ? w : x) : [...wallets, w];
        savedSet('wallets', setWallets, newList);
        setModal(null); setEditingWallet(null);
      }} onDelete={(id) => {
        const w = wallets.find((x) => x.id === id);
        if (w?.isDefault) return alert("Can't delete default wallets");
        if (transactions.some((tr) => tr.walletId === id)) {
          if (!confirm('Wallet has transactions. Delete anyway? Transactions will keep historical data.')) return;
        }
        savedSet('wallets', setWallets, wallets.filter((x) => x.id !== id));
        setModal(null); setEditingWallet(null);
      }} onClose={() => { setModal(null); setEditingWallet(null); }} />}
      {modal === 'currency' && <CurrencyModal t={t} currencyCode={currencyCode} onSelect={(c) => { savedSet('currency', setCurrencyCode, c); setModal(null); }} onClose={() => setModal(null)} />}
      {modal === 'search' && <SearchModal t={t} searchQ={searchQ} setSearchQ={setSearchQ} filteredTx={filteredTx} getCat={getCat} fmtDate={fmtDate} formatMoney={formatMoney} onClose={() => { setSearchQ(''); setModal(null); }} />}
      {modal === 'settings' && <SettingsModal t={t} theme={theme} currencyCode={currencyCode} onSwitchTheme={() => savedSet('theme', setTheme, theme === 'dark' ? 'light' : 'dark')} onChangeCurrency={() => setModal('currency')} onExportCSV={() => { exportCSV(); setModal(null); }} onBackup={() => { exportBackup(); setModal(null); }} onRestore={importBackup} onClose={() => setModal(null)} />}
      {modal === 'budget' && <BudgetModal t={t} budgets={budgets} categories={categories.expense} onSave={(b) => savedSet('budgets', setBudgets, b)} onClose={() => setModal(null)} />}
      {modal === 'trip' && <TripModal t={t} theme={theme} onSave={(tp) => { savedSet('trips', setTrips, [...trips, tp]); setModal(null); }} onClose={() => setModal(null)} />}
      {modal === 'goal' && <GoalModal t={t} theme={theme} onSave={(g) => { savedSet('goals', setGoals, [...goals, g]); setModal(null); }} onClose={() => setModal(null)} />}
      {modal === 'sub' && <SubModal t={t} theme={theme} onSave={(s) => { savedSet('subscriptions', setSubscriptions, [...subscriptions, s]); setModal(null); }} onClose={() => setModal(null)} />}
      {modal === 'recurring' && <RecurringModal t={t} theme={theme} categories={categories} wallets={wallets} currency={currency} onSave={(r) => { savedSet('recurring', setRecurring, [...recurring, r]); setModal(null); }} onClose={() => setModal(null)} />}
    </div>
  );
}

// ===== Onboarding =====
function Onboarding({ t, onFinish }) {
  const [step, setStep] = useState(0);
  const steps = [
    { emoji: '👋', title: 'Welcome', desc: 'A simple way to track money with multi-currency, multi-wallet, and powerful insights.' },
    { emoji: '💳', title: 'Multiple Wallets', desc: 'Cash, Card, Savings — track each one separately and see your total at a glance.' },
    { emoji: '🌍', title: 'Travel Friendly', desc: 'Switch currencies anytime. Use Trip mode to track expenses for a specific journey.' },
    { emoji: '🔒', title: 'Privacy First', desc: 'Your data stays on your device. No bank logins, no servers, no ads. Use backup to keep it safe.' },
  ];
  const s = steps[step];
  return (
    <div style={{ minHeight: '100vh', background: t.bg, color: t.text, display: 'flex', flexDirection: 'column', padding: '40px 24px', fontFamily: '"SF Pro Display", system-ui, sans-serif' }}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,600&display=swap');`}</style>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', textAlign: 'center' }}>
        <div style={{ fontSize: '72px', marginBottom: '20px' }}>{s.emoji}</div>
        <div style={{ fontFamily: '"Fraunces", serif', fontSize: '32px', fontWeight: 600, marginBottom: '12px' }}>{s.title}</div>
        <div style={{ fontSize: '15px', color: t.textMute, lineHeight: 1.5, maxWidth: '320px', margin: '0 auto' }}>{s.desc}</div>
      </div>
      <div style={{ display: 'flex', justifyContent: 'center', gap: '6px', marginBottom: '24px' }}>
        {steps.map((_, i) => (
          <div key={i} style={{ width: '8px', height: '8px', borderRadius: '50%', background: i === step ? t.accent : t.border }} />
        ))}
      </div>
      <button onClick={() => step < steps.length - 1 ? setStep(step + 1) : onFinish()} style={{
        background: `linear-gradient(135deg, ${t.accent} 0%, ${t.accentAlt} 100%)`,
        color: '#1a1410', border: 'none', borderRadius: '14px', padding: '16px', fontWeight: 600, fontSize: '16px', cursor: 'pointer',
      }}>{step < steps.length - 1 ? 'Continue' : 'Get Started'}</button>
      {step > 0 && (
        <button onClick={() => setStep(0)} style={{ background: 'transparent', color: t.textMute, padding: '10px', marginTop: '8px', fontSize: '13px' }}>
          Skip
        </button>
      )}
    </div>
  );
}

// ===== Helpers =====
function IconButton({ t, onClick, children }) {
  return <button onClick={onClick} style={{ background: t.surface, border: `1px solid ${t.border}`, borderRadius: '12px', padding: '8px', color: t.textMute, display: 'flex' }}>{children}</button>;
}
function Card({ t, children }) {
  return <div style={{ background: t.surface, border: `1px solid ${t.border}`, borderRadius: '18px', padding: '18px', marginBottom: '14px' }}>{children}</div>;
}
function CardTitle({ t, children, noMargin }) {
  return <div style={{ fontFamily: '"Fraunces", serif', fontSize: '17px', fontWeight: 600, marginBottom: noMargin ? 0 : '12px', color: t.text }}>{children}</div>;
}
function Empty({ t, icon: Icon, text }) {
  return (
    <div style={{ textAlign: 'center', padding: '30px 20px', color: t.textDim }}>
      <Icon size={40} style={{ opacity: 0.3, marginBottom: '10px' }} />
      <div style={{ fontSize: '13px' }}>{text}</div>
    </div>
  );
}
function Label({ t, children }) {
  return <div style={{ fontSize: '10px', color: t.textMute, letterSpacing: '1px', textTransform: 'uppercase', marginBottom: '6px' }}>{children}</div>;
}
function Modal({ onClose, t, title, children, extraAction }) {
  return (
    <div onClick={onClose} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(8px)', zIndex: 100, display: 'flex', alignItems: 'flex-end', animation: 'fadeIn 0.2s' }}>
      <div onClick={(e) => e.stopPropagation()} style={{
        width: '100%', background: t.surface, borderTopLeftRadius: '20px', borderTopRightRadius: '20px',
        padding: '18px 20px 28px', animation: 'slideUp 0.3s ease-out', maxHeight: '90vh', overflowY: 'auto',
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '18px' }}>
          <div style={{ fontFamily: '"Fraunces", serif', fontSize: '19px', fontWeight: 600, color: t.text }}>{title}</div>
          <div style={{ display: 'flex', gap: '6px' }}>
            {extraAction}
            <button onClick={onClose} style={{ background: t.surfaceAlt, color: t.textMute, padding: '7px', borderRadius: '50%', display: 'flex' }}>
              <X size={16} />
            </button>
          </div>
        </div>
        {children}
      </div>
    </div>
  );
}
function inputStyle(t) {
  return { width: '100%', background: t.surfaceAlt, border: `1px solid ${t.border}`, borderRadius: '12px', padding: '12px 14px', color: t.text, fontSize: '14px', outline: 'none' };
}
function PrimaryBtn({ t, theme, onClick, disabled, children }) {
  return (
    <button onClick={onClick} disabled={disabled} style={{
      width: '100%', padding: '14px', background: disabled ? t.surfaceAlt : `linear-gradient(135deg, ${t.accent} 0%, ${t.accentAlt} 100%)`,
      color: disabled ? t.textDim : (theme === 'dark' ? '#1a1410' : '#fff'),
      borderRadius: '12px', fontWeight: 600, fontSize: '15px',
    }}>{children}</button>
  );
}

function DayGroup({ day, items, t, theme, getCat, getWallet, formatMoney, onEdit, onDelete, onSaveQuick }) {
  return (
    <div style={{ marginBottom: '16px' }}>
      <div style={{ fontSize: '10px', letterSpacing: '1.5px', textTransform: 'uppercase', color: t.textMute, marginBottom: '6px' }}>{day}</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
        {items.map((tr) => {
          const c = getCat(tr.category);
          const w = getWallet(tr.walletId);
          return (
            <div key={tr.id} onClick={() => onEdit(tr)} style={{
              background: t.surface, border: `1px solid ${t.border}`, borderRadius: '12px',
              padding: '10px 12px', display: 'flex', alignItems: 'center', gap: '10px',
              animation: 'pop 0.2s ease-out', cursor: 'pointer',
            }}>
              <div style={{
                width: '34px', height: '34px',
                background: tr.type === 'income' ? 'rgba(122,156,122,0.15)' : `${c.color}25`,
                borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '16px',
              }}>{c.emoji}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 500, fontSize: '13px', marginBottom: '1px' }}>{c.label}</div>
                <div style={{ fontSize: '11px', color: t.textMute, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {w.emoji} {w.name}{tr.note ? ` · ${tr.note}` : ''}
                </div>
              </div>
              <div style={{ fontFamily: '"Fraunces", serif', fontWeight: 600, fontSize: '13px', color: tr.type === 'income' ? t.income : t.expense, whiteSpace: 'nowrap' }}>
                {formatMoney(tr.amount, tr.type === 'income' ? '+' : '−')}
              </div>
              <button onClick={(e) => { e.stopPropagation(); onSaveQuick(tr); }} title="Save as quick action" style={{ background: 'transparent', color: t.textDim, padding: '3px', display: 'flex' }}>
                <Repeat size={13} />
              </button>
              <button onClick={(e) => { e.stopPropagation(); onDelete(tr.id); }} style={{ background: 'transparent', color: t.textDim, padding: '3px', display: 'flex' }}>
                <Trash2 size={13} />
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function PieChartView({ data, total, t, formatMoney }) {
  if (!data.length || total === 0) return null;
  const size = 170, radius = size / 2 - 10;
  const cx = size / 2, cy = size / 2;
  let cumAngle = -Math.PI / 2;
  return (
    <div style={{ display: 'flex', justifyContent: 'center' }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        {data.map((c, i) => {
          const angle = (c.total / total) * 2 * Math.PI;
          const x1 = cx + radius * Math.cos(cumAngle);
          const y1 = cy + radius * Math.sin(cumAngle);
          cumAngle += angle;
          const x2 = cx + radius * Math.cos(cumAngle);
          const y2 = cy + radius * Math.sin(cumAngle);
          const large = angle > Math.PI ? 1 : 0;
          const path = `M ${cx} ${cy} L ${x1} ${y1} A ${radius} ${radius} 0 ${large} 1 ${x2} ${y2} Z`;
          return <path key={i} d={path} fill={c.color} stroke={t.surface} strokeWidth="2" />;
        })}
        <circle cx={cx} cy={cy} r={radius * 0.55} fill={t.surface} />
        <text x={cx} y={cy - 4} textAnchor="middle" fill={t.textMute} fontSize="10" letterSpacing="1.5">SPENT</text>
        <text x={cx} y={cy + 14} textAnchor="middle" fill={t.text} fontSize="16" fontWeight="600" fontFamily="Fraunces, serif">{formatMoney(total)}</text>
      </svg>
    </div>
  );
}

function CalendarView({ calMonth, setCalMonth, transactions, t, formatMoney, getCat, theme }) {
  const year = calMonth.getFullYear(), month = calMonth.getMonth();
  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);
  const startWeekday = firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1; // Mon=0
  const days = [];
  for (let i = 0; i < startWeekday; i++) days.push(null);
  for (let d = 1; d <= lastDay.getDate(); d++) days.push(d);

  const dayTotals = useMemo(() => {
    const map = {};
    transactions.forEach((tr) => {
      const d = new Date(tr.date);
      if (d.getMonth() === month && d.getFullYear() === year) {
        const day = d.getDate();
        if (!map[day]) map[day] = { income: 0, expense: 0 };
        map[day][tr.type] += tr.amount;
      }
    });
    return map;
  }, [transactions, month, year]);

  const [selDay, setSelDay] = useState(null);
  const today = new Date();
  const isCurMonth = today.getMonth() === month && today.getFullYear() === year;

  const dayTx = transactions.filter((tr) => {
    const d = new Date(tr.date);
    return d.getMonth() === month && d.getFullYear() === year && d.getDate() === selDay;
  });

  return (
    <div style={{ padding: '0 20px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
        <button onClick={() => setCalMonth(new Date(year, month - 1, 1))} style={{ background: t.surface, border: `1px solid ${t.border}`, borderRadius: '10px', padding: '8px', color: t.text, display: 'flex' }}>
          <ChevronLeft size={16} />
        </button>
        <div style={{ fontFamily: '"Fraunces", serif', fontSize: '17px', fontWeight: 600 }}>
          {calMonth.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}
        </div>
        <button onClick={() => setCalMonth(new Date(year, month + 1, 1))} style={{ background: t.surface, border: `1px solid ${t.border}`, borderRadius: '10px', padding: '8px', color: t.text, display: 'flex' }}>
          <ChevronRight size={16} />
        </button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: '4px', marginBottom: '6px' }}>
        {['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].map((d) => (
          <div key={d} style={{ textAlign: 'center', fontSize: '10px', color: t.textMute, fontWeight: 600, padding: '4px' }}>{d}</div>
        ))}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: '4px' }}>
        {days.map((d, i) => {
          if (!d) return <div key={i} />;
          const tot = dayTotals[d];
          const isToday = isCurMonth && today.getDate() === d;
          const sel = selDay === d;
          return (
            <button key={i} onClick={() => setSelDay(sel ? null : d)} style={{
              aspectRatio: '1', background: sel ? t.accent : tot ? t.surface : 'transparent',
              border: `1px solid ${isToday ? t.accent : tot ? t.border : 'transparent'}`,
              borderRadius: '8px', padding: '4px', color: sel ? '#1a1410' : t.text,
              display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '2px',
            }}>
              <div style={{ fontSize: '13px', fontWeight: isToday ? 700 : 500 }}>{d}</div>
              {tot && (
                <div style={{ fontSize: '8px', color: sel ? '#1a1410' : (tot.expense > tot.income ? t.expense : t.income), fontFamily: '"Fraunces", serif', fontWeight: 600 }}>
                  {tot.expense > 0 ? `−${Math.round(tot.expense)}` : `+${Math.round(tot.income)}`}
                </div>
              )}
            </button>
          );
        })}
      </div>

      {selDay && (
        <Card t={t}>
          <CardTitle t={t}>{new Date(year, month, selDay).toLocaleDateString('en-US', { weekday: 'long', day: 'numeric', month: 'long' })}</CardTitle>
          {dayTx.length === 0 ? (
            <div style={{ fontSize: '13px', color: t.textMute, textAlign: 'center', padding: '12px 0' }}>No transactions this day</div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
              {dayTx.map((tr) => {
                const c = getCat(tr.category);
                return (
                  <div key={tr.id} style={{ background: t.surfaceAlt, border: `1px solid ${t.border}`, borderRadius: '10px', padding: '8px 12px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <span style={{ fontSize: '18px' }}>{c.emoji}</span>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '13px', fontWeight: 500 }}>{c.label}</div>
                      {tr.note && <div style={{ fontSize: '11px', color: t.textMute }}>{tr.note}</div>}
                    </div>
                    <div style={{ fontFamily: '"Fraunces", serif', fontWeight: 600, fontSize: '13px', color: tr.type === 'income' ? t.income : t.expense }}>
                      {formatMoney(tr.amount, tr.type === 'income' ? '+' : '−')}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </Card>
      )}
    </div>
  );
}

function AddModal({ t, theme, editingTx, categories, wallets, currency, currencyCode, activeTrip, onClose, onSave, onAddCategory }) {
  const isEdit = !!editingTx;
  const [type, setType] = useState(editingTx?.type || 'expense');
  const [amount, setAmount] = useState(editingTx ? String(editingTx.amount) : '');
  const [category, setCategory] = useState(editingTx?.category || categories.expense[0].id);
  const [walletId, setWalletId] = useState(editingTx?.walletId || wallets[0].id);
  const [note, setNote] = useState(editingTx?.note || '');
  const [tags, setTags] = useState((editingTx?.tags || []).join(', '));
  const [date, setDate] = useState(editingTx?.date.slice(0, 10) || new Date().toISOString().slice(0, 10));

  const cats = type === 'expense' ? categories.expense : categories.income;
  useEffect(() => {
    if (!cats.find((c) => c.id === category)) setCategory(cats[0].id);
  }, [type]);

  const handleSave = () => {
    const value = parseFloat(amount.replace(',', '.'));
    if (!value || value <= 0) return;
    const tx = {
      id: editingTx?.id || Date.now() + Math.random(),
      type, amount: value, currency: currencyCode,
      category, walletId, note: note.trim(),
      tags: tags.split(',').map((s) => s.trim()).filter(Boolean),
      tripId: type === 'expense' && (editingTx?.tripId || activeTrip) ? (editingTx?.tripId || activeTrip) : null,
      date: new Date(date + 'T' + new Date().toTimeString().slice(0, 8)).toISOString(),
    };
    onSave(tx);
  };

  return (
    <Modal onClose={onClose} t={t} title={isEdit ? 'Edit Entry' : 'New Entry'}>
      <div style={{ display: 'flex', background: t.surfaceAlt, borderRadius: '12px', padding: '4px', marginBottom: '16px' }}>
        <button onClick={() => setType('expense')} style={{ flex: 1, padding: '9px', borderRadius: '10px', background: type === 'expense' ? t.expense : 'transparent', color: type === 'expense' ? '#fff' : t.textMute, fontWeight: 600, fontSize: '13px' }}>Expense</button>
        <button onClick={() => setType('income')} style={{ flex: 1, padding: '9px', borderRadius: '10px', background: type === 'income' ? t.income : 'transparent', color: type === 'income' ? '#fff' : t.textMute, fontWeight: 600, fontSize: '13px' }}>Income</button>
      </div>

      <Label t={t}>Amount ({currency.code})</Label>
      <div style={{ position: 'relative', marginBottom: '12px' }}>
        {currency.position === 'before' && <div style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: t.textMute, fontSize: '18px', fontFamily: '"Fraunces", serif', zIndex: 1 }}>{currency.symbol}</div>}
        <input
          type="text" inputMode="decimal" autoFocus value={amount}
          onChange={(e) => setAmount(e.target.value.replace(/[^0-9.,]/g, ''))}
          placeholder="0"
          style={{
            width: '100%', background: t.surfaceAlt, border: `1px solid ${t.border}`, borderRadius: '12px',
            padding: currency.position === 'before' ? '14px 44px 14px 38px' : '14px 50px 14px 14px',
            color: t.text, fontFamily: '"Fraunces", serif', fontSize: '24px', fontWeight: 600, outline: 'none',
          }}
        />
        {currency.position === 'after' && <div style={{ position: 'absolute', right: '14px', top: '50%', transform: 'translateY(-50%)', color: t.textMute, fontSize: '16px', fontFamily: '"Fraunces", serif' }}>{currency.symbol}</div>}
      </div>

      <Label t={t}>Wallet</Label>
      <div style={{ display: 'flex', gap: '6px', overflowX: 'auto', marginBottom: '12px', paddingBottom: '4px' }}>
        {wallets.map((w) => (
          <button key={w.id} onClick={() => setWalletId(w.id)} style={{
            flexShrink: 0, padding: '8px 12px', background: walletId === w.id ? t.surfaceAlt : 'transparent',
            border: `1px solid ${walletId === w.id ? t.accent : t.border}`, borderRadius: '10px',
            color: t.text, display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px',
          }}>
            <span>{w.emoji}</span><span>{w.name}</span>
          </button>
        ))}
      </div>

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
        <Label t={t}>Category</Label>
        <button onClick={() => onAddCategory(type)} style={{ background: 'transparent', color: t.accent, fontSize: '12px', fontWeight: 600 }}>+ New</button>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '6px', marginBottom: '12px' }}>
        {cats.map((c) => (
          <button key={c.id} onClick={() => setCategory(c.id)} style={{
            padding: '8px 4px', background: category === c.id ? t.surfaceAlt : 'transparent',
            border: `1px solid ${category === c.id ? t.accent : t.border}`, borderRadius: '10px', color: t.text,
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '3px',
          }}>
            <span style={{ fontSize: '18px' }}>{c.emoji}</span>
            <span style={{ fontSize: '9px', color: t.textMute }}>{c.label}</span>
          </button>
        ))}
      </div>

      <Label t={t}>Date</Label>
      <input type="date" value={date} onChange={(e) => setDate(e.target.value)} style={{ ...inputStyle(t), marginBottom: '12px' }} />

      <Label t={t}>Note (optional)</Label>
      <input type="text" value={note} onChange={(e) => setNote(e.target.value)} placeholder="e.g. lunch at café" style={{ ...inputStyle(t), marginBottom: '12px' }} />

      <Label t={t}>Tags (optional, comma-separated)</Label>
      <input type="text" value={tags} onChange={(e) => setTags(e.target.value)} placeholder="e.g. work, business trip" style={{ ...inputStyle(t), marginBottom: '16px' }} />

      <PrimaryBtn t={t} theme={theme} onClick={handleSave} disabled={!amount}>{isEdit ? 'Save Changes' : 'Save'}</PrimaryBtn>
    </Modal>
  );
}

function CategoryModal({ t, theme, cat, onSaveCat, onDeleteCat, onClose }) {
  const isNew = String(cat?.id || '').startsWith('new_');
  const [label, setLabel] = useState(cat?.label || '');
  const [emoji, setEmoji] = useState(cat?.emoji || '📌');
  const [color, setColor] = useState(cat?.color || COLOR_CHOICES[0]);
  const [type, setType] = useState(cat?.type || 'expense');
  return (
    <Modal onClose={onClose} t={t} title={isNew ? 'New Category' : 'Edit Category'}>
      {isNew && (
        <>
          <div style={{ display: 'flex', background: t.surfaceAlt, borderRadius: '12px', padding: '4px', marginBottom: '12px' }}>
            <button onClick={() => setType('expense')} style={{ flex: 1, padding: '8px', borderRadius: '10px', background: type === 'expense' ? t.expense : 'transparent', color: type === 'expense' ? '#fff' : t.textMute, fontWeight: 600, fontSize: '12px' }}>Expense</button>
            <button onClick={() => setType('income')} style={{ flex: 1, padding: '8px', borderRadius: '10px', background: type === 'income' ? t.income : 'transparent', color: type === 'income' ? '#fff' : t.textMute, fontWeight: 600, fontSize: '12px' }}>Income</button>
          </div>
        </>
      )}
      <Label t={t}>Name</Label>
      <input value={label} onChange={(e) => setLabel(e.target.value)} placeholder="e.g. Pets" style={{ ...inputStyle(t), marginBottom: '12px' }} />
      <Label t={t}>Icon</Label>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(8, 1fr)', gap: '4px', marginBottom: '12px' }}>
        {EMOJI_CHOICES.map((e) => (
          <button key={e} onClick={() => setEmoji(e)} style={{
            aspectRatio: '1', fontSize: '18px', background: emoji === e ? t.surfaceAlt : 'transparent',
            border: `1px solid ${emoji === e ? t.accent : t.border}`, borderRadius: '8px',
          }}>{e}</button>
        ))}
      </div>
      <Label t={t}>Color</Label>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginBottom: '16px' }}>
        {COLOR_CHOICES.map((cl) => (
          <button key={cl} onClick={() => setColor(cl)} style={{
            width: '32px', height: '32px', borderRadius: '50%', background: cl,
            border: color === cl ? `3px solid ${t.text}` : `1px solid ${t.border}`,
          }} />
        ))}
      </div>
      <PrimaryBtn t={t} theme={theme} onClick={() => {
        if (!label.trim()) return;
        const id = isNew ? `cat_${Date.now()}` : cat.id;
        onSaveCat({ ...cat, id, label: label.trim(), emoji, color, type, isDefault: false });
      }} disabled={!label.trim()}>{isNew ? 'Create' : 'Save'}</PrimaryBtn>
      {!isNew && !cat?.isDefault && (
        <button onClick={() => { if (confirm('Delete this category?')) onDeleteCat(cat.id); }} style={{
          width: '100%', padding: '12px', marginTop: '8px', background: 'transparent', color: t.danger, fontWeight: 600, fontSize: '14px',
        }}>Delete Category</button>
      )}
    </Modal>
  );
}

function WalletModal({ t, theme, wallet, onSave, onDelete, onClose }) {
  const isNew = String(wallet?.id || '').startsWith('new_');
  const [name, setName] = useState(wallet?.name || '');
  const [emoji, setEmoji] = useState(wallet?.emoji || '💵');
  const [color, setColor] = useState(wallet?.color || COLOR_CHOICES[0]);
  return (
    <Modal onClose={onClose} t={t} title={isNew ? 'New Wallet' : 'Edit Wallet'}>
      <Label t={t}>Name</Label>
      <input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Bank ABC" style={{ ...inputStyle(t), marginBottom: '12px' }} />
      <Label t={t}>Icon</Label>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(8, 1fr)', gap: '4px', marginBottom: '12px' }}>
        {['💵','💳','🐷','🏦','💰','💎','📱','🎁','💼','🎯','⭐','🪙'].map((e) => (
          <button key={e} onClick={() => setEmoji(e)} style={{
            aspectRatio: '1', fontSize: '20px', background: emoji === e ? t.surfaceAlt : 'transparent',
            border: `1px solid ${emoji === e ? t.accent : t.border}`, borderRadius: '8px',
          }}>{e}</button>
        ))}
      </div>
      <Label t={t}>Color</Label>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginBottom: '16px' }}>
        {COLOR_CHOICES.map((cl) => (
          <button key={cl} onClick={() => setColor(cl)} style={{ width: '32px', height: '32px', borderRadius: '50%', background: cl, border: color === cl ? `3px solid ${t.text}` : `1px solid ${t.border}` }} />
        ))}
      </div>
      <PrimaryBtn t={t} theme={theme} onClick={() => {
        if (!name.trim()) return;
        const id = isNew ? `wallet_${Date.now()}` : wallet.id;
        onSave({ ...wallet, id, name: name.trim(), emoji, color, isDefault: wallet?.isDefault || false });
      }} disabled={!name.trim()}>{isNew ? 'Create' : 'Save'}</PrimaryBtn>
      {!isNew && !wallet?.isDefault && (
        <button onClick={() => onDelete(wallet.id)} style={{ width: '100%', padding: '12px', marginTop: '8px', background: 'transparent', color: t.danger, fontWeight: 600, fontSize: '14px' }}>Delete Wallet</button>
      )}
    </Modal>
  );
}

function CurrencyModal({ t, currencyCode, onSelect, onClose }) {
  return (
    <Modal onClose={onClose} t={t} title="Choose Currency">
      <div style={{ display: 'flex', flexDirection: 'column', gap: '4px', maxHeight: '60vh', overflowY: 'auto' }}>
        {CURRENCIES.map((c) => {
          const active = c.code === currencyCode;
          return (
            <button key={c.code} onClick={() => onSelect(c.code)} style={{
              background: active ? t.surfaceAlt : 'transparent',
              border: `1px solid ${active ? t.accent : t.border}`,
              borderRadius: '10px', padding: '10px 12px',
              display: 'flex', alignItems: 'center', gap: '12px', color: t.text, textAlign: 'left',
            }}>
              <div style={{ width: '32px', height: '32px', background: active ? `${t.accent}30` : t.surfaceAlt, borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: '"Fraunces", serif', fontSize: '14px', fontWeight: 600, color: active ? t.accent : t.textMute }}>{c.symbol}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: '13px' }}>{c.code}</div>
                <div style={{ fontSize: '11px', color: t.textMute }}>{c.name}</div>
              </div>
              {active && <Check size={16} color={t.accent} />}
            </button>
          );
        })}
      </div>
    </Modal>
  );
}

function SearchModal({ t, searchQ, setSearchQ, filteredTx, getCat, fmtDate, formatMoney, onClose }) {
  return (
    <Modal onClose={onClose} t={t} title="Search">
      <input type="text" autoFocus value={searchQ} onChange={(e) => setSearchQ(e.target.value)} placeholder="Category, note, amount, tag, wallet..." style={inputStyle(t)} />
      <div style={{ marginTop: '14px', maxHeight: '50vh', overflowY: 'auto' }}>
        {searchQ.trim() && filteredTx.slice(0, 30).map((tr) => {
          const c = getCat(tr.category);
          return (
            <div key={tr.id} style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '8px 0', borderBottom: `1px solid ${t.border}` }}>
              <span style={{ fontSize: '18px' }}>{c.emoji}</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: '13px', fontWeight: 500 }}>{c.label}</div>
                <div style={{ fontSize: '11px', color: t.textMute, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{tr.note || fmtDate(tr.date)}</div>
              </div>
              <div style={{ fontFamily: '"Fraunces", serif', fontWeight: 600, fontSize: '13px', color: tr.type === 'income' ? t.income : t.expense }}>
                {formatMoney(tr.amount, tr.type === 'income' ? '+' : '−')}
              </div>
            </div>
          );
        })}
      </div>
    </Modal>
  );
}

function SettingsModal({ t, theme, currencyCode, onSwitchTheme, onChangeCurrency, onExportCSV, onBackup, onRestore, onClose }) {
  const fileRef = useRef();
  return (
    <Modal onClose={onClose} t={t} title="Settings">
      <input type="file" ref={fileRef} accept=".json" style={{ display: 'none' }} onChange={(e) => { if (e.target.files[0]) onRestore(e.target.files[0]); }} />
      <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
        <SettingRow t={t} icon={theme === 'dark' ? Sun : Moon} label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'} onClick={onSwitchTheme} />
        <SettingRow t={t} icon={Wallet} label={`Currency: ${currencyCode}`} onClick={onChangeCurrency} />
        <SettingRow t={t} icon={Download} label="Backup all data (JSON)" onClick={onBackup} />
        <SettingRow t={t} icon={Upload} label="Restore from backup" onClick={() => fileRef.current.click()} />
        <SettingRow t={t} icon={Download} label="Export transactions (CSV)" onClick={onExportCSV} />
      </div>
      <div style={{ marginTop: '16px', padding: '14px', background: t.surfaceAlt, borderRadius: '12px', fontSize: '11px', color: t.textMute, textAlign: 'center', lineHeight: 1.5 }}>
        Your data stays on this device. Make regular backups to keep it safe.
      </div>
    </Modal>
  );
}

function SettingRow({ t, icon: Icon, label, onClick }) {
  return (
    <button onClick={onClick} style={{
      background: t.surfaceAlt, border: `1px solid ${t.border}`, borderRadius: '10px',
      padding: '12px 14px', display: 'flex', alignItems: 'center', gap: '10px', color: t.text, textAlign: 'left', width: '100%',
    }}>
      <Icon size={16} color={t.accent} />
      <div style={{ flex: 1, fontSize: '13px', fontWeight: 500 }}>{label}</div>
      <ChevronRight size={14} color={t.textDim} />
    </button>
  );
}

function BudgetModal({ t, budgets, categories, onSave, onClose }) {
  return (
    <Modal onClose={onClose} t={t} title="Monthly Budgets">
      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', maxHeight: '60vh', overflowY: 'auto' }}>
        {categories.map((c) => (
          <div key={c.id} style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '8px 12px', background: t.surfaceAlt, borderRadius: '10px' }}>
            <span style={{ fontSize: '18px' }}>{c.emoji}</span>
            <div style={{ flex: 1, fontSize: '13px', fontWeight: 500 }}>{c.label}</div>
            <input
              type="text" inputMode="decimal" placeholder="0"
              value={budgets[c.id] || ''}
              onChange={(e) => {
                const v = e.target.value.replace(/[^0-9.,]/g, '');
                const n = parseFloat(v.replace(',', '.'));
                const newB = { ...budgets };
                if (!v || isNaN(n) || n <= 0) delete newB[c.id]; else newB[c.id] = n;
                onSave(newB);
              }}
              style={{ width: '90px', background: t.surface, border: `1px solid ${t.border}`, borderRadius: '8px', padding: '6px 10px', color: t.text, fontSize: '13px', textAlign: 'right', outline: 'none' }}
            />
          </div>
        ))}
      </div>
    </Modal>
  );
}

function TripModal({ t, theme, onSave, onClose }) {
  const [name, setName] = useState('');
  const [budget, setBudget] = useState('');
  return (
    <Modal onClose={onClose} t={t} title="New Trip">
      <Label t={t}>Trip name</Label>
      <input autoFocus value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Paris weekend" style={{ ...inputStyle(t), marginBottom: '12px' }} />
      <Label t={t}>Budget (optional)</Label>
      <input value={budget} onChange={(e) => setBudget(e.target.value.replace(/[^0-9.,]/g, ''))} placeholder="0" inputMode="decimal" style={{ ...inputStyle(t), marginBottom: '16px' }} />
      <PrimaryBtn t={t} theme={theme} onClick={() => {
        if (!name.trim()) return;
        onSave({ id: 'trip_' + Date.now(), name: name.trim(), budget: parseFloat(budget.replace(',', '.')) || 0 });
      }} disabled={!name.trim()}>Create Trip</PrimaryBtn>
    </Modal>
  );
}

function GoalModal({ t, theme, onSave, onClose }) {
  const [name, setName] = useState('');
  const [target, setTarget] = useState('');
  const [emoji, setEmoji] = useState('🎯');
  const emojis = ['🎯','🏠','🚗','✈️','💍','🎓','💻','📱','🏖️','💰'];
  return (
    <Modal onClose={onClose} t={t} title="New Savings Goal">
      <Label t={t}>Goal name</Label>
      <input autoFocus value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. New iPhone" style={{ ...inputStyle(t), marginBottom: '12px' }} />
      <Label t={t}>Target amount</Label>
      <input value={target} onChange={(e) => setTarget(e.target.value.replace(/[^0-9.,]/g, ''))} placeholder="0" inputMode="decimal" style={{ ...inputStyle(t), marginBottom: '12px' }} />
      <Label t={t}>Icon</Label>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginBottom: '16px' }}>
        {emojis.map((e) => (
          <button key={e} onClick={() => setEmoji(e)} style={{
            width: '40px', height: '40px', fontSize: '20px',
            background: emoji === e ? t.surfaceAlt : 'transparent',
            border: `1px solid ${emoji === e ? t.accent : t.border}`, borderRadius: '10px',
          }}>{e}</button>
        ))}
      </div>
      <PrimaryBtn t={t} theme={theme} onClick={() => {
        const tgt = parseFloat(target.replace(',', '.'));
        if (!name.trim() || !tgt || tgt <= 0) return;
        onSave({ id: 'goal_' + Date.now(), name: name.trim(), target: tgt, saved: 0, emoji });
      }} disabled={!name.trim() || !target}>Create Goal</PrimaryBtn>
    </Modal>
  );
}

function SubModal({ t, theme, onSave, onClose }) {
  const [name, setName] = useState('');
  const [amount, setAmount] = useState('');
  const [period, setPeriod] = useState('Monthly');
  const [emoji, setEmoji] = useState('📺');
  const presets = [
    { name: 'Netflix', emoji: '🎬' }, { name: 'Spotify', emoji: '🎵' },
    { name: 'YouTube', emoji: '▶️' }, { name: 'iCloud', emoji: '☁️' },
    { name: 'Apple Music', emoji: '🎧' }, { name: 'Gym', emoji: '🏋️' },
  ];
  return (
    <Modal onClose={onClose} t={t} title="New Subscription">
      <Label t={t}>Quick presets</Label>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px', marginBottom: '12px' }}>
        {presets.map((p) => (
          <button key={p.name} onClick={() => { setName(p.name); setEmoji(p.emoji); }} style={{
            background: t.surfaceAlt, border: `1px solid ${t.border}`, borderRadius: '16px',
            padding: '5px 10px', color: t.text, fontSize: '11px',
          }}>{p.emoji} {p.name}</button>
        ))}
      </div>
      <Label t={t}>Name</Label>
      <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Service name" style={{ ...inputStyle(t), marginBottom: '12px' }} />
      <Label t={t}>Amount</Label>
      <input value={amount} onChange={(e) => setAmount(e.target.value.replace(/[^0-9.,]/g, ''))} placeholder="0" inputMode="decimal" style={{ ...inputStyle(t), marginBottom: '12px' }} />
      <Label t={t}>Period</Label>
      <select value={period} onChange={(e) => setPeriod(e.target.value)} style={{ ...inputStyle(t), marginBottom: '16px' }}>
        <option>Monthly</option><option>Yearly</option>
      </select>
      <PrimaryBtn t={t} theme={theme} onClick={() => {
        const a = parseFloat(amount.replace(',', '.'));
        if (!name.trim() || !a || a <= 0) return;
        onSave({ id: 'sub_' + Date.now(), name: name.trim(), amount: a, period, emoji });
      }} disabled={!name.trim() || !amount}>Add</PrimaryBtn>
    </Modal>
  );
}

function RecurringModal({ t, theme, categories, wallets, currency, onSave, onClose }) {
  const [type, setType] = useState('expense');
  const [amount, setAmount] = useState('');
  const [category, setCategory] = useState(categories.expense[0].id);
  const [walletId, setWalletId] = useState(wallets[0].id);
  const [note, setNote] = useState('');
  const [freq, setFreq] = useState('monthly');
  const cats = type === 'expense' ? categories.expense : categories.income;
  useEffect(() => { if (!cats.find((c) => c.id === category)) setCategory(cats[0].id); }, [type]);
  return (
    <Modal onClose={onClose} t={t} title="New Recurring">
      <div style={{ display: 'flex', background: t.surfaceAlt, borderRadius: '12px', padding: '4px', marginBottom: '12px' }}>
        <button onClick={() => setType('expense')} style={{ flex: 1, padding: '8px', borderRadius: '10px', background: type === 'expense' ? t.expense : 'transparent', color: type === 'expense' ? '#fff' : t.textMute, fontWeight: 600, fontSize: '12px' }}>Expense</button>
        <button onClick={() => setType('income')} style={{ flex: 1, padding: '8px', borderRadius: '10px', background: type === 'income' ? t.income : 'transparent', color: type === 'income' ? '#fff' : t.textMute, fontWeight: 600, fontSize: '12px' }}>Income</button>
      </div>
      <Label t={t}>Amount</Label>
      <input value={amount} onChange={(e) => setAmount(e.target.value.replace(/[^0-9.,]/g, ''))} placeholder="0" inputMode="decimal" style={{ ...inputStyle(t), marginBottom: '12px' }} />
      <Label t={t}>Frequency</Label>
      <div style={{ display: 'flex', gap: '4px', marginBottom: '12px' }}>
        {['weekly','monthly','yearly'].map((f) => (
          <button key={f} onClick={() => setFreq(f)} style={{
            flex: 1, padding: '8px', background: freq === f ? t.surfaceAlt : 'transparent',
            border: `1px solid ${freq === f ? t.accent : t.border}`, borderRadius: '10px',
            color: t.text, fontSize: '12px', textTransform: 'capitalize',
          }}>{f}</button>
        ))}
      </div>
      <Label t={t}>Wallet</Label>
      <select value={walletId} onChange={(e) => setWalletId(e.target.value)} style={{ ...inputStyle(t), marginBottom: '12px' }}>
        {wallets.map((w) => <option key={w.id} value={w.id}>{w.emoji} {w.name}</option>)}
      </select>
      <Label t={t}>Category</Label>
      <select value={category} onChange={(e) => setCategory(e.target.value)} style={{ ...inputStyle(t), marginBottom: '12px' }}>
        {cats.map((c) => <option key={c.id} value={c.id}>{c.emoji} {c.label}</option>)}
      </select>
      <Label t={t}>Note (e.g. "Rent")</Label>
      <input value={note} onChange={(e) => setNote(e.target.value)} placeholder="Description" style={{ ...inputStyle(t), marginBottom: '16px' }} />
      <PrimaryBtn t={t} theme={theme} onClick={() => {
        const a = parseFloat(amount.replace(',', '.'));
        if (!a || a <= 0) return;
        onSave({ id: 'rec_' + Date.now(), type, amount: a, category, walletId, note, freq, startDate: new Date().toISOString(), lastRun: new Date().toISOString() });
      }} disabled={!amount}>Save</PrimaryBtn>
    </Modal>
  );
}
