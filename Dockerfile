FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    && curl -fsSL https://code-server.dev/install.sh | sh

EXPOSE 8080

CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "none"]