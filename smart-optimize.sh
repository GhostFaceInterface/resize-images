#!/usr/bin/env bash
# v2-min — sade ve sağlam: her şeyi WebP'ye çevirir, SKIP yok, ilk kare işlenir
set -u  # (bilinçli olarak -e yok; her dosyada devam etsin)
IFS=$'\n\t'

echo "[smart-optimize] v2-min"

IN_DIR="${1:-$HOME/r34}"
OUT_DIR="${2:-${IN_DIR}_out}"

# Hedefler
PREFERRED_MAX=$((500 * 1024))   # 500 KB hedef
HARD_MAX=$((1000 * 1024))       # 1 MB üst sınır

# Kalite / boyut denemeleri
START_Q=82       # kalite başlangıcı
MIN_Q=50         # en düşük kalite
Q_STEP=5         # kalite adımı
START_W=2000     # uzun kenar başlangıç
MIN_W=1200       # uzun kenar alt sınır
W_STEP=200       # genişlik adımı
ALPHA_Q=85       # (varsa) alfa kalite

need() { command -v "$1" >/dev/null 2>&1 || { echo "Gerekli araç yok: $1" >&2; exit 1; }; }
need cwebp
command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1 || { echo "ImageMagick gerekli." >&2; exit 1; }

digits_only(){ tr -cd '0-9' <<< "${1:-}"; }
bytes() {
  local out
  if stat -f%z "$1" >/dev/null 2>&1; then out=$(stat -f%z "$1" 2>/dev/null || echo 0)
  else out=$(stat -c%s "$1" 2>/dev/null || echo 0); fi
  out=$(digits_only "$out"); echo "${out:-0}"
}
kb(){ awk -v b="${1:-0}" 'BEGIN{printf "%.1f", b/1024.0}'; }

# tek deneme: (src -> dst) : src[0] tek kare alınır, resize edilir, cwebp ile encode edilir
encode_once() {
  # $1=src $2=dst $3=quality $4=max_width
  local src="$1" dst="$2" q="$3" w="$4"
  mkdir -p "$(dirname "$dst")"
  if command -v magick >/dev/null 2>&1; then
    # PNG32:- => RGBA pipe; [0] ilk kare (statik dosyada da sorun olmaz)
    magick "$src[0]" -auto-orient -resize "${w}x>" -strip PNG32:- \
      | cwebp -q "$q" -alpha_q "$ALPHA_Q" -m 6 -mt -af -quiet -o "$dst" -- - >/dev/null 2>&1
  else
    convert "$src[0]" -auto-orient -resize "${w}x>" -strip PNG32:- \
      | cwebp -q "$q" -alpha_q "$ALPHA_Q" -m 6 -mt -af -quiet -o "$dst" -- - >/dev/null 2>&1
  fi
}

encode_to_target() {
  # $1=src $2=dst
  local src="$1" dst="$2" q="$START_Q" w="$START_W" sz=0
  while :; do
    encode_once "$src" "$dst" "$q" "$w"
    sz=$(bytes "$dst")

    # hedefleri tuttuysa çık
    if [ "$sz" -le "$HARD_MAX" ]; then
      [ "$sz" -le "$PREFERRED_MAX" ] && return 0
    fi

    # kaliteyi düşür
    if [ "$q" -gt "$MIN_Q" ]; then
      q=$((q - Q_STEP)); continue
    fi
    # kalite tabanına geldiysek genişliği biraz daha indir ve kaliteyi resetle
    if [ "$w" -gt "$MIN_W" ]; then
      w=$((w - W_STEP)); q="$START_Q"; continue
    fi

    # buraya düştüysek 1 MB altına inemedik; eldeki en iyiyi bırak
    return 0
  done
}

process_one() {
  local src="$1" rel dst out_sz
  rel="${src#$IN_DIR/}"
  dst="$OUT_DIR/${rel%.*}.webp"

  # Görsel uzantılarını kabaca filtrele; değilse kopyala
  case "${src##*.}" in
    jpg|JPG|jpeg|JPEG|png|PNG|webp|WEBP|gif|GIF|tif|TIF|tiff|TIFF|bmp|BMP) ;;
    *) mkdir -p "$(dirname "$dst")"; cp -p "$src" "$OUT_DIR/$rel"; echo "[COPY] $rel"; return;;
  esac

  encode_to_target "$src" "$dst"
  out_sz=$(bytes "$dst")
  echo "[WEBP] $rel → $(kb "$out_sz") KB"
}

main() {
  echo "IN : $IN_DIR"
  echo "OUT: $OUT_DIR"
  mkdir -p "$OUT_DIR"

  # boşluklu adlar için güvenli okuma
  find "$IN_DIR" -type f -print0 | while IFS= read -r -d '' f; do
    process_one "$f" || true
  done

  echo "Bitti. Özet:"
  (du -sh "$OUT_DIR" 2>/dev/null || true)
}
main "$@"