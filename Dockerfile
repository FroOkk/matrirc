# --- Stage 1: The Full-Featured Builder ---
FROM rust:latest AS builder

# 1. Add the musl target for static linking
RUN rustup target add x86_64-unknown-linux-musl

# 2. Install musl-tools to get the musl-gcc wrapper
# (The full image has most tools, but musl-gcc is still needed for this target)
RUN apt-get update && apt-get install -y musl-tools libssl-dev

WORKDIR /app

# 3. Cache dependencies 
# This prevents re-downloading everything if only your source code changes
COPY . .
ENV PKG_CONFIG_ALLOW_CROSS=1
RUN cargo build --release --target x86_64-unknown-linux-musl

# --- Stage 2: The Runtime ---
# We use Alpine here instead of Scratch because it's only ~5MB 
# and provides CA certificates for HTTPS and a shell for debugging.
FROM scratch

# Copy the binary from the builder
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/matrirc /usr/local/bin/matrirc

if [ "$ALLOW_REGISTER" = "true" ]; then
  $REGISTER="--allow-register"
fi

# Run the app
CMD ["/usr/local/bin/matrirc $REGISTER"]