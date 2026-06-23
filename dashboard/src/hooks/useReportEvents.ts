import { useEffect, useRef } from 'react'

const BASE = (import.meta.env.VITE_API_URL ?? 'http://localhost:8000') as string

export interface ReportEvent {
  type: 'report_created' | 'status_changed' | 'report_assigned'
  id: string
  tracking_code?: string
  status?: string
  [key: string]: unknown
}

/**
 * Opens an SSE connection to /v1/events/reports and calls onEvent for each message.
 * The connection is closed when the component unmounts. EventSource auto-reconnects
 * on transient failures, so no manual retry logic is needed.
 *
 * Token is sent as a query param because EventSource cannot set custom headers.
 */
export function useReportEvents(onEvent: (event: ReportEvent) => void): void {
  const callbackRef = useRef(onEvent)
  callbackRef.current = onEvent

  useEffect(() => {
    const token = localStorage.getItem('access_token')
    if (!token) return

    const url = `${BASE}/v1/events/reports?token=${encodeURIComponent(token)}`
    const es = new EventSource(url)

    es.onmessage = (e) => {
      try {
        callbackRef.current(JSON.parse(e.data) as ReportEvent)
      } catch {
        // ignore malformed frames
      }
    }

    // onerror: EventSource will retry automatically — no action needed here
    return () => es.close()
  }, []) // intentionally empty — connection lives for the component lifetime
}
