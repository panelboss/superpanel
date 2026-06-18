import Layout from '@/components/Layout';

export default function DnsPage() {
  return (
    <Layout>
      <div className="card">
        <div className="card-title">Cloudflare DNS</div>
        <div className="empty">
          <div style={{fontSize:40,marginBottom:12}}>☁️</div>
          <div>Cloudflare API not configured</div>
          <div style={{fontSize:12,marginTop:4}}>Add your API token in Settings to manage DNS records</div>
        </div>
      </div>
    </Layout>
  );
}
