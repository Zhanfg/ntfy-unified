'use client'

import { useEffect, useState, type ReactNode } from 'react'

/**
 * Desktop-only page clients reference IPC commands absent from mobile Rust.
 * This prevents mounting those clients in Android. Not an auth boundary.
 */
export function DesktopOnlyRoute({ children }: { children: ReactNode }) {
  const [android, setAndroid] = useState<boolean | null>(null)

  useEffect(() => {
    setAndroid(/\bAndroid\b/i.test(navigator.userAgent))
  }, [])

  if (android === null) return null

  if (android) {
    return (
      <main className="flex min-h-dvh flex-col items-center justify-center gap-4 p-6 text-center">
        <h1 className="text-base font-semibold">Desktop-only tool</h1>
        <p className="max-w-sm text-sm text-muted-foreground">
          This feature is not available in the Android foreground client.
        </p>
        <a className="text-sm text-primary underline" href="/">
          Return to Inbox
        </a>
      </main>
    )
  }

  return <>{children}</>
}
