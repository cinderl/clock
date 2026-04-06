# agent.md — Digital Clock

## Project Overview

A single-file, zero-dependency desktop/mobile digital clock web application.  
Everything lives in `index.html` — HTML, CSS, and vanilla JavaScript.

---

## File Structure

```
index.html   # Main application (HTML + CSS + JS)
manifest.json        # PWA web app manifest
sw.js                # Service worker (cache-first, offline support)
icon-192.png         # PWA icon — 192×192 px
icon-512.png         # PWA icon — 512×512 px
agent.md             # This file
```

---

## Architecture

### Layers (z-index stack)

| Layer | Element | z-index | Purpose |
|---|---|---|---|
| Sunrise | `#sunrise-layer` | 0 | Full-viewport color overlay driven by rAF |
| Clock | `#clock-wrapper > #clock` | 1 | Scaled time display |
| Alarm indicator | `#alarm-indicator` | 10 | Top-left ⏰ icon, armed/ringing states |
| Settings button | `#settings-btn` | 10 | Floating gear, bottom-right |
| Settings panel | `#settings-panel` | 20 | Dark overlay panel, opens above gear |

### Clock DOM structure

```html
<div id="clock-wrapper">          <!-- centering flex container -->
  <div id="clock">                <!-- font-size set by fitClock(); flex row or column -->
    <span id="clock-hh" class="clock-digits">00</span>
    <span id="clock-colon">:</span>
    <span id="clock-mm" class="clock-digits">00</span>
  </div>
</div>
```

Each `.clock-digits` span carries a `::before` ghost with `content: '88'` to simulate unlit LCD segments.

### Orientation layout

| Orientation | `#clock` flex direction | `#clock-colon` | Scaling target |
|---|---|---|---|
| Landscape (`vw >= vh`) | `row` | visible | Full row `HH:MM` fills viewport |
| Portrait (`vh > vw`) | `column` | `display: none` | Each digit pair fills full width; two rows fit viewport height |

Switched via `@media (orientation: portrait)`. `fitClock()` branches on `vh > vw` at runtime to measure and scale correctly for each case.

### State object

All mutable runtime state is held in a single `state` object:

```js
{
  clockColor,      // hex string — active clock color
  alarmTime,       // "HH:MM" string or ""
  alarmFired,      // bool — prevents re-triggering within same minute
  sunriseActive,   // bool — sunrise rAF loop running
  sunriseStart,    // performance.now() timestamp when sunrise began
  sunriseDur,      // ms — user-configurable (default 60 000)
  iconTimer,       // setTimeout ID for gear fade-out
  panelOpen,       // bool — settings panel visibility
}
```

### Key functions

| Function | Description |
|---|---|
| `fitClock()` | Branches on orientation. Portrait: scales to fill width with two stacked rows. Landscape: scales full `HH:MM` row to fill viewport. Called on load, `resize`, and `orientationchange`. |
| `tickClock()` | Gets `{ hh, mm }` from `formatTime()`, writes to `#clock-hh` / `#clock-mm` spans only when value changes. Calls `checkAlarm()`. Runs every 500 ms. |
| `checkAlarm(hhmm)` | Compares current `HH:MM` to `state.alarmTime`. Fires `triggerSunrise()` once per alarm event; resets `alarmFired` when the minute advances. |
| `triggerSunrise()` | Guards against double-trigger, sets `sunriseActive`, stamps `sunriseStart`, kicks off rAF loop. |
| `animateSunrise(now)` | rAF callback. Computes `progress = elapsed / sunriseDur`, applies ease-in-out quad, sets `hsl(42, sat%, lit%)` on `#sunrise-layer`. On completion schedules `resetSunrise` after 10-minute hold. |
| `resetSunrise()` | Clears `sunriseActive`, fades `#sunrise-layer` back to transparent over 3 s via CSS transition, re-arms alarm indicator. |
| `applyColor(hex)` | Sets `--clock-color` and derives `--glow-color` (rgba at 40% opacity) on `:root`. |
| `loadSettings()` | Reads `dclock_settings` from `localStorage`, hydrates `state`. |
| `saveSettings()` | Serialises `{ clockColor, alarmTime, sunriseSecs }` to `localStorage`. |
| `showIcon()` | Adds `.visible` to gear button, resets 3 s auto-hide timer. |
| `requestFullscreenOnce()` | Calls `requestFullscreen` (with vendor prefix fallbacks) on first click outside the panel. |

