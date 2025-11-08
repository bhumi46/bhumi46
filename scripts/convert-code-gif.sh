#!/usr/bin/env bash
# Convert code.gif into modern web-friendly formats (WebM VP9, AV1, MP4 H.264) and animated WebP.
# Usage: ./scripts/convert-code-gif.sh path/to/code.gif output-dir
set -euo pipefail

INPUT="${1:-code.gif}"
OUTDIR="${2:-dist}"
mkdir -p "$OUTDIR"

# Parameters (tweak for quality/size tradeoff)
MAX_WIDTH=${MAX_WIDTH:-1280}   # resize if wider than this
FPS=${FPS:-20}           # reduce fps for smaller size (adjust to taste)
CRF_VP9=${CRF_VP9:-30}       # lower -> higher quality (VP9)
CRF_AV1=${CRF_AV1:-30}       # AV1 quality
CRF_H264=${CRF_H264:-23}     # H.264 quality
Q_WEBP=${Q_WEBP:-75}

# Compute scale filter to keep even dimensions (required by many encoders)
SCALE_FILTER="scale='if(gt(iw,${MAX_WIDTH}),trunc(${MAX_WIDTH}/2)*2,iw)':'trunc(ih/2)*2'"

echo "Converting $INPUT → $OUTDIR ..."

# Detect available encoders (prefer svt-av1 if available for faster AV1 encoding)
FFMPEG_AV1_ENCODER="libaom-av1"
if ffmpeg -hide_banner -encoders | grep -q "libsvtav1"; then
  FFMPEG_AV1_ENCODER="libsvtav1"
fi

# WebM (AV1) — higher compression, slower encode
ffmpeg -y -i "$INPUT" -an -vf "$SCALE_FILTER,fps=${FPS}" -c:v ${FFMPEG_AV1_ENCODER} -crf ${CRF_AV1} -b:v 0 -pix_fmt yuva420p "$OUTDIR/code-av1.webm"

# WebM (VP9)
ffmpeg -y -i "$INPUT" -an -vf "$SCALE_FILTER,fps=${FPS}" -c:v libvpx-vp9 -b:v 0 -crf ${CRF_VP9} -pix_fmt yuva420p "$OUTDIR/code-vp9.webm"

# MP4 (H.264) — good fallback for non-WebM browsers
ffmpeg -y -i "$INPUT" -an -vf "$SCALE_FILTER,fps=${FPS}" -c:v libx264 -preset slow -crf ${CRF_H264} -pix_fmt yuv420p -movflags +faststart "$OUTDIR/code-h264.mp4"

# Animated WebP
ffmpeg -y -i "$INPUT" -vf "$SCALE_FILTER,fps=${FPS}" -loop 0 -lossless 0 -qscale ${Q_WEBP} -preset default "$OUTDIR/code.webp"

# Optimized GIF re-encoded (optional fallback)
ffmpeg -y -i "$INPUT" -vf "$SCALE_FILTER,fps=${FPS}" -gifflags -transdiff -y "$OUTDIR/code-optimized.gif"

printf "\nDone. Files placed in %s:\n" "$OUTDIR"
ls -1 "$OUTDIR"
