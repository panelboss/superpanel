import Layout from '@/components/Layout';
import '../globals.css';

export const metadata = {
  title: 'SuperPanel - Server Manager',
  description: 'One-click VPS Web Management Panel',
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
