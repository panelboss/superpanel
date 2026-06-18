import Layout from '@/components/Layout';

export default function SettingsPage() {
  return (
    <Layout>
      <div className="grid-2">
        <div className="card">
          <div className="card-title">Panel Settings</div>
          <div style={{marginTop:12}}>
            <div style={{display:'flex',justifyContent:'space-between',padding:'10px 0',fontSize:14,borderBottom:'1px solid var(--border)'}}>
              <span style={{color:'var(--text-dim)'}}>Version</span> <span>1.0.0</span>
            </div>
            <div style={{display:'flex',justifyContent:'space-between',padding:'10px 0',fontSize:14,borderBottom:'1px solid var(--border)'}}>
              <span style={{color:'var(--text-dim)'}}>Port</span> <span>8080</span>
            </div>
            <div style={{display:'flex',justifyContent:'space-between',padding:'10px 0',fontSize:14}}>
              <span style={{color:'var(--text-dim)'}}>Stack</span> <span>Auto-detected</span>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="card-title">API Integrations</div>
          <div style={{marginTop:12}}>
            <div style={{display:'flex',justifyContent:'space-between',padding:'10px 0',fontSize:14,borderBottom:'1px solid var(--border)'}}>
              <span>☁️ Cloudflare</span> <span className="badge badge-yellow">Not set</span>
            </div>
            <div style={{display:'flex',justifyContent:'space-between',padding:'10px 0',fontSize:14}}>
              <span>📦 Mega.nz</span> <span className="badge badge-yellow">Not set</span>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}
