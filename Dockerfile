# Use Ubuntu 24.04 as base
FROM ubuntu:24.04

# Set environment variables (non-sensitive)
ENV DEBIAN_FRONTEND=noninteractive
ENV CODE_SERVER_PORT=8443

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    git \
    ca-certificates \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install code-server
RUN echo "**** install code-server ****" && \
  if [ -z ${CODE_RELEASE+x} ]; then \
    CODE_RELEASE=$(curl -sX GET https://api.github.com/repos/coder/code-server/releases/latest \
      | awk '/tag_name/{print $4;exit}' FS='[""]' | sed 's|^v||'); \
  fi && \
  mkdir -p /app/code-server && \
  curl -o /tmp/code-server.tar.gz -L \
    "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-linux-amd64.tar.gz" && \
  tar xf /tmp/code-server.tar.gz -C /app/code-server --strip-components=1 && \
  rm /tmp/code-server.tar.gz && \
  ln -s /app/code-server/bin/code-server /usr/local/bin/code-server

# Create non-root user mysticgiggle
RUN useradd -m -s /bin/bash mysticgiggle && \
    usermod -aG sudo mysticgiggle && \
    echo "mysticgiggle ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/mysticgiggle/project && \
    chown -R mysticgiggle:mysticgiggle /home/mysticgiggle

# Copy project files from host into container
COPY . /home/mysticgiggle/project
RUN chown -R mysticgiggle:mysticgiggle /home/mysticgiggle/project

# Switch to non-root user
USER mysticgiggle
WORKDIR /home/mysticgiggle/project

# Expose port 8443
EXPOSE 8443

# Default command (secure password via env)
CMD ["bash", "-c", "code-server --bind-addr 0.0.0.0:8443 --auth password"]
