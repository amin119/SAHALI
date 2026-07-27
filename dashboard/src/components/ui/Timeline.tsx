export interface TimelineItem {
  id: string
  icon: string
  title: string
  subtitle?: string
  note?: string
  date: string
}

export default function Timeline({ items, emptyMessage }: { items: TimelineItem[]; emptyMessage: string }) {
  if (items.length === 0) {
    return <p className="text-xs text-[#94A3B8] text-center py-4">{emptyMessage}</p>
  }
  return (
    <div className="relative">
      <div className="absolute left-3.5 top-0 bottom-0 w-px bg-[#E2E8F0]" />
      <div className="space-y-4">
        {items.map(item => (
          <div key={item.id} className="flex gap-3 relative">
            <div className="w-7 h-7 rounded-full bg-[#f7f9fe] border border-[#E2E8F0] flex items-center justify-center flex-shrink-0 relative z-10">
              <span className="material-symbols-outlined text-[#0038AF]" style={{ fontSize: 13 }}>{item.icon}</span>
            </div>
            <div className="flex-1 pt-0.5">
              <p className="text-xs font-medium text-[#181c20]">{item.title}</p>
              {item.subtitle && <p className="text-xs text-[#64748B]">{item.subtitle}</p>}
              {item.note && <p className="text-xs text-[#94A3B8] mt-0.5 italic">{item.note}</p>}
              <p className="text-[10px] text-[#94A3B8] mt-0.5">{item.date}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
