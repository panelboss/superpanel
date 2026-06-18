import Layout from '@/components/Layout';

export default function DatabasePage() {
  return (
    <Layout>
      <div className="card">
        <div className="card-title">Databases</div>
        <table className="table" style={{marginTop: 12}}>
          <thead>
            <tr><th>Name</th><th>Engine</th><th>Size</th><th>Status</th></tr>
          </thead>
          <tbody>
            <tr><td colSpan="4"><div className="empty"><div style={{fontSize:40,marginBottom:12}}>🗄️</div><div>No databases detected</div></div></td></tr>
          </tbody>
        </table>
      </div>
    </Layout>
  );
}
