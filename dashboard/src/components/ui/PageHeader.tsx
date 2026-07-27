import type { ReactNode } from 'react'

export default function PageHeader({
  title,
  subtitle,
  actions,
}: {
  title: string
  subtitle?: string
  actions?: ReactNode
}) {
  return (
    <div className="flex flex-col md:flex-row md:items-end justify-between mb-6 gap-4">
      <div>
        <h2 className="text-[#0F172A] text-2xl font-bold">{title}</h2>
        {subtitle && <p className="text-[#64748B] text-sm mt-1">{subtitle}</p>}
      </div>
      {actions && <div className="flex items-center gap-2">{actions}</div>}
    </div>
  )
}
