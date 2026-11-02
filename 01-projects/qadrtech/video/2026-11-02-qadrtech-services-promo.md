---
type: video
brand: qadrtech
title: Qadr Tech — Services Promo (EN)
date: 2026-11-02
status: rendered
template: qadrtech-promo
project_dir: ~/Projects/qadrtech-hq/videos/qadrtech-services-promo
generated_by: claude
tags: [qadrtech, video, motion-graphics]
variants:
  - id: promo-en
    label: Services Promo (EN, 9:16)
    path: ~/Projects/qadrtech-hq/videos/qadrtech-services-promo/out/qadrtech-services-en.mp4
    format: 1080x1920 30fps
    duration: 46.3
    status: rendered
    published: []
  - id: promo-en-wide
    label: Services Promo (EN, 16:9)
    path: ~/Projects/qadrtech-hq/videos/qadrtech-services-promo/out/qadrtech-services-en-wide.mp4
    format: 1920x1080 30fps
    duration: 46.3
    status: rendered
    published: []
  - id: avatar-en
    label: Services Promo (EN, avatar VO, 9:16)
    path: ~/Projects/qadrtech-hq/videos/qadrtech-services-promo/out/qadrtech-services-avatar-en.mp4
    format: 1080x1920 30fps
    duration: 46.7
    status: rendered
    published: []
  - id: avatar-en-wide
    label: Services Promo (EN, avatar VO, 16:9)
    path: ~/Projects/qadrtech-hq/videos/qadrtech-services-promo/out/qadrtech-services-avatar-en-wide.mp4
    format: 1920x1080 30fps
    duration: 46.7
    status: rendered
    published: []
---

Motion-graphics promo for Qadr Tech Solutions' services: custom web applications, workflow digitalization, and company websites. Concept: "The shape of your work". A generic software block doesn't fit the team's workflow outline. Qadr Tech builds the matching piece, which snaps in at the climax of the process scene.

Scenes: hook (block doesn't fit) → problem (spreadsheets and documents, the same data copied) → services (3 panels assemble from tiles) → process (Understand → Define/you approve → Build & Review → Deliver, then the piece snaps in) → proof (real project screenshots, "used every working day", higher education since 2017) → CTA ("We'll build around it.") → end card (logo, qadr.tech, Discuss Your Needs).

- Formats: 16:9 for YouTube, LinkedIn, and the qadr.tech website; 9:16 for Instagram Reels, YouTube Shorts, and LinkedIn mobile.
- Source: ~/Projects/qadrtech-hq/qadr-tech (website copy).
- Script: ~/Projects/qadrtech-hq/videos/qadrtech-services-promo/docs/naskah-voice-over.md
- Captions:
  - ~/Projects/qadrtech-hq/videos/qadrtech-services-promo/caption-instagram-en.md
  - ~/Projects/qadrtech-hq/videos/qadrtech-services-promo/caption-linkedin-en.md
  - ~/Projects/qadrtech-hq/videos/qadrtech-services-promo/caption-youtube-en.md
  - ~/Projects/qadrtech-hq/videos/qadrtech-services-promo/caption-web-en.md
- Posters: out/poster-wide.jpg, out/poster-vertical.jpg

Production notes:
- VO: Gemini TTS `gemini-3.8-flash-tts`, voice Sulafat.
  - Parts 3 and 5 read the director's notes aloud. Part 5 was trimmed (`trimStart` 18.7 s). Part 3 was regenerated with the transcript only, so its tone may differ slightly. Re-check by ear.
  - The bad takes are in `voiceovers-retake/`.
- No client names in VO, on-screen text, or captions (no permission yet). Screenshots are cropped, and the institution name and seal are blurred.
- Not used: "Eight documented projects" from the About page, because the repo lists 11 projects.
- Audio: −14.3 LUFS, peak −1.5 dBFS.
- After the video is done: delete the Gemini API key / `.env` in the project folder.

Avatar VO version (`avatar-en`, `avatar-en-wide`):
- Same visuals and dialogue as the Gemini version. Only the audio comes from avatar clips (standard template workflow).
- Script with avatar prompts: ~/Projects/qadrtech-hq/videos/qadrtech-services-promo/docs/naskah-voice-over-avatar.md
- Clips: `voiceovers-avatar/part-1..6.mp4`, joined by `vo-avatar.config.json` → `public/vo-avatar.wav` (43.05 s). Variant: `src/variants/promo-avatar-en.ts`.
- Audio: −14.3 LUFS, peak −1.7 dBFS.
- Re-check by ear:
  - Whisper heard "approvals **and** spreadsheets", "reports **and** documents", and "**and** educational institution". These are probably mishearings of "in" and "an".
  - Part 4 has a ~0.9 s pause after "First,".
- The captions are shared with the Gemini version. YouTube chapters for this version are in caption-youtube-en.md.
