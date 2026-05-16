import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'ธาม Oracle — Dashboard',
  description: 'Tham Oracle Fleet & Memory Dashboard',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="th">
      <body>{children}</body>
    </html>
  )
}
