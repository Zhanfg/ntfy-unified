'use client'

import { useEffect, useState } from 'react'
import { isPermissionGranted, requestPermission } from '@tauri-apps/plugin-notification'

import { Modal } from '@/components/ntfy/modal'
import { ThemeSelect } from '@/components/theme/select'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
import { preferences } from '@/lib/tauri/ntfy'

export function Preferences({ close }: { close: () => void }) {
  const [preview, setPreview] = useState(false)
  const [permission, setPermission] = useState('Checking…')
  const [busy, setBusy] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true

    void Promise.all([preferences(), isPermissionGranted()])
      .then(([saved, allowed]) => {
        if (active) {
          setPreview(saved)
          setPermission(allowed ? 'Granted' : 'Not granted')
        }
      })
      .catch((failure) => {
        if (active) setError(String(failure))
      })
      .finally(() => {
        if (active) setBusy(false)
      })

    return () => {
      active = false
    }
  }, [])

  return (
    <Modal
      busy={busy}
      close={close}
      description="Control appearance and preferences of how the application behaves."
      title="Settings"
    >
      <div className="mt-1.25 flex flex-col gap-4.5">
        <ThemeSelect />

        <div className="flex items-center justify-between text-xs">
          <div>
            <strong>Notification</strong>
            <p className="mt-1.25 text-xs text-muted-foreground">
              Show message content in system notifications
            </p>
          </div>

          <Checkbox
            aria-label="Show message title and content in system notifications"
            checked={preview}
            className="cursor-pointer"
            disabled={busy}
            id="message-preview"
            onCheckedChange={(checked) => setPreview(checked === true)}
          />
        </div>

        <p className="rounded-lg bg-surface-subtle p-3 text-xs leading-relaxed text-muted-foreground">
          This setting changes only system notification previews. It does not hide
          messages in the app and is disabled by default.
        </p>

        {permission !== 'Granted' && (
          <div className="flex items-center justify-between text-xs">
            <div>
              <strong>Permission</strong>
              <p className="mt-1.25 text-xs text-muted-foreground first-letter:uppercase">
                {permission}
              </p>
            </div>

            <Button
              className="cursor-pointer duration-150 transition-colors"
              disabled={busy}
              onClick={async () => {
                setBusy(true)

                try {
                  setPermission(await requestPermission())
                } catch (failure) {
                  setError(String(failure))
                } finally {
                  setBusy(false)
                }
              }}
              size="sm"
              variant="outline"
            >
              Enable
            </Button>
          </div>
        )}

        {error && (
          <p
            className="rounded-md bg-danger-soft p-2.5 text-xs leading-[1.7] text-danger-foreground"
            role="alert"
          >
            {error}
          </p>
        )}

        <div className="flex justify-end gap-2 pt-1.75">
          <Button
            className="min-h-9 min-w-20 cursor-pointer transition-colors duration-150"
            disabled={busy}
            onClick={async () => {
              setBusy(true)

              try {
                await preferences(preview)
                close()
              } catch (failure) {
                setError(String(failure))
              } finally {
                setBusy(false)
              }
            }}
            size="sm"
            type="submit"
          >
            Save
          </Button>
        </div>
      </div>
    </Modal>
  )
}
