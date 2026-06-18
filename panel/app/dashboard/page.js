import Layout from '@/components/Layout';

function SystemCard({ title, value, unit, sub, color }) {
  return (
    <div className="card">
      <div className="card-title">{title}</div>
      <div className={`card-value ${color || ''}`}>
        {value}{unit && <span style={{fontSize:16,fontWeight:400,marginLeft:4}}>{unit}</span>}
      </div>
      {sub && <div className="card-sub">{sub}</div>}
    </div>
  );
}

function ProgressCard({ title, value, max, label, color }) {
  const pct = Math.min(100, Math.round((value / max) * 100));
  const progressColor = pct > 90 ? 'progress-red' : pct > 70 ? 'progress-yellow' : 'progress-green';

  return (
    <div className="card">
      <div className="card-title">{title}</div>
      <div className="card-value">{pct}%</div>
      <div className="progress-bar">
        <div className={`progress-fill ${progressColor}`} style={{width: `${pct}%`}}></div>
      </div>
      <div className="card-sub">{label}</div>
    </div>
  );
}

function ServiceBadge({ name, active }) {
  return (
    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'8px 0',borderBottom:'1px solid var(--border)'}}>
      <span style={{fontSize:14}}>{name}</span>
      <span className={`badge ${active ? 'badge-green' : 'badge-red'}`}>
        {active ? 'Active' : 'Inactive'}
      </span>
    </div>
  );
}

export default async function DashboardPage() {
  let system = { os: 'N/A', uptime: 'N/A', cpu: 0, ram: { used: 0, total: 1 }, disk: { used: 0, total: 1 }, services: [] };

  try {
    // Try local system info
    const os = require('os');
    const fs = require('fs');
    const { execSync } = require('child_process');

    const totalMem = os.totalmem();
    const freeMem = os.freemem();
    const usedMem = totalMem - freeMem;

    system = {
      os: `${os.type()} ${os.release()}`,
      hostname: os.hostname(),
      uptime: Math.floor(os.uptime()),
      cpu: os.cpus().length,
      cpuModel: os.cpus()[0]?.model || 'Unknown',
      ram: {
        used: Math.round(usedMem / 1024 / 1024),
        total: Math.round(totalMem / 1024 / 1024),
      },
      disk: { used: 0, total: 0 },
      services: [],
    };

    // Try disk
    try {
      const df = execSync('df -BG / | tail -1', { timeout: 2000 }).toString();
      const parts = df.trim().split(/\s+/);
      if (parts.length >= 4) {
        system.disk = {
          used: parseInt(parts[2]) || 0,
          total: parseInt(parts[1]) || 1,
        };
      }
    } catch {}

    // Check services
    const svcs = ['nginx', 'apache2', 'mysql', 'mariadb', 'postgresql', 'php8.1-fpm', 'docker'];
    for (const svc of svcs) {
      try {
        execSync(`systemctl is-active ${svc}`, { timeout: 1000, stdio: 'pipe' });
        system.services.push({ name: svc, active: true });
      } catch {
        try {
          execSync(`systemctl is-active ${svc}`, { timeout: 1000, stdio: 'pipe' });
          system.services.push({ name: svc, active: true });
        } catch {
          // silently skip
        }
      }
    }
  } catch (e) {
    // fallback to placeholder
  }

  return (
    <Layout>
      <div className="grid-4" style={{marginBottom:24}}>
        <SystemCard title="CPU Usage" value={system.cpu} unit="cores" sub={system.cpuModel?.slice(0,30)} color="blue" />
        <ProgressCard title="RAM" value={system.ram.used} max={system.ram.total} label={`${system.ram.used} / ${system.ram.total} MB`} />
        <ProgressCard title="Disk" value={system.disk.used} max={system.disk.total || 1} label={`${system.disk.used} / ${system.disk.total || '?'} GB`} />
        <SystemCard title="Uptime" value={Math.floor(system.uptime / 3600)} unit="hours" sub={(system.uptime % 3600 / 60).toFixed(0) + ' min'} color="green" />
      </div>

      <div className="grid-2">
        <div className="card">
          <div className="card-title">System Info</div>
          <div style={{marginTop:8}}>
            <div style={{display:'flex',justifyContent:'space-between',padding:'6px 0',fontSize:14,borderBottom:'1px solid var(--border)'}}>
              <span style={{color:'var(--text-dim)'}}>OS</span> <span>{system.os}</span>
            </div>
            <div style={{display:'flex',justifyContent:'space-between',padding:'6px 0',fontSize:14,borderBottom:'1px solid var(--border)'}}>
              <span style={{color:'var(--text-dim)'}}>Hostname</span> <span>{system.hostname}</span>
            </div>
            <div style={{display:'flex',justifyContent:'space-between',padding:'6px 0',fontSize:14,borderBottom:'1px solid var(--border)'}}>
              <span style={{color:'var(--text-dim)'}}>Node.js</span> <span>{process.version}</span>
            </div>
            <div style={{display:'flex',justifyContent:'space-between',padding:'6px 0',fontSize:14}}>
              <span style={{color:'var(--text-dim)'}}>Platform</span> <span>{process.platform} {process.arch}</span>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="card-title">Services</div>
          <div style={{marginTop:8}}>
            {system.services.length > 0 ? system.services.map(s => (
              <ServiceBadge key={s.name} name={s.name} active={s.active} />
            )) : (
              <div style={{padding:'20px 0',textAlign:'center',color:'var(--text-dim)',fontSize:14}}>
                Running on {process.platform} — services detectable on Linux
              </div>
            )}
          </div>
        </div>
      </div>
    </Layout>
  );
}
