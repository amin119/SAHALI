export default function SelectionBar({ count, onClear }: { count: number; onClear: () => void }) {
  if (count === 0) return null
  return (
    <div className="bg-[#0038AF]/10 border border-[#0038AF]/20 rounded-xl px-4 py-2 mb-4 flex items-center justify-between">
      <span className="text-[#0038AF] text-sm font-medium">{count} sélectionné{count > 1 ? 's' : ''}</span>
      <button className="text-[#ba1a1a] text-sm hover:underline" onClick={onClear}>Désélectionner</button>
    </div>
  )
}
