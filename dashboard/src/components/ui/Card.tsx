import type { HTMLAttributes } from 'react'

/** The white, bordered, rounded surface every panel in the dashboard sits
 * on — the filter bar, the table wrapper, the detail panel all used the
 * exact same three Tailwind classes by hand. */
export default function Card({ className = '', children, ...rest }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={`bg-white rounded-xl border border-[#E2E8F0] ${className}`} {...rest}>
      {children}
    </div>
  )
}
