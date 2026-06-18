import Layout from '@/components/Layout'

export default function FilesPage() {
  return (
    <Layout>
      <div className="card">
        <div className="card-title">File Manager</div>
        <div style={{ marginTop: 12, padding: '8px 12px', background: '#f7fafc', borderRadius: 8, fontSize: 13, fontFamily: 'monospace', color: 'var(--text-dim)', marginBottom: 16 }}>
          /var/www/
        </div>
        <div className="empty">
          <div style={{ fontSize: 40, marginBottom: 12 }}>📁</div>
          <div>File browser coming soon</div>
          <div style={{ fontSize: 12, marginTop: 4 }}>Browse and edit server files</div>
        </div>
      </div>
    </Layout>
  )
}
