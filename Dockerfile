FROM alpine:3.18.4 as alpine-builder
RUN apk --no-cache add git build-base cmake linux-headers lld curl
ARG MIMALLOC_VERSION=2.1.2
RUN cd / \
    && curl -sSLo mimalloc.tar.gz https://github.com/microsoft/mimalloc/archive/refs/tags/v${MIMALLOC_VERSION}.tar.gz \
    && tar -zxvf mimalloc.tar.gz \
    && mv mimalloc-${MIMALLOC_VERSION} mimalloc \
    && cd mimalloc \
    && mkdir build && cd build \
    && cmake -DCMAKE_C_FLAGS="-fuse-ld=lld" .. && make -j$(nproc) && make install

# Package stage
FROM rust:1.73-alpine3.18 as rust
COPY --from=alpine-builder /mimalloc/build/*.so.* /lib/
ARG MIMALLOC_VERSION=2.1
ARG S5CMD_VERSION=2.1.0
RUN ln -s /lib/libmimalloc.so.${MIMALLOC_VERSION} /lib/libmimalloc.so
ENV LD_PRELOAD=/lib/libmimalloc.so \
    MIMALLOC_LARGE_OS_PAGES=1 \
    RUSTFLAGS="-C target-feature=-crt-static -C link-arg=-fuse-ld=lld" \
    CARGO_NET_GIT_FETCH_WITH_CLI=true \
    CARGO_TERM_COLOR="always"
RUN apk --no-cache add lld build-base cmake clang-dev linux-headers libevent-dev musl-dev openssl-dev

ADD fhir /app
WORKDIR /app

RUN cargo build --release

CMD ["/app/target/fhir"]
