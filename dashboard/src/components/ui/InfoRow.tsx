import type { ReactNode } from 'react'

/** Label-over-value pair used throughout every detail panel — extracted
 * because the info tab alone repeated this exact two-line pattern eight
 * times by hand. */
export default function InfoRow({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div>
      <p className="text-[#94A3B8] text-xs mb-1">{label}</p>
      <div className="text-sm text-[#181c20]">{children}</div>
    </div>
  )
}
