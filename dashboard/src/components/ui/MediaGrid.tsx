import { API_BASE } from '../../lib/api'

function resolveUrl(u: string): string {
  return u.startsWith('/') ? `${API_BASE}${u}` : u
}

/** Photo grid + optional video/voice-note player for a report or a
 * resolution report. This exact block used to be copy-pasted verbatim
 * between the report's info tab and its resolution-report tab — now it's
 * one component both use. */
export default function MediaGrid({
  photoUrls,
  photoUrl,
  videoUrl,
  voiceNoteUrl,
  hint,
}: {
  photoUrls?: string[]
  photoUrl?: string
  videoUrl?: string
  voiceNoteUrl?: string
  hint?: string
}) {
  const rawUrls = photoUrls?.length ? photoUrls : photoUrl ? [photoUrl] : []
  const photos = rawUrls.map(resolveUrl)

  if (!photos.length && !videoUrl && !voiceNoteUrl) return null

  return (
    <div className="space-y-3">
      {photos.length > 0 && (
        <div>
          <p className="text-[#94A3B8] text-xs mb-2">{photos.length > 1 ? `Photos (${photos.length})` : 'Photo'}</p>
          <div className={`grid gap-2 ${photos.length > 1 ? 'grid-cols-2' : 'grid-cols-1'}`}>
            {photos.map((src, i) => (
              <a key={i} href={src} target="_blank" rel="noopener noreferrer">
                <img
                  src={src}
                  alt={`Photo ${i + 1}`}
                  className="w-full rounded-xl object-cover cursor-zoom-in hover:opacity-90 transition-opacity"
                  style={{ maxHeight: photos.length > 1 ? 120 : 200 }}
                  onError={e => { (e.currentTarget as HTMLImageElement).parentElement!.style.display = 'none' }}
                />
              </a>
            ))}
          </div>
          {hint && <p className="text-[10px] text-[#94A3B8] mt-1">{hint}</p>}
        </div>
      )}
      {videoUrl && (
        <div>
          <p className="text-[#94A3B8] text-xs mb-2">Vidéo</p>
          <video controls className="w-full rounded-xl bg-black" style={{ maxHeight: 240 }} src={resolveUrl(videoUrl)} />
        </div>
      )}
      {voiceNoteUrl && (
        <div>
          <p className="text-[#94A3B8] text-xs mb-2">Note vocale</p>
          <audio controls className="w-full" src={resolveUrl(voiceNoteUrl)} />
        </div>
      )}
    </div>
  )
}
