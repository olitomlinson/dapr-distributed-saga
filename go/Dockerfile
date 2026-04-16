# Build stage
FROM golang:1.26 AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum* ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o primes-app .

# Runtime stage
FROM gcr.io/distroless/static-debian12

WORKDIR /

# Copy the binary from builder
COPY --from=builder /app/primes-app .

EXPOSE 8080

CMD ["./primes-app"]
