import Layout from '@/components/Layout'
import os from 'os'
import { execSync } from 'child_process'

function SystemCard({ title, value, unit, sub, color }) {
  return (
    <div className="card">
      <div className="card-title">{title}</div>
      <div className={`card-value ${color || ''}`}>
        {value}{unit && <span style={{ fontSize: 16, fontWeight: 400, marginLeft: 4 }}>{unit}</span>}
      </div>
      {sub && <div className="card-sub">{sub}</div>}
    </div>
  )
}

function ProgressCard({ title, value, max, label }) {
  const pct = Math.min(100, Math.round((value / max) * 100))
  const progressColor = pct > 90 ? 'progress-red' : pct > 70 ? 'progress-yellow' : 'progress-green'
  return (
    <div className="card">
      <div className="card-title">{title}</div>
      <div className="card-value">{pct}%</div>
      <div className="progress-bar">
        <div className={`progress-fill ${progressColor}`} style={{ width: `${pct}%` }} />
      </div>
      <div className="card-sub">{label}</div>
    </div>
  )
}

export default function DashboardPage() {
  let system = { os: 'N/A', hostname: 'N/A', uptime: 0, cpu: 1, cpuModel: 'Unknown', ram: { used: 0, total: 1 }, disk: { used: 0, total: 1 }, services: [] }

  try {
    const totalMem = os.totalmem()
    const freeMem = os.freemem()
    system = {
      os: `${os.type()} ${os.release()}`,
      hostname: os.hostname(),
      uptime: Math.floor(os.uptime()),
      cpu: os.cpus().length,
      cpuModel: os.cpus()[0]?.model || 'Unknown',
      ram: { used: Math.round((totalMem - freeMem) / 1024 / 1024), total: Math.round(totalMem / 1024 / 1024) },
      disk: { used: 0, total: 0 },
      services: []
    }

    try {
      const df = execSync('df -BG / | tail -1', { timeout: 2000 }).toString().trim().split(/\s+/)
      if (df.length >= 4) system.disk = { used: parseInt(df[2]) || 0, total: parseInt(df[1]) || 1 }
    } catch {}

    const svcs = ['nginx', 'apache2', 'mysql', 'mariadb', 'postgresql', 'docker']
    for (const svc of svcs) {
      try {
        execSync(`systemctl is-active ${svc}`, { timeout: 1000, stdio: 'pipe' })
        system.services.push({ name: svc, active: true })
      } catch {
        try { execSync(`systemctl is-active ${svc}`, { timeout: 1000, stdio: 'pipe' }); system.services.push({ name: svc, active: true }) } catch {}
      }
    }
  } catch {}

  return (
    <Layout>
      <div className="grid-4" style={{ marginBottom: 24 }}>
        <SystemCard title="CPU Usage" value={system.cpu} unit="cores" sub={system.cpuModel?.slice(0, 30)} color="blue" />
        <ProgressCard title="RAM" value={system.ram.used} max={system.ram.total} label={`${system.ram.used} / ${system.ram.total} MB`} />
        <ProgressCard title="Disk" value={system.disk.used} max={system.disk.total || 1} label={`${system.disk.used} / ${system.disk.total || '?'} GB`} />
        <SystemCard title="Uptime" value={Math.floor(system.uptime / 3600)} unit="hours" sub={(system.uptime % 3600 / 60).toFixed(0) + ' min'} color="green" />
      </div>

      <div className="grid-2">
        <div className="card">
          <div className="card-title">System Info</div>
          <div style={{ marginTop: 8 }}>
            {[['OS', system.os], ['Hostname', system.hostname], ['Node.js', process.version], ['Platform', `${process.platform} ${process.arch}`]].map(([k, v], i) => (
              <div key={k} style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', fontSize: 14, borderBottom: i < 3 ? '1px solid var(--border)' : 'none' }}>
                <span style={{ color: 'var(--text-dim)' }}>{k}</span><span>{v}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="card">
          <div className="card-title">Services</div>
          <div style={{ marginTop: 8 }}>
            {system.services.length > 0 ? system.services.map(s => (
              <div key={s.name} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 0', borderBottom: '1px solid var(--border)' }}>
                <span style={{ fontSize: 14 }}>{s.name}</span>
                <span className={`badge ${s.active ? 'badge-green' : 'badge-red'}`}>{s.active ? 'Active' : 'Inactive'}</span>
              </div>
            )) : <div style={{ padding: '20px 0', textAlign: 'center', color: 'var(--text-dim)', fontSize: 14 }}>Running on {process.platform} — services detectable on Linux</div>}
          </div>
        </div>
      </div>
    </Layout>
  )
}
