# Base image: Ruby with necessary dependencies for Jekyll
FROM ruby:3.2

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# Keep gems outside /usr/src/app: docker-compose bind-mounts the repo over that
# path at runtime, which would otherwise hide everything installed here. Pinning
# BUNDLE_APP_CONFIG likewise stops the repo's own .bundle/config (which points at
# vendor/bundle on the host) from being picked up inside the container.
ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_APP_CONFIG=/usr/local/bundle \
    PATH=/usr/local/bundle/bin:$PATH

# Create a non-root user with UID 1000
RUN groupadd -g 1000 vscode && \
    useradd -m -u 1000 -g vscode vscode && \
    mkdir -p /usr/src/app /usr/local/bundle && \
    chown -R vscode:vscode /usr/src/app /usr/local/bundle

# Set the working directory
WORKDIR /usr/src/app

# Switch to the non-root user
USER vscode

# Copy Gemfile into the container (necessary for `bundle install`). Gemfile.lock
# is gitignored, so the glob keeps this working whether or not it exists.
COPY --chown=vscode:vscode Gemfile Gemfile.lock* ./

# Install bundler and dependencies
RUN gem install bundler:2.4.19 && bundle install

# Command to serve the Jekyll site. _config.dev.yml layers local-only overrides
# on top of _config.yml; see that file for why it is needed.
CMD ["bundle", "exec", "jekyll", "serve", "--config", "_config.yml,_config.dev.yml", "-H", "0.0.0.0", "-w", "--livereload"]
