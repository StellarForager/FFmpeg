# Xdcheckin-FFmpeg
Minimal FFmpeg with h.264 for Xdcheckin.

## Build Status
[![Build for linux_aarch64](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-linux_aarch64.yml/badge.svg)](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-linux_aarch64.yml) <br>
[![Build for linux_armv7l](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-linux_armv7l.yml/badge.svg)](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-linux_armv7l.yml) <br>
[![Build for linux_i686](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-linux_i686.yml/badge.svg)](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-linux_i686.yml) <br>
[![Build for linux_x86_64](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-linux_x86_64.yml/badge.svg)](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-linux_x86_64.yml) <br>
[![Build for macosx_12_7_x86_64](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-macosx_12_7_x86_64.yml/badge.svg)](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-macosx_12_7_x86_64.yml) <br>
[![Build for macosx_14_7_arm64](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-macosx_14_7_arm64.yml/badge.svg)](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-macosx_14_7_arm64.yml) <br>
[![Build for win32](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-win32.yml/badge.svg)](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-win32.yml) <br>
[![Build for win_amd64](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-win_amd64.yml/badge.svg)](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-win_amd64.yml) <br>
[![Build for win_arm64](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-win_arm64.yml/badge.svg)](https://github.com/Pairman/Xdcheckin-FFmpeg/actions/workflows/build-win_arm64.yml)

## Usage
Install:
```sh
pip install xdcheckin-ffmpeg
```

Import, get FFmpeg executable path and its version:
```python
import xdcheckin_ffmpeg
print(xdcheckin_ffmpeg.bin.ffmpeg()) # or xdcheckin_ffmpeg.ffmpeg()
print(xdcheckin_ffmpeg.bin.ffmpeg_version()) # or xdcheckin_ffmpeg.ffmpeg_version()
```

## Credits
[zimbatm/ffmpeg-static](https://github.com/zimbatm/ffmpeg-static) <br>
[fdk-acc-free](https://cgit.freedesktop.org/~wtay/fdk-aac/log/?h=fedora) <br>
[imageio/imageio-ffmpeg](https://github.com/imageio/imageio-ffmpeg)