---

## CSS Custom Properties

```css
--clock-color      /* Active digit color (hex) */
--glow-color       /* rgba glow derived from --clock-color */
--bg-color         /* Page background (#000000) */
--panel-bg         /* Settings panel background */
--panel-border     /* Settings panel border color */
```

---

## External Dependencies

| Resource | URL | Purpose |
|---|---|---|
| Seven Segment font | `https://fonts.cdnfonts.com/css/seven-segment` | LCD-style 7-segment display typeface |
| NoSleep.js 0.12.0 | `https://cdn.jsdelivr.net/npm/nosleep.js@0.12.0/dist/NoSleep.min.js` | Prevents screen sleep on all browsers and iOS via silent looping video |

No JS frameworks, no build step, no bundler.

### PWA / Installability

The app meets Android Chrome's installability criteria:

| Requirement | How it is satisfied |
|---|---|
| HTTPS (or localhost) | Must be served over HTTPS when deployed |
| Web app manifest | `manifest.json` — `display: standalone`, `orientation: any` |
| Service worker | `sw.js` registered on `window load`; controls fetch |
| Icons | 192×192 and 512×512 PNG icons with `purpose: any maskable` |

Android Chrome shows the "Add to Home Screen" / "Install app" banner automatically once all criteria are met. The installed app launches in true fullscreen (no browser chrome).

### Service worker strategy

Cache-first with network fallback (defined in `sw.js`):

1. **Install** — pre-caches all local assets (`digital-clock.html`, `manifest.json`, both icons).
2. **Activate** — deletes any caches whose name differs from `CACHE_NAME` (version bump = clean slate).
3. **Fetch** — serves from cache; on miss, fetches from network, stores response, returns it. External font URLs (cdnfonts) are also cached on first fetch.

To update the app: bump `CACHE_NAME` in `sw.js` (e.g. `dclock-v2`). The new SW will install, delete the old cache, and re-fetch all assets.

### Serving locally for testing

```bash
# Python 3
python3 -m http.server 8080
# then open http://localhost:8080/digital-clock.html in Chrome
```

Chrome treats `localhost` as a secure origin, so the install prompt will appear during local testing.

### NoSleep.js integration

Loaded in a dedicated `<script>` block before the main script. Enabled immediately on page load and re-enabled on `visibilitychange` (covers tab switching and phone lock/unlock). Replaces the previous native Wake Lock API approach.

```js
const noSleep = new NoSleep();
noSleep.enable();
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible') noSleep.enable();
});
```

---

## localStorage Schema

Key: `dclock_settings`

```json
{
  "clockColor":  "#ff2200",
  "alarmTime":   "07:30",
  "sunriseSecs": 60
}
```

All fields are optional — missing keys fall back to defaults.

---

## Settings Panel — Fields

| Field | Element ID | Type | Range / Notes |
|---|---|---|---|
| Clock color | `#color-picker` | `<input type="color">` | Any valid hex color |
| Alarm time | `#alarm-input` | `<input type="time">` | `HH:MM` (24 h); empty = disabled |
| Sunrise duration | `#sunrise-dur-input` | `<input type="number">` | 10 – 3600 seconds, step 10 |
| Simulate sunrise | `#simulate-btn` | `<button>` | Immediately triggers sunrise animation |

---

## Sunrise Animation — Full Lifecycle

Driven by `requestAnimationFrame`, not CSS transitions.

