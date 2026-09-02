---
name: animation-vocabulary
description: "Use as an augmenting motion reference when a product UI task includes transitions, micro-interactions, hover or press feedback, scroll effects, springs, easing, loops, or motion performance. Frontend-design remains primary for product UI; use this skill directly for animation-vocabulary questions. Not for: static styling; becoming the primary frontend design route."
---

# Animation Vocabulary

A shared vocabulary for UI/web motion, plus the defaults that make animation feel right instead of decorative. Use the exact terms below when proposing or critiquing motion so intent is unambiguous. Source: Emil Kowalski, animations.dev/vocabulary.

Use this as an augmenting motion reference alongside `frontend-design` for product UI; `frontend-design` remains primary for product UI direction. Use this skill directly only for animation-vocabulary or motion-reference questions, not static styling.

## Sensible defaults (apply unless there's a reason not to)

- **Easing:** `ease-out` for most UI (enter/feedback). `ease-in-out` for elements moving A→B on screen. `linear` only for spinners/marquees. Avoid plain `ease-in` (feels sluggish).
- **Animate `transform` and `opacity` only** — they're GPU-composited. Animating `width`/`height`/`top`/`left` causes layout thrashing and jank.
- **Duration:** enter/exit ~150–300ms. Shorter for frequently-seen motion, longer for large/rare transitions. Springs use physics, not a fixed duration.
- **Respect `prefers-reduced-motion`** — tone down or remove motion. Always.
- **Purposeful only:** motion should orient, give feedback, or show a relationship. If it does none of those, cut it.
- **Frequency rule:** the more often a user sees an animation, the shorter and subtler it should be.
- **Origin-aware:** elements should animate from their trigger (popover grows from its button), and keep spatial consistency across states so users don't lose track.

## Entrances & Exits
How elements appear and disappear.

- **Fade in/out** — appear/disappear via opacity.
- **Slide in** — enter from off-screen (any direction).
- **Scale in** — grow from smaller to full size, often paired with fade.
- **Pop in** — appear with slight overshoot; "bounces into place."
- **Reveal** — content uncovered gradually via clip-path or mask.
- **Enter/Exit** — animation played when an element is added to / removed from the screen.

## Sequencing & Timing

- **Keyframes** — defined points (0%, 50%, 100%) the browser interpolates between.
- **Interpolation/Tween** — generating in-between frames for continuous motion.
- **Stagger** — items animated sequentially with small delays, creating a cascade.
- **Orchestration** — deliberately timing multiple animations to feel coordinated.
- **Delay** — time before an animation starts.
- **Duration** — how long an animation takes.
- **Fill mode** — whether an element keeps first/last frame styles before/after animation (e.g. `forwards`).
- **Stepped animation** — divided into discrete steps, like a countdown timer.

## Movement & Transforms

- **Translate** — move along X or Y.
- **Scale** — bigger or smaller.
- **Rotate** — spin around a point.
- **Skew** — slant/shear along X or Y.
- **3D tilt/Flip** — rotate in 3D (`rotateX`/`rotateY`) for depth.
- **Perspective** — strength of the 3D effect; lower value exaggerates depth.
- **Transform origin** — anchor point a scale/rotation grows or spins from.
- **Origin-aware animation** — element animates from its trigger (popover growing from its button).

## Transitions Between States

- **Crossfade** — one element fades out as another fades in at the same position.
- **Continuity transition** — keeps the user oriented by visually connecting before/after states.
- **Morph** — one shape smoothly becomes another (e.g. Dynamic Island).
- **Shared element transition** — element travels/transforms between positions (thumbnail → card).
- **Layout animation** — size/position changes animate instead of snapping.
- **Accordion/Collapse** — smooth height expand/collapse to show/hide content.
- **Direction-aware transition** — content slides forward/backward based on navigation direction.

## Scroll

- **Scroll reveal** — elements fade/slide in as they enter the viewport.
- **Scroll-driven animation** — animation progress tied directly to scroll position.
- **Parallax** — background and foreground move at different speeds for depth.
- **Page transition** — animation when navigating between pages/routes.
- **View transition** — browser morphs between two states/pages, connecting shared elements.

## Feedback & Interaction

