const MAP: Record<string, string> = {
  road:        'road',
  pothole:     'construction',
  sidewalk:    'directions_walk',
  sign:        'signpost',
  lightbulb:   'lightbulb',
  streetlight: 'light_mode',
  wire:        'electrical_services',
  trash:       'delete_outline',
  dump:        'delete_sweep',
  garbage:     'recycling',
  overflow:    'water_drop',
  tree:        'park',
  water:       'water_drop',
  air:         'air',
  leak:        'plumbing',
  sewage:      'water_damage',
  bus:         'directions_bus',
  traffic:     'traffic',
  shield:      'shield',
  building:    'apartment',
  hazard:      'warning',
}

export function categoryIcon(icon: string | null | undefined): string {
  if (!icon) return 'category'
  return MAP[icon] ?? 'category'
}
