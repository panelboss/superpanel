import { NextResponse } from 'next/server'
import { execSync } from 'child_process'

export async function GET() {
  try {
    const out = execSync('mysql -e "SHOW DATABASES" 2>/dev/null', { timeout: 2000 })
      .toString().trim().split('\n').slice(1).map(d => d.trim()).filter(d => d && !['information_schema','mysql','performance_schema','sys'].includes(d))
    return NextResponse.json({ databases: out })
  } catch {
    return NextResponse.json({ databases: [] })
  }
}
