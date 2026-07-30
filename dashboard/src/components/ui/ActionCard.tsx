interface ActionCardProps {
  icon: string
  color: string
  count: number
  label: string
  description?: string
  onClick?: () => void
}

/** A big, obvious "here's what needs you" tile — count first, label second,
 * whole thing clickable. Built for the dashboard landing page so a non-expert
 * user can act without first reading a chart. */
export default function ActionCard({ icon, color, count, label, description, onClick }: ActionCardProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={!onClick}
      className={`flex items-center gap-4 bg-white rounded-xl p-5 shadow-sm border border-[#E2E8F0] text-left w-full transition-all
        ${onClick ? 'hover:shadow-md hover:-translate-y-0.5 cursor-pointer' : 'cursor-default'}`}
    >
      <div className="w-12 h-12 rounded-lg flex items-center justify-center flex-shrink-0" style={{ backgroundColor: `${color}18` }}>
        <span className="material-symbols-outlined" style={{ fontSize: 26, color }}>{icon}</span>
      </div>
      <div className="min-w-0 flex-1">
        <p className="text-2xl font-bold text-[#181c20] leading-none">{count}</p>
        <p className="text-sm font-semibold text-[#181c20] mt-1.5">{label}</p>
        {description && <p className="text-xs text-[#64748B] mt-0.5">{description}</p>}
      </div>
      {onClick && <span className="material-symbols-outlined text-[#94A3B8] flex-shrink-0" style={{ fontSize: 20 }}>chevron_right</span>}
    </button>
  )
}
