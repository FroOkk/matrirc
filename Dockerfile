# --- Stage 1: The Full-Featured Builder ---
FROM rust:1.80 AS builder

# 1. Add the musl target for static linking
RUN rustup target add x86_64-unknown-linux-musl

# 2. Install musl-tools to get the musl-gcc wrapper
# (The full image has most tools, but musl-gcc is still needed for this target)
RUN apt-get update && apt-get install -y musl-tools

WORKDIR /app

# 3. Cache dependencies 
# This prevents re-downloading everything if only your source code changes
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release --target x86_64-unknown-linux-musl

# 4. Build your actual application
COPY ./src ./src
# We 'touch' the main file to ensure cargo realizes the source has changed
RUN touch src/main.rs
RUN cargo build --release --target x86_64-unknown-linux-musl

# --- Stage 2: The Runtime ---
# We use Alpine here instead of Scratch because it's only ~5MB 
# and provides CA certificates for HTTPS and a shell for debugging.
FROM alpine:latest

# Install certificates so HTTPS requests work
RUN apk --no-cache add ca-certificates

# Copy the binary from the builder
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release /usr/local/bin/app

# Run the app
CMD ["/usr/local/bin/app/matrirc"]