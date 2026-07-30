import { useEffect, useRef } from 'react'
import { api } from '../lib/api'

const BASE = (import.meta.env.VITE_API_URL ?? 'http://localhost:8000') as string
const RETRY_DELAY_MS = 4000

export interface ReportEvent {
  type: 'report_created' | 'status_changed' | 'report_assigned'
  id: string
  tracking_code?: string
  status?: string
  [key: string]: unknown
}

/**
 * Opens an SSE connection to /v1/events/reports and calls onEvent for each message.
 * The connection is closed when the component unmounts.
 *
 * EventSource can't set an Authorization header, so instead of putting the
 * real access token in the URL, we fetch a short-lived one-time ticket first
 * (POST /events/ticket) and pass that instead. Since the ticket is single-use,
 * we can't rely on EventSource's own auto-reconnect (it would just retry the
 * same, now-dead ticket) — onerror instead fetches a fresh ticket and reopens.
 */
export function useReportEvents(onEvent: (event: ReportEvent) => void): void {
  const callbackRef = useRef(onEvent)
  callbackRef.current = onEvent

  useEffect(() => {
    let es: EventSource | null = null
    let cancelled = false
    let retryTimer: ReturnType<typeof setTimeout> | undefined

    async function connect() {
      if (cancelled) return
      let ticket: string
      try {
        const res = await api.post<{ ticket: string }>('/events/ticket')
        ticket = res.ticket
      } catch {
        retryTimer = setTimeout(connect, RETRY_DELAY_MS)
        return
      }
      if (cancelled) return

      // Bind handlers to this specific source, not the shared `es` variable —
      // otherwise a delayed error from a source a previous reconnect already
      // replaced could close the new connection and double-schedule retries.
      const source = new EventSource(`${BASE}/v1/events/reports?ticket=${encodeURIComponent(ticket)}`)
      es = source
      source.onmessage = (e) => {
        try {
          callbackRef.current(JSON.parse(e.data) as ReportEvent)
        } catch {
          // ignore malformed frames
        }
      }
      source.onerror = () => {
        source.close()
        if (es !== source) return
        es = null
        if (!cancelled) retryTimer = setTimeout(connect, RETRY_DELAY_MS)
      }
    }

    connect()
    return () => {
      cancelled = true
      if (retryTimer) clearTimeout(retryTimer)
      es?.close()
    }
  }, []) // intentionally empty — connection lives for the component lifetime
}