```
progress 0 → 1  (linear, over state.sunriseDur ms)
eased    = easeInOutQuad(progress)

hue  = 42          (warm amber-gold, constant)
sat  = eased x 100 (0% → 100%)
lit  = eased x 52  (0% → 52%)

background = hsl(42, sat%, lit%)
```

| Phase | Duration | What happens |
|---|---|---|
| Rise | `state.sunriseDur` (default 60 s) | rAF loop interpolates background black → golden yellow |
| Hold | 10 minutes (600 000 ms) | Background stays at peak golden yellow |
| Reset | 3 s CSS transition | `#sunrise-layer` fades back to transparent; alarm re-arms |

To change the hold duration, edit the `setTimeout(resetSunrise, 600_000)` call inside `animateSunrise`.

---

## Browser API Usage

| API | Usage | Fallback |
|---|---|---|
| `requestAnimationFrame` | Sunrise color loop | N/A (universal) |
| NoSleep.js | Prevent screen sleep (wraps silent video trick) | Degrades gracefully if autoplay blocked |
| `Element.requestFullscreen` | Immersive mode on first tap | Vendor prefixes tried; silent fail |
| `localStorage` | Persist settings | Silent fail in private browsing |

---

## Interaction Model

- **Any tap/click** outside the panel → show gear icon for 3 s, request fullscreen.
- **Gear click** → toggle settings panel. Icon stays visible while panel is open.
- **Escape key** → close settings panel.
- **Click outside panel** → close panel.
- **Alarm match** → `checkAlarm` fires once per `HH:MM` match, resets when time moves on.

---

## Known Constraints / Extension Points

- Time display is `HH:MM` only (no seconds). To add seconds: add a `#clock-ss` span, update `formatTime()` and `fitClock()` (portrait would need three rows or a smaller scale); the 500 ms tick interval is already sufficient.
- Alarm fires a visual sunrise only — no audio. To add audio: call `new Audio(url).play()` inside `triggerSunrise()`.
- Sunrise hold duration is hardcoded at 10 minutes (`600_000` ms in the `setTimeout` inside `animateSunrise`). To make it configurable, expose a `resetDelaySecs` field in `state`, the settings panel, and `localStorage`.
- `sunriseDur` clamp is 10 – 3600 s. Adjust `min`/`max` on `#sunrise-dur-input` and the `Math.max/min` guard in its event handler.
- Portrait ghost content is `'88'` per span (correct for two digits). If seconds are added in portrait, add a third span with its own `::before`.

---

## App Behavior

### Core Features

1. **Digital Clock Display**: The app dynamically updates the time every 500ms, ensuring accurate real-time display.
2. **Alarm Functionality**: Users can set an alarm, which triggers a sunrise animation when the specified time is reached.
3. **Sunrise Animation**: A gradual color overlay simulates a sunrise, easing users into their day.
4. **Responsive Design**: The clock adapts to both landscape and portrait orientations, optimizing the layout for any device.
5. **Settings Panel**: Users can customize the clock color, alarm time, and sunrise duration via an intuitive settings panel.
6. **Offline Support**: The app functions offline, thanks to a service worker implementing a cache-first strategy.

### User Interactions

- **Clock Customization**: Users can change the clock's color, which updates the display and glow effects in real-time.
- **Alarm Management**: Alarms can be set or cleared, with visual indicators showing the alarm status.
- **Fullscreen Mode**: A single click outside the settings panel enables fullscreen mode for an immersive experience.
- **Settings Persistence**: User preferences are saved in `localStorage` and automatically loaded on app start.

### Background Processes

- **Real-Time Updates**: The `tickClock()` function ensures the time display is always current.
- **Alarm Monitoring**: The `checkAlarm()` function continuously checks if the current time matches the alarm time.
- **Sunrise Animation**: The `animateSunrise()` function runs a smooth animation loop, creating a visually appealing transition.
