# ---- Stage 1: Build Stage ----
    FROM alpine:latest AS builder

    # Install required dependencies
    RUN apk add --no-cache bash curl aws-cli jq
    
    # Set working directory
    WORKDIR /app
    
    # Copy script into container
    COPY fetch_metadata.sh /app/fetch_metadata.sh
    
    # Grant execution permissions
    RUN chmod +x /app/fetch_metadata.sh
    
    
    # ---- Stage 2: Runtime Stage ----
    FROM alpine:latest
    
    # Install only required dependencies
    RUN apk add --no-cache bash curl aws-cli jq
    
    # Set working directory
    WORKDIR /app
    
    # Copy the script from the builder stage
    COPY --from=builder /app/fetch_metadata.sh /app/fetch_metadata.sh
    
    # Grant execution permissions
    RUN chmod +x /app/fetch_metadata.sh
    
    # Set entrypoint to execute the script
    ENTRYPOINT ["/app/fetch_metadata.sh"]
    
