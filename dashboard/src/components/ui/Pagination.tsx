import Button from './Button'

export default function Pagination({
  page,
  totalPages,
  total,
  onChange,
}: {
  page: number
  totalPages: number
  total: number
  onChange: (page: number) => void
}) {
  if (totalPages <= 1) return null
  return (
    <div className="flex items-center justify-between mt-4">
      <span className="text-sm text-[#64748B]">Page {page} sur {totalPages} · {total.toLocaleString('fr-FR')} résultats</span>
      <div className="flex items-center gap-2">
        <Button variant="secondary" size="sm" disabled={page === 1} onClick={() => onChange(page - 1)}>← Précédent</Button>
        <Button variant="secondary" size="sm" disabled={page >= totalPages} onClick={() => onChange(page + 1)}>Suivant →</Button>
      </div>
    </div>
  )
}
