# Gói phụ thuộc

- `pacman.txt`: gói có trong repo Arch/CachyOS.
- `aur.txt`: gói AUR (CachyOS có sẵn `noctalia-qs` thay cho `quickshell`).

```bash
sudo pacman -S --needed $(grep -v '^#' packages/pacman.txt | tr '\n' ' ')
yay -S --needed $(grep -v '^#' packages/aur.txt | tr '\n' ' ')
```

`quickshell` là bắt buộc. Trên CachyOS, gói `noctalia-qs` cung cấp `/usr/bin/quickshell`.
