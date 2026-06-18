import { NextResponse } from 'next/server'
import { execSync } from 'child_process'

export async function GET() {
  try {
    const out = execSync('ls /etc/nginx/sites-available/ 2>/dev/null', { timeout: 2000 })
      .toString().trim().split('\n').filter(Boolean)
    const enabled = execSync('ls /etc/nginx/sites-enabled/ 2>/dev/null', { timeout: 2000 })
      .toString().trim().split('\n').filter(Boolean)
    const sites = out.map(name => ({
      name,
      enabled: enabled.includes(name),
      config: '/etc/nginx/sites-available/' + name
    }))
    return NextResponse.json({ sites })
  } catch {
    return NextResponse.json({ sites: [] })
  }
}
