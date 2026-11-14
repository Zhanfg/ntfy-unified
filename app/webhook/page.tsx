import { BackButton } from '@/components/back-button'
import { DesktopOnlyRoute } from '@/components/ntfy/desktop-only-route'
import { Webhook } from '@/components/webhook'

export default function Page() {
  return (
    <DesktopOnlyRoute>
    <main className="flex h-dvh min-h-0 text-sm">
      <div className="flex min-w-0 flex-1 flex-col p-6 space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-base font-semibold select-none">Webhook</h1>
          <BackButton />
        </div>

        <section className="flex flex-1 flex-col">
          <Webhook />
        </section>
      </div>
    </main>
    </DesktopOnlyRoute>
  )
}
