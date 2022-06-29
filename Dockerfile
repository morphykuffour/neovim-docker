FROM alpine:3.13 AS builder

LABEL maintainer="morp"
ENV \
    UID="1000" \
    GID="1000" \
    UNAME="neovim" \
    GNAME="neovim" \
    SHELL="/bin/bash" \
    WORKSPACE="/mnt/workspace" \
	NVIM_CONFIG="/home/neovim/.config/nvim" \
	NVIM_PCK="/home/neovim/.local/share/nvim/site/pack" \
	ENV_DIR="/home/neovim/.local/share/vendorvenv" \
	NVIM_PROVIDER_PYLIB="python3_neovim_provider" \
	PATH="/home/neovim/.local/bin:${PATH}"

ARG BUILD_DEPS="autoconf automake cmake curl g++ gettext gettext-dev git libtool make ninja openssl pkgconfig unzip binutils"
ARG TARGET=nightly


# build neovim nightly
RUN apk add --no-cache ${BUILD_DEPS} && \
  git clone https://github.com/neovim/neovim.git /tmp/neovim && \
  cd /tmp/neovim && \
  git fetch --all --tags -f && \
  git checkout ${TARGET} && \
  make CMAKE_BUILD_TYPE=Release && \
  make CMAKE_INSTALL_PREFIX=/usr/local install && \
  strip /usr/local/bin/nvim 

# install packer.nvim
RUN git clone --depth 1 https://github.com/nvim-lua/plenary.nvim ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim


FROM alpine:3.13
COPY --from=builder /usr/local /usr/local/
RUN true # see: https://github.com/moby/moby/issues/37965
# Required shared libraries
COPY --from=builder /lib/ld-musl-x86_64.so.1 /lib/
RUN true
COPY --from=builder /usr/lib/libgcc_s.so.1 /usr/lib/
RUN true
COPY --from=builder /usr/lib/libintl.so.8 /usr/lib/


CMD ["/usr/local/bin/nvim"]
