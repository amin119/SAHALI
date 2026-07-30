export default function EmptyState({ icon, message, size = 'md' }: { icon: string; message: string; size?: 'sm' | 'md' }) {
  return (
    <div className={`flex flex-col items-center justify-center text-[#94A3B8] ${size === 'md' ? 'py-16' : 'py-8'}`}>
      <span className="material-symbols-outlined mb-3" style={{ fontSize: size === 'md' ? 40 : 36 }}>{icon}</span>
      <p className="text-xs">{message}</p>
    </div>
  )
}
