# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.3.0
FROM registry.docker.com/library/ruby:${RUBY_VERSION}-slim AS base

# Common system deps (curl, certs)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Node 20 + Yarn 1.x (needed for @hotwired/turbo@8)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y nodejs && \
    npm install -g yarn@1.22.22 && \
    rm -rf /var/lib/apt/lists/*

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development

# ---------- BUILD STAGE ----------
FROM base AS build

# Build-time packages for gems and native extensions
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      libvips \
      pkg-config \
      python-is-python3 && \
    rm -rf /var/lib/apt/lists/*

# Install Ruby gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Install node modules
COPY package.json yarn.lock ./
RUN yarn install

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ---------- FINAL RUNTIME IMAGE ----------
FROM base

# Runtime-only packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      libvips \
      postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built gems and app from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails /rails && \
    chmod +x /rails/bin/docker-entrypoint
USER rails:rails
WORKDIR /rails


# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
