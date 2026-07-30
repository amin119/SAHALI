export default function ErrorBanner({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3 mb-4">
      <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
      <span className="text-sm text-red-600">{message}</span>
      {onRetry && (
        <button onClick={onRetry} className="ml-auto text-[#0038AF] text-sm hover:underline">Réessayer</button>
      )}
    </div>
  )
}
