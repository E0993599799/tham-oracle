import type { Metadata, Viewport } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'ธาม Oracle — Forge Omega',
  description: 'Tham Oracle Fleet & Memory Dashboard',
}

export const viewport: Viewport = {
  themeColor: '#070b14',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="th">
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&family=Noto+Sans+Thai:wght@400;500;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>{children}</body>
    </html>
  )
}
