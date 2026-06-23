const BASE = (import.meta.env.VITE_API_URL ?? 'http://localhost:8000') + '/v1'

function getToken(): string | null {
  return localStorage.getItem('access_token')
}

async function request<T>(
  method: string,
  path: string,
  options: { body?: unknown; auth?: boolean; params?: Record<string, string | number | undefined> } = {}
): Promise<T> {
  const { body, auth = true, params } = options

  let url = `${BASE}${path}`
  if (params) {
    const qs = Object.entries(params)
      .filter(([, v]) => v !== undefined && v !== '')
      .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
      .join('&')
    if (qs) url += `?${qs}`
  }

  const headers: Record<string, string> = { 'Content-Type': 'application/json' }
  if (auth) {
    const token = getToken()
    if (token) headers['Authorization'] = `Bearer ${token}`
  }

  const res = await fetch(url, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  })

  if (res.status === 401) {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    window.location.href = '/login'
    throw new Error('Session expirée')
  }

  if (!res.ok) {
    const err = await res.json().catch(() => ({}))
    throw new Error((err as { detail?: string }).detail ?? `Erreur HTTP ${res.status}`)
  }

  if (res.status === 204) return undefined as T
  return res.json() as Promise<T>
}

export const api = {
  get: <T>(path: string, params?: Record<string, string | number | undefined>) =>
    request<T>('GET', path, { params }),
  getPublic: <T>(path: string, params?: Record<string, string | number | undefined>) =>
    request<T>('GET', path, { auth: false, params }),
  post: <T>(path: string, body?: unknown, auth = true) =>
    request<T>('POST', path, { body, auth }),
  patch: <T>(path: string, body?: unknown) =>
    request<T>('PATCH', path, { body }),
  delete: <T>(path: string) =>
    request<T>('DELETE', path),
}
