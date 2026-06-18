import { NextResponse } from 'next/server';

// Use bcrypt in production; simple compare for now
const PANEL_PASSWORD = process.env.PANEL_PASSWORD || 'admin123';

export async function POST(request) {
  try {
    const { password } = await request.json();
    
    if (password === PANEL_PASSWORD) {
      const response = NextResponse.json({ success: true });
      response.cookies.set('panel_token', Buffer.from(password).toString('base64'), {
        httpOnly: true,
        secure: false,
        sameSite: 'lax',
        maxAge: 60 * 60 * 24, // 24 hours
        path: '/',
      });
      return response;
    }

    return NextResponse.json({ success: false, message: 'Invalid password' }, { status: 401 });
  } catch {
    return NextResponse.json({ success: false, message: 'Invalid request' }, { status: 400 });
  }
}
