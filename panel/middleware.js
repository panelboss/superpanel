import { NextResponse } from 'next/server';

export function middleware(request) {
  const token = request.cookies.get('panel_token');
  const { pathname } = request.nextUrl;

  // Allow login page and API
  if (pathname === '/' || pathname.startsWith('/api/auth')) {
    if (token && pathname === '/') {
      return NextResponse.redirect(new URL('/dashboard', request.url));
    }
    return NextResponse.next();
  }

  // Protect dashboard routes
  if (pathname.startsWith('/dashboard') || pathname.startsWith('/sites') || 
      pathname.startsWith('/database') || pathname.startsWith('/dns') ||
      pathname.startsWith('/backup') || pathname.startsWith('/settings')) {
    if (!token) {
      return NextResponse.redirect(new URL('/', request.url));
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
