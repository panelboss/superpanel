'use client'
import { useState, useEffect } from 'react'
import Layout from '@/components/Layout'

export default function ServicesPage() {
  const [services, setServices] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch('/api/services').then(r => r.json()).then(d => {
      setServices(d.services || [])
      setLoading(false)
    }).catch(() => setLoading(false))
  }, [])

  const doAction = async (name, action) => {
    await fetch('/api/services', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ service: name, action })
    })
    fetch('/api/services').then(r => r.json()).then(d => setServices(d.services))
  }

  if (loading) return <Layout><div className="loading"><div className="spinner"></div></div></Layout>

  return (
    <Layout>
      <div className="card">
        <div className="card-title">Service Control</div>
        <div style={{ marginTop: 12 }}>
          {services.map((s, i) => (
            <div key={s.name} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '14px 0', borderBottom: i < services.length - 1 ? '1px solid var(--border)' : 'none' }}>
              <div>
                <div style={{ fontSize: 14, fontWeight: 500 }}>{s.name}</div>
                <div style={{ fontSize: 12, color: 'var(--text-dim)' }}>systemctl</div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <span className={'badge ' + (s.active ? 'badge-green' : 'badge-red')}>
                  {s.active ? 'Active' : 'Stopped'}
                </span>
                <button className="btn-sm btn-outline" onClick={() => doAction(s.name, 'restart')}>Restart</button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </Layout>
  )
}
