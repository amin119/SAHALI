import { useEffect, useRef } from 'react'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

interface LocationPickerProps {
  lat: number | null
  lng: number | null
  onChange: (lat: number, lng: number) => void
}

const DEFAULT_CENTER: [number, number] = [36.8, 10.18] // Tunis, when nothing is set yet

function makePinIcon() {
  return L.divIcon({
    className: '',
    html: '<div style="width:16px;height:16px;border-radius:50% 50% 50% 0;background:#0038AF;border:2px solid white;box-shadow:0 1px 4px rgba(0,0,0,.3);transform:rotate(-45deg)"></div>',
    iconSize: [16, 16],
    iconAnchor: [8, 16],
  })
}

/** Click (or drag the pin) to set a lat/lng — used wherever a municipality's
 * centroid needs to be set, instead of asking an admin to type raw coordinates. */
export default function LocationPicker({ lat, lng, onChange }: LocationPickerProps) {
  const containerRef = useRef<HTMLDivElement>(null)
  const mapRef = useRef<L.Map | null>(null)
  const markerRef = useRef<L.Marker | null>(null)

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return
    const center: [number, number] = lat != null && lng != null ? [lat, lng] : DEFAULT_CENTER
    const map = L.map(containerRef.current, { center, zoom: lat != null ? 13 : 7, zoomControl: true })
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap',
      maxZoom: 19,
    }).addTo(map)

    const marker = L.marker(center, { icon: makePinIcon(), draggable: true }).addTo(map)
    marker.on('dragend', () => {
      const p = marker.getLatLng()
      onChange(p.lat, p.lng)
    })
    map.on('click', (e: L.LeafletMouseEvent) => {
      marker.setLatLng(e.latlng)
      onChange(e.latlng.lat, e.latlng.lng)
    })

    mapRef.current = map
    markerRef.current = marker

    return () => {
      map.remove()
      mapRef.current = null
      markerRef.current = null
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <div className="rounded-xl overflow-hidden border border-[#E2E8F0]" style={{ height: 220 }}>
      <div ref={containerRef} style={{ width: '100%', height: '100%' }} />
    </div>
  )
}
