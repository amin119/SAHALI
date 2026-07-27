export interface TabItem<K extends string> {
  key: K
  label: string
  icon: string
  badge?: number
}

export default function Tabs<K extends string>({
  tabs,
  active,
  onChange,
}: {
  tabs: TabItem<K>[]
  active: K
  onChange: (key: K) => void
}) {
  return (
    <div className="flex border-b border-[#E2E8F0] flex-shrink-0 overflow-x-auto">
      {tabs.map(tab => (
        <button
          key={tab.key}
          onClick={() => onChange(tab.key)}
          className={`flex items-center gap-1.5 px-3 py-2.5 text-xs font-medium whitespace-nowrap border-b-2 transition-colors ${
            active === tab.key
              ? 'border-[#0038AF] text-[#0038AF]'
              : 'border-transparent text-[#64748B] hover:text-[#181c20]'
          }`}
        >
          <span className="material-symbols-outlined" style={{ fontSize: 14 }}>{tab.icon}</span>
          {tab.label}
          {!!tab.badge && (
            <span className="bg-[#0038AF] text-white text-[9px] font-bold rounded-full w-4 h-4 flex items-center justify-center">
              {tab.badge}
            </span>
          )}
        </button>
      ))}
    </div>
  )
}
