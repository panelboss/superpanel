import Layout from '@/components/Layout';

export default function SitesPage() {
  return (
    <Layout>
      <div className="card">
        <div className="card-title">Managed Sites</div>
        <table className="table" style={{marginTop: 12}}>
          <thead>
            <tr>
              <th>Domain</th>
              <th>Status</th>
              <th>Web Server</th>
              <th>PHP</th>
              <th>SSL</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td colSpan="5">
                <div className="empty">
                  <div style={{fontSize:40,marginBottom:12}}>🌐</div>
                  <div>No sites configured yet</div>
                  <div style={{fontSize:12,marginTop:4}}>Add your first site from the server</div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </Layout>
  );
}
