FROM elixir:1.16-alpine

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get --only prod

# Copy application code
COPY lib ./lib

# Compile application
RUN MIX_ENV=prod mix compile

# Expose port
EXPOSE 4000

# Start server
CMD ["mix", "run", "--no-halt"]
