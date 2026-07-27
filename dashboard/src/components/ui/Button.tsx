import type { ButtonHTMLAttributes } from 'react'

type Variant = 'primary' | 'secondary' | 'danger' | 'ghost'
type Size = 'sm' | 'md'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant
  size?: Size
  icon?: string
  loading?: boolean
  fullWidth?: boolean
}

const VARIANT_CLASSES: Record<Variant, string> = {
  primary:   'bg-[#0038AF] text-white hover:opacity-90',
  secondary: 'bg-white border border-[#E2E8F0] text-[#64748B] hover:bg-[#f7f9fe]',
  danger:    'bg-red-500 text-white hover:opacity-90',
  ghost:     'text-[#64748B] hover:bg-[#f7f9fe]',
}

const SIZE_CLASSES: Record<Size, string> = {
  sm: 'px-3 py-1.5 text-xs',
  md: 'px-4 py-2 text-sm',
}

/** Shared action button — covers every button style used across the dashboard
 * (primary actions, secondary/outline actions, destructive actions, and
 * icon-only ghost buttons), so a visual tweak only has to happen once. */
export default function Button({
  variant = 'primary',
  size = 'md',
  icon,
  loading = false,
  fullWidth = false,
  disabled,
  children,
  className = '',
  ...rest
}: ButtonProps) {
  return (
    <button
      disabled={disabled || loading}
      className={`inline-flex items-center justify-center gap-1.5 rounded-lg font-medium transition-all disabled:opacity-50 disabled:cursor-not-allowed ${VARIANT_CLASSES[variant]} ${SIZE_CLASSES[size]} ${fullWidth ? 'w-full' : ''} ${className}`}
      {...rest}
    >
      {icon && !loading && (
        <span className="material-symbols-outlined" style={{ fontSize: size === 'sm' ? 14 : 18 }}>{icon}</span>
      )}
      {children}
    </button>
  )
}
