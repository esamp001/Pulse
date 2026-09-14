# Image-First Modern Design Standards

## 1. Vision & Design Philosophy

Pulse / Rally is a mobile sports platform designed to turn casual matches into verified competitive games. To convey energy, athleticism, and modern premium quality, our UI/UX follows an **Image-First Design Philosophy**.

Text-heavy layouts and plain monolithic cards feel like admin dashboards. Modern consumer sports applications must be **visually immersive**, leading with rich imagery—including high-definition court photographs, dynamic sport graphics, and clear participant avatars—while maintaining ultra-clean, borderless surface structures.

---

## 2. Core Image-First Design Patterns

### 2.1 Split-Hero Cards (e.g., Match Invitations, Lobby Banners, Active Match Cards)
Components presenting matches, invitations, or court bookings should lead with a two-tone **Split-Hero** layout:

1. **Upper Hero Section (Image Layer)**:
   - **Full-Bleed Cover**: Use `BoxFit.cover` across a dedicated height container (typically 100dp–140dp) to showcase the venue or match context.
   - **Gradient Scrim Overlay**: ALWAYS place a natural vertical gradient scrim over the image to guarantee high-contrast legibility for text and badges overlaid on the photo:
     ```dart
     DecoratedBox(
       decoration: BoxDecoration(
         gradient: LinearGradient(
           begin: Alignment.topCenter,
           end: Alignment.bottomCenter,
           colors: [
             Colors.black.withValues(alpha: 0.20),
             Colors.black.withValues(alpha: 0.45),
             Colors.black.withValues(alpha: 0.75),
           ],
           stops: const [0.0, 0.45, 1.0],
         ),
       ),
     )
     ```
   - **Floating Contextual Pills**: Position floating status pills, sport category tags, or countdown timers directly over the image hero (e.g. mint countdown pill, sport label).

2. **Lower Action Surface (Information & Controls)**:
   - Clean, borderless surface fill (`PulseColors.getSurface(isDark)`).
   - Participant details with circular avatar, role description, and action buttons.

---

### 2.2 Multi-Tier Graceful Imagery Fallbacks
Components that rely on imagery MUST NOT break, show blank boxes, or display ugly grey placeholders when a network image is unavailable or loading fails. Implement a strict **3-Tier Fallback Strategy**:

1. **Tier 1: High-Resolution Photo**:
   - Display court photo or user avatar from CDN/network URL.
   - Always sanitize strings (`trim()`, check `.isNotEmpty`).

2. **Tier 2: Authentic Athletic Vector Graphic Fallback**:
   - If no photo exists (or network load errors out), render a stylized athletic court canvas using `CustomPainter` with court perimeter lines, net dividers, and a subtle watermark of the respective sport icon (`PulseSportIcons` at 15–20% opacity):
     ```dart
     // Background athletic dark gradient + court line painter + sport watermark
     Container(
       decoration: const BoxDecoration(
         gradient: LinearGradient(
           begin: Alignment.topLeft,
           end: Alignment.bottomRight,
           colors: [Color(0xFF143B37), Color(0xFF0C2422)],
         ),
       ),
       child: Stack(
         children: [
           CustomPaint(painter: _CourtGridLinePainter(...)),
           Positioned(
             right: -10, bottom: -14,
             child: Opacity(opacity: 0.18, child: PulseSportIcons.buildWidget(sportKey, size: 90)),
           ),
         ],
       ),
     )
     ```

3. **Tier 3: Monogram Initial Badges (for Users / Avatars)**:
   - For users without avatars, generate a circular avatar with brand primary tint (`PulseColors.primary.withValues(alpha: 0.12)`) and a bold initial monogram in `Lexend` typography.

---

### 2.3 Venue & Court Cards
- Every court or venue representation (in `CourtFinderScreen`, `CourtPickerModal`, `CreateMatchScreen`, and `CourtCard`) must lead with the court photo.
- Details such as distance, surface type, indoor/outdoor tags, and rating badges should float as semi-transparent pills over the image banner.

### 2.4 Avatars Across All Social & Match Touchpoints
- Any list, card, notification, or drawer item showing a player, host, opponent, or referee must include their circular avatar.
- Never display anonymous plain text names without visual avatar anchors.

---

## 3. Interaction with Core Project Rules

Image-first styling must strictly harmonize with the project's foundational UI standards:

1. **Strict No Drop Shadow Rule**:
   - Do NOT add drop shadows (`boxShadow`, `elevation`) under image cards or hero headers.
   - Use contrast, surface color shifts, and gradient scrims for visual separation—not shadows.

2. **Clean Borderless Design**:
   - Rely on borderless surface fills rather than heavy stroke outlines (`BorderSide.none`).
   - Image hero headers blend seamlessly into rounded cards (`clipBehavior: Clip.antiAlias`).

3. **Responsive Overflow Protection (280x520 Viewports)**:
   - Text overlays and hero header rows must wrap titles and location labels in `Flexible` or `Expanded` with `TextOverflow.ellipsis`.
   - Action buttons below the hero must wrap in `FittedBox(fit: BoxFit.scaleDown)` to prevent any `RenderFlex` overflow on ultra-small mobile devices.

4. **Dynamic Light & Dark Adaptation**:
   - Scrims, fallbacks, and surface fills must dynamically adapt between light and dark modes via `PulseColors` (`getSurface`, `getTextPrimary`, `getTextSecondary`).

---

## 4. Summary Checklist for New Screens & Components
- [ ] Does this component feature relevant photos (court, user avatar, sport banner) rather than plain text?
- [ ] Is there a natural gradient scrim over the image ensuring legible white typography?
- [ ] Is a 3-tier athletic vector fallback implemented in case the image is missing or offline?
- [ ] Are all drop shadows removed (`elevation: 0`, `shadowColor: Colors.transparent`)?
- [ ] Are containers and inputs borderless?
- [ ] Does it pass the mandatory 280x520 responsive overflow test?
