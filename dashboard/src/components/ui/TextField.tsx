import type { InputHTMLAttributes, TextareaHTMLAttributes } from 'react'

interface TextFieldProps extends InputHTMLAttributes<HTMLInputElement> {
  icon?: string
  label?: string
  error?: string
}

const FIELD_CLASSES = 'w-full bg-[#f1f4f9] border-0 rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20'

/** Shared text input — every plain text field in the dashboard (search boxes,
 * note fields, name fields) used the same hand-written Tailwind incantation;
 * this is that incantation, written once. */
export function TextField({ icon, label, error, className = '', ...rest }: TextFieldProps) {
  return (
    <div>
      {label && <label className="text-xs text-[#64748B] mb-1 block">{label}</label>}
      <div className="relative">
        {icon && (
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[#747686]" style={{ fontSize: 16 }}>
            {icon}
          </span>
        )}
        <input
          className={`${FIELD_CLASSES} ${icon ? 'pl-9' : ''} ${error ? 'ring-2 ring-red-200' : ''} ${className}`}
          {...rest}
        />
      </div>
      {error && <p className="text-[10px] text-red-500 mt-1">{error}</p>}
    </div>
  )
}

interface TextAreaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string
  error?: string
}

export function TextArea({ label, error, className = '', ...rest }: TextAreaProps) {
  return (
    <div>
      {label && <label className="text-xs text-[#64748B] mb-1 block">{label}</label>}
      <textarea
        className={`${FIELD_CLASSES} resize-none ${error ? 'ring-2 ring-red-200' : ''} ${className}`}
        {...rest}
      />
      {error && <p className="text-[10px] text-red-500 mt-1">{error}</p>}
    </div>
  )
}

interface SelectFieldProps {
  value: string
  onChange: (value: string) => void
  options: { value: string; label: string }[]
  placeholder?: string
  className?: string
}

export function SelectField({ value, onChange, options, placeholder, className = '' }: SelectFieldProps) {
  return (
    <select
      value={value}
      onChange={e => onChange(e.target.value)}
      className={`bg-[#f1f4f9] rounded-lg px-3 py-2 text-sm outline-none border-0 text-[#181c20] ${className}`}
    >
      {placeholder && <option value="">{placeholder}</option>}
      {options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
    </select>
  )
}
