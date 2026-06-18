import Layout from '@/components/Layout';

export default function BackupPage() {
  return (
    <Layout>
      <div className="card">
        <div className="card-title">Automated Backups</div>
        <div style={{marginTop:12}}>
          <div style={{display:'flex',justifyContent:'space-between',padding:'10px 0',borderBottom:'1px solid var(--border)',fontSize:14}}>
            <span>⏰ Daily backup</span>
            <span className="badge badge-green">Active (2:00 AM)</span>
          </div>
          <div style={{display:'flex',justifyContent:'space-between',padding:'10px 0',borderBottom:'1px solid var(--border)',fontSize:14}}>
            <span>🗄️ Database backup</span>
            <span className="badge badge-green">Enabled</span>
          </div>
          <div style={{display:'flex',justifyContent:'space-between',padding:'10px 0',fontSize:14}}>
            <span>☁️ Mega.nz sync</span>
            <span className="badge badge-yellow">Not configured</span>
          </div>
        </div>
        <div className="empty" style={{marginTop:16}}>
          <div style={{fontSize:14}}>Backup dir: /opt/webpanel/backups/</div>
        </div>
      </div>
    </Layout>
  );
}
