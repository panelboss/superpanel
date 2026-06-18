import { NextResponse } from 'next/server'
import { execSync } from 'child_process'

export async function GET() {
  const names = ['nginx', 'mysql', 'docker', 'ssh']
  try {
    const out = execSync('free -m | awk "/^Mem:/{printf \"%d/%d\", $3, $2}"', { timeout: 1000 }).toString()
    const svcs = names.map(name => {
      try { execSync('systemctl is-active ' + name, { timeout: 1000, stdio: 'pipe' }); return { name, active: true } } 
      catch { return { name, active: false } }
    })
    return NextResponse.json({ services: svcs, memory: out })
  } catch {
    return NextResponse.json({ services: names.map(n => ({ name: n, active: false })) })
  }
}
export async function POST(request) {
  try {
    const { service, action } = await request.json()
    if (['nginx', 'mysql', 'docker'].includes(service) && ['start', 'stop', 'restart'].includes(action)) {
      execSync('systemctl ' + action + ' ' + service, { timeout: 5000 })
      return NextResponse.json({ success: true })
    }
    return NextResponse.json({ error: 'Invalid request' }, { status: 400 })
  } catch (e) {
    return NextResponse.json({ error: e.message }, { status: 500 })
  }
}
