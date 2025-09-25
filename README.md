# Smart Optimize

**Smart Optimize** klasör içindeki görselleri topluca optimize edip **WebP** formatına dönüştüren, macOS/Linux uyumlu basit bir Bash scriptidir.  
Hedef: görsel kalitesini makul seviyede koruyarak disk kullanımını ve transfer süresini azaltmak.

---

## Özellikler

- Desteklenen giriş formatları: `PNG`, `JPG/JPEG`, `WEBP`, `GIF`, `TIFF`, `BMP` (diğer dosyalar kopyalanır).  
- Animasyonlu GIF/WEBP dosyaları **skip edilmez** — animasyon varsa **ilk kare (frame 0)** alınır ve optimize edilir.  
- Çıktılar her zaman **`.webp`** formatındadır.  
- Hedef boyut:
  - **Tercihen** ≤ `500 KB`  
  - **Kesin üst sınır** ≤ `1 MB`  
- Akıllı döngü: kaliteyi (ör. `82 → 50`) düşür, halen büyükse uzun kenarı (`2000 px → 1200 px`) küçült.  
- Orijinaller korunur; optimize edilmiş dosyalar ayrı bir `*_out` klasöründe toplanır.

---

## Gereksinimler

### macOS (Homebrew)
```bash
brew install webp imagemagick
chmod +x smart-optimize.sh
```
### Örnek kullanım
```bash
 ./smart-optimize.sh ~/folder_name ~/folder_name_out

```