import type { ReactNode } from 'react'
import EmptyState from './EmptyState'

export interface Column<T> {
  key: string
  header: string
  render: (row: T) => ReactNode
}

interface DataTableProps<T> {
  columns: Column<T>[]
  rows: T[]
  rowKey: (row: T) => string
  loading?: boolean
  onRowClick?: (row: T) => void
  isRowActive?: (row: T) => boolean
  selectable?: boolean
  selected?: string[]
  onToggleSelect?: (id: string) => void
  onToggleSelectAll?: (checked: boolean) => void
  emptyIcon?: string
  emptyMessage?: string
}

/** Generic data table: loading skeleton, optional row selection, optional
 * click-to-open-detail, and a consistent empty state — the shape every
 * list page in the dashboard (reports, teams, municipalities...) needs,
 * written once instead of once per page. */
export default function DataTable<T>({
  columns,
  rows,
  rowKey,
  loading = false,
  onRowClick,
  isRowActive,
  selectable = false,
  selected = [],
  onToggleSelect,
  onToggleSelectAll,
  emptyIcon = 'search_off',
  emptyMessage = 'Aucun résultat',
}: DataTableProps<T>) {
  const colCount = columns.length + (selectable ? 1 : 0)

  return (
    <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm overflow-hidden">
      <div className="overflow-x-auto">
      <table className="w-full text-left">
        <thead>
          <tr className="bg-[#f7f9fe] border-b border-[#E2E8F0]">
            {selectable && (
              <th className="w-10 px-4 py-3">
                <input
                  type="checkbox"
                  className="rounded"
                  checked={selected.length === rows.length && rows.length > 0}
                  onChange={e => onToggleSelectAll?.(e.target.checked)}
                />
              </th>
            )}
            {columns.map(col => (
              <th key={col.key} className="px-4 py-3 text-xs font-semibold text-[#64748B] uppercase tracking-wider">
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-[#E2E8F0]">
          {loading
            ? Array.from({ length: 8 }).map((_, i) => (
                <tr key={i} className="animate-pulse">
                  {Array.from({ length: colCount }).map((__, j) => (
                    <td key={j} className="px-4 py-3.5"><div className="h-4 bg-[#E2E8F0] rounded w-20" /></td>
                  ))}
                </tr>
              ))
            : rows.map(row => {
                const id = rowKey(row)
                const active = isRowActive?.(row) ?? false
                return (
                  <tr
                    key={id}
                    onClick={() => onRowClick?.(row)}
                    className={`transition-colors ${onRowClick ? 'hover:bg-[#f7f9fe] cursor-pointer' : ''} ${active ? 'bg-[#f1f4f9]' : ''}`}
                  >
                    {selectable && (
                      <td className="px-4 py-3.5" onClick={e => e.stopPropagation()}>
                        <input
                          type="checkbox"
                          className="rounded"
                          checked={selected.includes(id)}
                          onChange={() => onToggleSelect?.(id)}
                        />
                      </td>
                    )}
                    {columns.map(col => (
                      <td key={col.key} className="px-4 py-3.5">{col.render(row)}</td>
                    ))}
                  </tr>
                )
              })}
        </tbody>
      </table>
      </div>
      {!loading && rows.length === 0 && <EmptyState icon={emptyIcon} message={emptyMessage} />}
    </div>
  )
}
