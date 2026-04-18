# MoonPad

A Moonlight-based game-streaming client for iOS, focused on PC emulator streaming. Forked from [VoidLink](https://github.com/TrueZhuangJia/VoidLink), which was itself forked from the upstream [moonlight-iOS](https://github.com/moonlight-stream/moonlight-ios).

## What MoonPad adds on top of VoidLink

- **Platform resolution presets** — in place of the generic 720p/1080p/4K selectors, a `Platform` mode exposes per-console base resolutions (PS1 320×240, 3DS 400×480 stacked) with a 1×–4× scale multiplier. `Safe Area`, `FullScr/Window`, and `Custom` remain for non-emulator use.
- **Emulator controller skins** — a runtime skin system renders a console-themed overlay on top of the stream, with per-button hit areas, thumbsticks, extended-edge hit testing, and per-screen video regions. Bundled: `PS1.manicskin`, `PS1_FLEX.manicskin`, `ModernBlack.manicskin` (3DS).
- **Dual-screen rendering for Nintendo 3DS** — the streamed composite frame is split into top and bottom screens using the skin's `screens[]` layout. An auxiliary `AVSampleBufferDisplayLayer` receives the same decoded sample buffer queue as the primary, cropped and positioned to its region.
- **Per-region touch modes** — top screen acts as a relative-mouse trackpad; bottom screen acts as an absolute-position touchscreen with left-click press/release, so Azahar / Citra / Lime3DS register it as a native 3DS stylus touch.
- **Canonical source layouts** — MoonPad pins the expected on-wire frame layout per platform, so a third-party skin's `inputFrame` values can't silently mismap when the PC-side capture geometry doesn't match.

## Quick start — streaming a 3DS emulator

1. On the PC, install a virtual display driver (e.g. [VirtualDisplayDriver](https://github.com/itsmikethetech/Virtual-Display-Driver)) and add a 1600×1920 portrait display.
2. In Azahar / Citra / Lime3DS, enable **Use Custom Layout** under Graphics, with:
   - Top screen: `x=0, y=0, width=1600, height=960`
   - Bottom screen: `x=160, y=960, width=1280, height=960`
3. Move the emulator to the virtual display and fullscreen it.
4. Configure Sunshine to capture that display.
5. In MoonPad: **Settings → Resolution → Platform → 3DS → 4×** (or **Custom** with 1600×1920).

See the [Delta-compatible skin format docs](https://noah978.gitbook.io/delta-docs/skins) for authoring your own skins — MoonPad's loader accepts both `.manicskin` (Manic Emu) and `.deltaskin` (Delta) archives.

## Fork chain

```
moonlight-iOS       (Moonlight Game Streaming Project)
      │ fork
VoidLink            (True砖家 @ Bilibili + community)
      │ fork
MoonPad             (this project)
```

## Attribution

- **[moonlight-iOS](https://github.com/moonlight-stream/moonlight-ios)** — the Moonlight Game Streaming Project supplies the core NVIDIA GameStream / Sunshine client, the decoding pipeline, the H.264/HEVC/AV1 path, and the overwhelming majority of the codebase under MoonPad. MoonPad is a derivative work.
- **[VoidLink](https://github.com/TrueZhuangJia/VoidLink)** — True砖家 (True Zhuanjia) and the VoidLink contributors reworked the UI, added the on-screen controller / widgets / custom-OSC editor, and built the initial skin loader (`SkinController/`) that MoonPad extends. Most of MoonPad's plumbing is their work.
- **Controller skin format** — inspired by and directly interoperable with the skin format used by [Delta](https://github.com/rileytestut/Delta) (Riley Testut) and [Manic Emu](https://github.com/Manic-EMU/ManicEmu), both iOS emulator front-ends. MoonPad's parser reads their `info.json` layout (including `extendedEdges`, multi-screen `screens`, directional / `touchScreenX/Y` inputs) and PDF/PNG assets natively.
- **Bundled skins**
  - `PS1.manicskin`, `PS1_FLEX.manicskin` — shipped with VoidLink.
  - `ModernBlack.manicskin` — 3DS skin by **stars33k**, originally distributed as a Delta-compatible `.deltaskin`.
- **Submodules** — `moonlight-common-c`, `ENet`, `ImGui`, `X1Kit` per upstream Moonlight.

## License

GPLv3, inherited from moonlight-iOS. See [LICENSE.txt](LICENSE.txt). As a derivative work of a GPLv3 project, MoonPad is itself GPLv3, and any further forks must preserve the license and this attribution chain.

## Contributors

From this fork (MoonPad):
- [@raphasouthall](https://github.com/raphasouthall)

From the upstream VoidLink fork:
- [@TrueZhuangJia](https://github.com/TrueZhuangJia)
- [@stefanilijev97](https://github.com/stefanilijev97)
- [@Acaki](https://github.com/Acaki)
- [@seastwood](https://github.com/seastwood)
- [@Danos0100](https://github.com/Danos0100)
- [@xzzpig](https://github.com/xzzpig)
- [@King0fSpace](https://github.com/King0fSpace)

From moonlight-iOS: [full contributor list](https://github.com/moonlight-stream/moonlight-ios/graphs/contributors).
