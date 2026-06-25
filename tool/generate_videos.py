#!/usr/bin/env python3
"""Generate short offline MP4 lesson videos with ffmpeg."""
import json
import subprocess
from pathlib import Path

try:
    import imageio_ffmpeg
except ImportError:
    imageio_ffmpeg = None

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "videos"
VIDEOS_JSON = ROOT / "assets" / "content" / "videos.json"


def _ffmpeg_executable() -> str:
    if imageio_ffmpeg is not None:
        return imageio_ffmpeg.get_ffmpeg_exe()
    return "ffmpeg"


def generate_video(title: str, subtitle: str, output: Path, seconds: int = 8) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    text = f"{title}\\n{subtitle}".replace(":", "\\:").replace("'", "\\'")
    cmd = [
        _ffmpeg_executable(),
        "-y",
        "-f",
        "lavfi",
        "-i",
        f"color=c=0x1E88E5:s=1280x720:d={seconds}",
        "-vf",
        (
            "drawtext=fontcolor=white:fontsize=42:x=(w-text_w)/2:y=(h-text_h)/2-40:"
            f"text='{text}'"
        ),
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        str(output),
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main() -> None:
    videos = json.loads(VIDEOS_JSON.read_text(encoding="utf-8"))
    for video in videos:
        asset = ROOT / video["assetPath"]
        title = video["title"]
        subtitle = f"{video['subject']} · {video['chapter']}"
        print(f"Generating {asset.name} ...")
        generate_video(title, subtitle, asset)

    print(f"Generated {len(videos)} videos in {OUT}")


if __name__ == "__main__":
    main()
