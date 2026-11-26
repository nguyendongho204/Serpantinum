# Cấu hình fish tối giản, có thể dùng trên mọi distro.
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

fish_add_path -g ~/.local/bin
if test -d ~/.pixi/bin
    fish_add_path -g ~/.pixi/bin
end
