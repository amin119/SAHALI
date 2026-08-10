import { driver } from 'driver.js'
import 'driver.js/dist/driver.css'
import { getTourSteps } from './tours'

const BUTTON_TEXT = {
  fr: { next: 'Suivant', prev: 'Précédent', done: 'Terminé', progress: '{{current}} sur {{total}}' },
  ar: { next: 'التالي', prev: 'السابق', done: 'إنهاء', progress: '{{current}} من {{total}}' },
}

/** Starts the guided tour for the current page. Returns false (and starts
 * nothing) if this page has no tour defined yet, so the caller can fall back
 * to something else instead of the button doing nothing. */
export function runPageTour(pathname: string, lang: 'fr' | 'ar'): boolean {
  const steps = getTourSteps(pathname, lang)
  if (steps.length === 0) return false

  const text = BUTTON_TEXT[lang]
  const driverObj = driver({
    steps,
    animate: true,
    showProgress: true,
    stagePadding: 6,
    stageRadius: 12,
    overlayOpacity: 0.55,
    smoothScroll: true,
    skipMissingElement: true,
    popoverClass: 'sahali-tour-popover',
    progressText: text.progress,
    nextBtnText: text.next,
    prevBtnText: text.prev,
    doneBtnText: text.done,
  })
  driverObj.drive()
  return true
}
