# Meson Phase 4
pip3 wheel -w dist --no-build-isolation --no-deps $PWD

pip3 install --no-index --find-links dist meson
install -Dm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -Dm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson

