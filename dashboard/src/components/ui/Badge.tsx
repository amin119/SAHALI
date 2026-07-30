/** Coloured pill used for status, priority, and any other single-value tag.
 * `dot` renders the small filled circle StatusBadge uses; priority tags
 * don't want the dot, just the coloured background + text. */
export default function Badge({
  label,
  color,
  dot = false,
}: {
  label: string
  color: string
  dot?: boolean
}) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full text-xs font-semibold ${dot ? 'px-2.5 py-1' : 'px-2 py-0.5 uppercase tracking-tight font-bold rounded'}`}
      style={{ backgroundColor: `${color}18`, color }}
    >
      {dot && <span className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: color }} />}
      {label}
    </span>
  )
}
