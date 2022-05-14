# Meson Phase 4
python3 setup.py build

python3 setup.py install --root=dest
cp -r dest/* /
install -Dm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -Dm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson

