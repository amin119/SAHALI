export interface StepperStep {
  key: string
  label: string
  icon: string
}

interface StepperProps {
  steps: StepperStep[]
  currentIndex: number
  rejected?: boolean
  rejectedLabel?: string
  size?: 'sm' | 'md'
}

/** A horizontal "where is my report" journey — the same mental model as a
 * parcel-tracking page, so status changes read at a glance instead of
 * requiring the reader to parse a status word or switch tabs. */
export default function Stepper({ steps, currentIndex, rejected = false, rejectedLabel, size = 'sm' }: StepperProps) {
  const dim = size === 'md' ? 'w-11 h-11' : 'w-8 h-8'
  const iconSize = size === 'md' ? 20 : 16
  const lineTop = size === 'md' ? 21 : 15
  const labelSize = size === 'md' ? 'text-xs' : 'text-[10px]'

  return (
    <div className={size === 'md' ? 'px-6 py-6' : 'px-5 py-4'}>
      <div className="flex items-start">
        {steps.map((step, i) => {
          const done = !rejected && i < currentIndex
          const current = !rejected && i === currentIndex
          const lineActive = !rejected && i <= currentIndex

          return (
            <div key={step.key} className="flex-1 flex flex-col items-center relative">
              {i > 0 && (
                <div
                  className="absolute h-0.5"
                  style={{ top: lineTop, left: '-50%', width: '100%', backgroundColor: lineActive ? '#0038AF' : '#E2E8F0' }}
                />
              )}
              <div
                className={`${dim} rounded-full flex items-center justify-center relative z-10 border-2 transition-colors flex-shrink-0
                  ${done ? 'bg-[#0038AF] border-[#0038AF]' : current ? 'bg-white border-[#0038AF]' : 'bg-white border-[#E2E8F0]'}`}
              >
                {done ? (
                  <span className="material-symbols-outlined text-white" style={{ fontSize: iconSize }}>check</span>
                ) : (
                  <span
                    className="material-symbols-outlined"
                    style={{ fontSize: iconSize, color: current ? '#0038AF' : '#94A3B8' }}
                  >
                    {step.icon}
                  </span>
                )}
              </div>
              <p
                className={`${labelSize} text-center mt-2 leading-tight px-0.5 ${
                  current ? 'text-[#0038AF] font-semibold' : done ? 'text-[#181c20] font-medium' : 'text-[#94A3B8]'
                }`}
              >
                {step.label}
              </p>
            </div>
          )
        })}
      </div>
      {rejected && rejectedLabel && (
        <div className="mt-4 flex items-center gap-2 bg-red-50 border border-red-100 rounded-lg px-3 py-2">
          <span className="material-symbols-outlined text-red-500 flex-shrink-0" style={{ fontSize: 16 }}>cancel</span>
          <span className="text-xs font-medium text-red-600">{rejectedLabel}</span>
        </div>
      )}
    </div>
  )
}