- **Hover effect** — visual change on cursor-over.
- **Press/Tap feedback** — subtle scale-down on click to feel physical.
- **Hold to confirm** — progress fill while the user holds a button.
- **Drag** — move an element by grabbing it, often with release momentum.
- **Drag to reorder** — drag list items to rearrange while others shift to make room.
- **Swipe to dismiss** — drag off-screen to close (drawer/toast).
- **Rubber-banding** — resistance and snap-back when dragging past a boundary.
- **Shake/Wiggle** — quick side-to-side jitter signaling error/rejected input.
- **Ripple** — circle expanding from the tap point, confirming the press.

## Easing

- **Easing** — the rate an animation speeds up or slows down.
- **Ease-out** — fast → slow. Default for most UI.
- **Ease-in** — slow → fast. Often feels sluggish.
- **Ease-in-out** — slow → fast → slow. Good for elements moving A→B on screen.
- **Linear** — constant speed. Reserve for spinners/marquees.
- **Cubic-bezier** — custom easing curve for precise control.
- **Asymmetric easing** — accelerates and decelerates at different rates; "feels more alive."

## Spring Animations

- **Spring** — physics-driven motion (tension, mass, damping); no fixed duration.
- **Stiffness/Tension** — how hard the spring pulls toward target; higher = snappier.
- **Damping** — how quickly it settles; lower = more bounce.
- **Mass** — heavier = slower, more sluggish.
- **Bounce** — spring overshoots and settles back, adding playfulness.
- **Perceptual duration** — how long a spring *feels* finished, even while micro-settling.
- **Momentum** — carries velocity, especially after drag or interruption.
- **Velocity** — speed/direction of movement, carried into the next animation when interrupted.
- **Interruptible animation** — can be smoothly redirected mid-flight rather than finishing first.

## Looping & Ambient Motion

- **Marquee** — content scrolling continuously in a loop.
- **Loop** — animation repeating a set number of times or infinitely.
- **Alternate (yoyo)** — loop plays forward then reverses each iteration.
- **Orbit** — element circling another in a continuous path.
- **Pulse** — gentle repeating scale/opacity change to draw attention.
- **Float** — gentle continuous up-and-down drift; makes static elements feel alive.
- **Idle animation** — subtle motion while an element waits to be interacted with.

## Polish & Effects

- **Blur** — soften an element or mask tiny imperfections.
- **Clip-path** — clip to a shape; used for reveals, masks, before/after sliders.
- **Mask** — hide/reveal parts via shape or gradient; allows soft, fadeable edges.
- **Before/after slider** — draggable divider wiping between two overlaid images.
- **Line drawing** — SVG path that draws itself in like a tracing pen.
- **Text morph** — text animates character by character when its value changes.
- **Skeleton/Shimmer** — placeholder with a moving sheen shown while content loads.
- **Number ticker** — digits rolling/counting up to a value.
- **Tabular numbers** — fixed-width digits so numbers don't shift as they change; essential for tickers/timers.
- **Typewriter** — text appearing one character at a time, as if typed.

## Performance

- **Frame rate (FPS)** — frames per second; 60fps baseline, 120fps on newer displays.
- **Jank** — visible stutter when the browser drops frames.
- **Dropped frame** — a missed deadline to draw a frame, causing a hitch.
- **Compositing** — GPU moves/fades an element on its own layer without redoing layout or paint.
- **will-change** — CSS hint that promotes an element to its own layer ahead of animation.
- **Layout thrashing** — animating width/height/top/left forces layout recalculation every frame.

## Principles to Know

- **Purposeful animation** — orient, give feedback, or show relationships; never just decorate.
- **Anticipation** — small wind-up in the opposite direction before a move, hinting what's coming.
- **Follow-through** — parts keep moving and settle slightly after the main motion stops; adds weight.
- **Squash & stretch** — deform to convey weight, speed, and flexibility.
- **Perceived performance** — the right animation makes an interface feel faster even when it isn't.
- **Frequency of use** — more often seen → shorter and subtler.
- **Spatial consistency** — elements keep identity/position across states so users don't lose track.
- **Hardware acceleration** — animating `transform`/`opacity` lets the GPU keep motion smooth.
- **Reduced motion** — respect `prefers-reduced-motion`; tone down or remove.
