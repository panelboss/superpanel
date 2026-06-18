import { NextResponse } from 'next/server'
import { readdirSync, statSync } from 'fs'
import { join } from 'path'

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url)
    const dir = searchParams.get('path') || '/var/www'
    const items = readdirSync(dir).map(name => {
      try {
        const p = join(dir, name)
        const s = statSync(p)
        return { name, isDir: s.isDirectory(), size: s.size, mtime: s.mtime }
      } catch { return null }
    }).filter(Boolean).sort((a, b) => a.isDir === b.isDir ? a.name.localeCompare(b.name) : b.isDir - a.isDir)
    return NextResponse.json({ path: dir, items })
  } catch (e) {
    return NextResponse.json({ error: e.message }, { status: 500 })
  }
}
