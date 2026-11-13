'use client'

import {
  Bell,
  BellOff,
  Clock,
  Inbox,
  Plus,
  ScrollText,
  Settings,
  SlidersHorizontal,
  SquareText,
  Webhook,
  Workflow,
} from 'lucide-react'

import { TopicIcon } from '@/components/ntfy/topic-icon'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import { type Snapshot, type Topic } from '@/types/ntfy'

type Props = {
  snapshot: Snapshot
  selected: string | null
  select: (id: string | null) => void
  addServer: () => void
  addTopic: () => void
  editServer: (id: string) => void
  preferences: () => void
}

export function Sidebar({
  snapshot,
  selected,
  select,
  addServer,
  editServer,
  addTopic,
  preferences,
}: Props) {
  const unread = snapshot.topics.reduce((total, topic) => total + topic.unread, 0)
  const status = (topic: Topic) => snapshot.statuses.find((status) => status.topicId === topic.id)

  return (
    <aside className="ntfy-sidebar-panel sticky top-0 flex h-dvh w-64 shrink-0 flex-col gap-2.5 border-r border-border p-4">
      <div className="flex flex-row items-center gap-2 px-2 h-12 text-foreground select-none">
        <Bell aria-hidden="true" className="size-6 text-primary" />
        <h1 className="text-base font-semibold tracking-tight">ntfy-unified</h1>
      </div>

      <Button
        aria-pressed={selected === null}
        className={cn(
          'cursor-pointer duration-150 transition-colors w-full justify-between font-normal text-muted-foreground',
          selected === null &&
            'bg-accent text-accent-foreground hover:bg-accent dark:hover:bg-accent'
        )}
        onClick={() => select(null)}
        size="sm"
        variant="ghost"
      >
        <div className="flex items-center gap-2">
          <Inbox className="size-4.5" />
          <span className="text-xs">Notifications</span>
        </div>

        {unread > 0 && (
          <b className="bg-accent text-accent-foreground rounded min-w-5.25 py-0.5 px-1.25 text-center text-[10px] inline-block">
            {unread}
          </b>
        )}
      </Button>

      <nav aria-label="Subscriptions" className="min-h-22.5 flex-1 overflow-y-auto overscroll-contain">
        {snapshot.servers.map((server) => (
          <section className="mb-3.5 gap-1 flex flex-col" key={server.id}>
            <div className="flex items-center justify-between px-2.25 text-[11px] font-[650] text-foreground">
              <span className="truncate" title={server.url}>
                {server.name}
              </span>

              <Button
                aria-label={`Edit ${server.name}`}
                className="cursor-pointer duration-150 transition-colors text-muted-foreground hover:text-primary"
                onClick={() => editServer(server.id)}
                size="icon-xs"
                variant="ghost"
              >
                <SlidersHorizontal className="size-3" />
              </Button>
            </div>

            {snapshot.topics
              .filter((topic) => topic.serverId === server.id)
              .map((topic) => {
                const current = status(topic)
                return (
                  <Button
                    aria-pressed={selected === topic.id}
                    className={cn(
                      'cursor-pointer duration-150 transition-colors justify-start px-2.5 gap-2.5 text-left text-xs text-muted-foreground',
                      selected === topic.id &&
                        'bg-accent text-accent-foreground hover:bg-accent dark:hover:bg-accent'
                    )}
                    key={topic.id}
                    onClick={() => select(topic.id)}
                    size="sm"
                    type="button"
                    variant="ghost"
                  >
                    <span className="relative flex size-5 shrink-0 items-center justify-center border border-border rounded-md p-3">
                      <TopicIcon aria-hidden="true" className="size-3.5" name={topic.icon} />

                      <span
                        aria-hidden="true"
                        className={cn(
                          'absolute -bottom-0.5 -right-0.5 size-1 rounded-full ring-2 ring-card',
                          current?.state === 'connected'
                            ? 'animate-pulse bg-success'
                            : 'bg-muted-foreground'
                        )}
                      />
                    </span>

                    <span className="min-w-0 flex-1 truncate">
                      {topic.displayName || topic.topic}
                    </span>

                    {topic.muted && <BellOff className="size-3.25" />}

                    {topic.unread > 0 && (
                      <b className="bg-accent text-accent-foreground rounded min-w-5.25 py-0.5 px-1.25 text-center text-[10px] inline-block">
                        {topic.unread}
                      </b>
                    )}
                  </Button>
                )
              })}

            {!server.enabled && (
              <p className="px-3 py-2 text-xs leading-[1.7] text-muted-foreground">
                Sign in to resume listening
              </p>
            )}

            {!snapshot.topics.some((topic) => topic.serverId === server.id) && (
              <p className="px-3 py-2 text-xs leading-[1.7] text-muted-foreground">
                No subscriptions
              </p>
            )}
          </section>
        ))}

        {snapshot.servers.length === 0 && (
          <p className="px-3 py-2 text-xs leading-[1.7] text-muted-foreground">
            Connect a server to get started.
          </p>
        )}
      </nav>

      <div className="border-t border-border pt-3 gap-1.5 flex flex-row">
        <Button
          aria-label="Add server"
          title="Add server"
          className="cursor-pointer duration-150 transition-colors rounded"
          onClick={addServer}
          size="icon-xs"
          variant="outline"
        >
          <Plus className="size-3" />
        </Button>

        {snapshot.topics.length > 0 && (
          <Button
            aria-label="Add subscription"
            title="Add subscription"
            className="cursor-pointer duration-150 transition-colors rounded"
            onClick={addTopic}
            size="icon-xs"
            variant="outline"
          >
            <SquareText className="size-3" />
          </Button>
        )}

        <Button
          asChild
          className="cursor-pointer duration-150 transition-colors rounded"
          size="icon-xs"
          variant="outline"
        >
          <a aria-label="Automations" title="Automations" href="/automation/">
            <Workflow className="size-3" />
          </a>
        </Button>

        <Button
          asChild
          className="cursor-pointer duration-150 transition-colors rounded"
          size="icon-xs"
          variant="outline"
        >
          <a aria-label="Logs" title="Logs" href="/logs/">
            <ScrollText className="size-3" />
          </a>
        </Button>

        <Button
          asChild
          className="cursor-pointer duration-150 transition-colors rounded"
          size="icon-xs"
          variant="outline"
        >
          <a aria-label="Webhooks" title="Webhooks" href="/webhook/">
            <Webhook className="size-3" />
          </a>
        </Button>

        <Button
          asChild
          className="cursor-pointer duration-150 transition-colors rounded"
          size="icon-xs"
          variant="outline"
        >
          <a aria-label="Schedule" title="Schedule" href="/schedule/">
            <Clock className="size-3" />
          </a>
        </Button>

        <Button
          aria-label="Preferences"
          title="Preferences"
          className="cursor-pointer duration-150 transition-colors rounded"
          onClick={preferences}
          size="icon-xs"
          variant="outline"
        >
          <Settings className="size-3" />
        </Button>
      </div>
    </aside>
  )
}
