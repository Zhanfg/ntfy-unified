'use client'

import { useEffect } from 'react'
import { useTheme } from 'next-themes'
import { invoke } from '@tauri-apps/api/core'

/** Native status icons/background must match the user's resolved React theme. */
export function AndroidSystemBars() {
  const { resolvedTheme } = useTheme()

  useEffect(() => {
    if (!/\bAndroid\b/i.test(navigator.userAgent) || !resolvedTheme) return
    void invoke('android_set_appearance', { dark: resolvedTheme === 'dark' })
      .catch(() => console.warn('Android system bar appearance synchronization unavailable'))
  }, [resolvedTheme])

  useEffect(() => {
    if (!/\bAndroid\b/i.test(navigator.userAgent)) return
    const safeProbe = document.createElement('div')
    safeProbe.setAttribute('aria-hidden', 'true')
    safeProbe.style.cssText = [
      'position:fixed', 'visibility:hidden', 'pointer-events:none', 'width:0',
      'height:0', 'overflow:hidden', 'padding-top:env(safe-area-inset-top,0px)',
      'padding-bottom:env(safe-area-inset-bottom,0px)',
      'padding-left:env(safe-area-inset-left,0px)',
      'padding-right:env(safe-area-inset-right,0px)',
    ].join(';')
    document.body.appendChild(safeProbe)

    const report = () => {
      const root = document.querySelector<HTMLElement>('.ntfy-app-surface')
      const content = document.querySelector<HTMLElement>('[data-ntfy-content]')
      const header = document.querySelector<HTMLElement>('[data-ntfy-header]')
      const button = header?.querySelector<HTMLElement>('button')
      if (!root || !content || !button) return
      const safe = getComputedStyle(safeProbe)
      const applied = getComputedStyle(root)
      const design = getComputedStyle(content)
      const number = (v: string) => Number.parseFloat(v) || 0
      console.info('[ntfy-ui-insets]', JSON.stringify({
        dpr: window.devicePixelRatio,
        viewport_width_css_px: window.innerWidth,
        viewport_height_css_px: window.innerHeight,
        css_env_top_px: number(safe.paddingTop),
        css_env_bottom_px: number(safe.paddingBottom),
        css_env_left_px: number(safe.paddingLeft),
        css_env_right_px: number(safe.paddingRight),
        applied_css_safe_top_px: number(applied.paddingTop),
        applied_css_safe_bottom_px: number(applied.paddingBottom),
        design_padding_top_css_px: number(design.paddingTop),
        header_button_top_css_px: button.getBoundingClientRect().top,
      }))
    }
    let frame = requestAnimationFrame(report)
    const schedule = () => {
      cancelAnimationFrame(frame)
      frame = requestAnimationFrame(report)
    }
    addEventListener('resize', schedule)
    window.visualViewport?.addEventListener('resize', schedule)
    const observer = new MutationObserver(schedule)
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['class'],
    })
    return () => {
      cancelAnimationFrame(frame)
      observer.disconnect()
      removeEventListener('resize', schedule)
      window.visualViewport?.removeEventListener('resize', schedule)
      safeProbe.remove()
    }
  }, [])

  return null
}
