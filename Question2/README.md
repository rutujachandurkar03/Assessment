# EC2 Metadata Fetcher (Dockerized)

## Overview
This project containerizes the EC2 metadata fetcher script using **Alpine Linux** as the base image. The script fetches EC2 metadata either from **AWS EC2** (IMDSv1/IMDSv2) or **LocalStack** (for local testing).

## Features
- Uses a lightweight **Alpine Linux** base image
- Supports fetching metadata from **real AWS EC2 instances** or **LocalStack**
- Works with **IMDSv1** and **IMDSv2**
- Multistage Docker build for optimization

---

## **Prerequisites**

- **Docker Desktop** installed
- **LocalStack** installed and running for local testing
- **AWS CLI** configured (for real AWS usage)
- **Git** installed
- **VS Code** (recommended for development)

---

## **Dockerfile Explanation**

The **Dockerfile** uses a **multi-stage build** approach:

1. **Base Stage**: Uses Alpine Linux and installs required dependencies.
2. **Final Stage**: Copies the script and executes it inside the container.

### **Dockerfile**
```dockerfile
# Stage 1: Base Image
FROM alpine:latest AS base
RUN apk add --no-cache bash curl aws-cli

# Stage 2: Final Image
FROM base
WORKDIR /app
COPY fetch_metadata.sh /app/
RUN chmod +x fetch_metadata.sh
ENTRYPOINT ["/app/fetch_metadata.sh"]
```

---

## **How to Build and Run the Docker Image**

### **Step 1: Clone the Repository**
```sh
git clone https://github.com/your-username/ec2-metadata-fetcher.git
cd ec2-metadata-fetcher
```

### **Step 2: Build the Docker Image**
```sh
docker build -t ec2-metadata-fetcher .
```

### **Step 3: Run the Docker Container**

#### **Running in LocalStack (Recommended for Local Testing)**
```sh
docker run --rm \
  --network="host" \
  -e AWS_DEFAULT_REGION=us-east-1 \
  -e AWS_ACCESS_KEY_ID=test \
  -e AWS_SECRET_ACCESS_KEY=test \
  -e AWS_ENDPOINT_URL=http://localhost:4566 \
  ec2-metadata-fetcher --imds-version v1
```

#### **Running in Real AWS EC2 Instance**
```sh
docker run --rm ec2-metadata-fetcher --imds-version v2
```

> **Note:** Ensure the instance has proper IAM role permissions to access metadata.

---

## **Pushing to Docker Hub**

### **Step 1: Login to Docker Hub**
```sh
docker login
```

### **Step 2: Tag the Image**
```sh
docker tag ec2-metadata-fetcher your-dockerhub-username/ec2-metadata-fetcher:latest
```

### **Step 3: Push the Image**
```sh
docker push your-dockerhub-username/ec2-metadata-fetcher:latest
```

---

## **Verifying LocalStack is Running**

Before running the container, make sure **LocalStack** is running and EC2 service is enabled:
```sh
curl -s http://localhost:4566/_localstack/health
```
Expected output:
```json
{"services": {"ec2": "running"}}
```
If EC2 is not running, restart LocalStack:
```sh
docker-compose up -d
```

---

## **Troubleshooting**

### **1. Error: "Unable to locate credentials"**
Solution:
- Run:
```sh
docker run --rm -e AWS_ACCESS_KEY_ID=test -e AWS_SECRET_ACCESS_KEY=test ec2-metadata-fetcher --imds-version v1
```

### **2. Error: "Could not connect to endpoint URL: http://localhost:4566/"**
Solution:
- Ensure **LocalStack** is running:
```sh
curl -s http://localhost:4566/_localstack/health
```
- Restart LocalStack:
```sh
docker-compose down && docker-compose up -d
```

---

## **Conclusion**
This project demonstrates how to containerize a script that fetches EC2 metadata using **AWS IMDSv1 and IMDSv2**. It can be run in real AWS EC2 instances or tested locally using **LocalStack**. The multi-stage **Dockerfile** ensures a minimal and optimized container image.

---

## **License**
MIT License. Feel free to use and modify this project.

---

> **Author:** Your Name | GitHub: [your-username](https://github.com/your-username)

