# OBS — Screen Region Sharing

OBS is installed on all machines via Homebrew cask. Its primary use here is sharing a specific region of a large screen (e.g. a 49" ultrawide) during video calls, using the Virtual Camera feature.

## How it works

OBS captures a cropped region of your display and outputs it as a virtual camera. You then select "OBS Virtual Camera" in your call app (Zoom, Meet, Teams, etc.) — the other person sees only that region, not your full screen.

## First-time setup

### 1. Create a scene with a cropped display

1. Open OBS
2. In the **Scenes** panel, click **+** → name it (e.g. `Screen Share`)
3. In the **Sources** panel, click **+** → **Display Capture** → name it and pick your display
4. Right-click the source → **Filters** → **+** → **Crop/Pad**
5. Set **Left**, **Top**, **Width**, **Height** to define the rectangle you want to share

> Tip: use **Edit → Transform → Edit Transform** (Ctrl+E) on the source to see exact pixel coordinates. On a 49" ultrawide (5120×1440) a half-screen zone would be width=2560, height=1440.

### 2. Match the canvas to your crop

Go to **Settings → Video** and set **Base (Canvas) Resolution** to the same size as your crop (e.g. 2560×1440). This avoids letterboxing in the call.

### 3. Enable the Virtual Camera

Click **Start Virtual Camera** in the Controls panel. OBS must be running and the virtual camera active before joining a call.

### 4. Select it in your call app

| App | Where to change |
|-----|-----------------|
| Zoom | Settings → Video → Camera → OBS Virtual Camera |
| Google Meet | Settings (gear) → Video → OBS Virtual Camera |
| Teams | Settings → Devices → Camera → OBS Virtual Camera |
| Discord | User Settings → Voice & Video → Camera → OBS Virtual Camera |

## Per-region scenes

You can create multiple scenes for different sharing zones (e.g. `Left Half`, `Right Half`, `Center Code`, `Full Screen`) and switch between them while a call is active — the virtual camera updates instantly.

## Zoom users

Zoom has a built-in region share that does not require OBS:

**Share Screen → Advanced → Portion of Screen**

A green resizable rectangle appears. Only that area is shared. Use this when you only need Zoom — no OBS setup required.
