import { type Metadata } from 'next'
import { Toaster } from 'sonner'

import { ThemeProvider } from '@/components/theme/provider'

import '../styles/globals.css'

export const metadata: Metadata = {
  title: 'ntfy-unified',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html data-scroll-behavior="smooth" lang="en" suppressHydrationWarning>
      <body
        className="bg-background-main font-sans text-foreground antialiased"
      >
        <ThemeProvider attribute="class" defaultTheme="dark" disableTransitionOnChange enableSystem>
          {children}
          <Toaster richColors />
        </ThemeProvider>
      </body>
    </html>
  )
}
