# Stage 1: Build the static Go binary
FROM golang:alpine AS builder

WORKDIR /app

# Copy go.mod and go.sum to cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the kafka_exporter binary statically
# CGO_ENABLED=0 disables cgo, forcing Go to build a completely static binary
# -a ensures all packages are rebuilt, not just incremental changes
# -ldflags="-s -w" reduces binary size by removing debug info and symbol table
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix nocgo -ldflags="-s -w" -o /bin/kafka_exporter

# Stage 2: Create the final lean image
FROM alpine/curl

# Copy the static binary from the builder stage
COPY --from=builder /bin/kafka_exporter /bin/kafka_exporter

EXPOSE 9308
ENTRYPOINT [ "/bin/kafka_exporter" ]