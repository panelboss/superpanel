'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';

const menu = [
  { href: '/dashboard', label: 'Dashboard', icon: '📊' },
  { href: '/sites', label: 'Sites', icon: '🌐' },
  { href: '/database', label: 'Database', icon: '🗄️' },
  { href: '/dns', label: 'DNS / Cloudflare', icon: '☁️' },
  { href: '/backup', label: 'Backup', icon: '📦' },
  { href: '/settings', label: 'Settings', icon: '⚙️' },
];

export default function Layout({ children }) {
  const pathname = usePathname();
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  const handleLogout = () => {
    document.cookie = 'panel_token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;';
    window.location.href = '/';
  };

  if (!mounted) return <div className="loading"><div className="spinner"></div></div>;

  return (
    <div className="layout">
      <nav className="sidebar">
        <div className="sidebar-logo">⚡ SuperPanel</div>
        {menu.map(item => (
          <Link key={item.href} href={item.href} className={pathname?.startsWith(item.href) ? 'active' : ''}>
            <span>{item.icon}</span> <span>{item.label}</span>
          </Link>
        ))}
      </nav>
      <div className="main">
        <div className="topbar">
          <h2>{menu.find(m => pathname?.startsWith(m.href))?.label || 'Dashboard'}</h2>
          <a href="#" className="logout" onClick={handleLogout}>🚪 Logout</a>
        </div>
        {children}
      </div>
    </div>
  );
}
