# syntax=docker/dockerfile:1

# ---- Build Flutter web ----
FROM ghcr.io/cirruslabs/flutter:stable AS flutter_builder

WORKDIR /app

# Copy the Flutter project
COPY mechanica_app/ ./mechanica_app/

WORKDIR /app/mechanica_app
# Get Flutter dependencies
RUN flutter pub get

# Build the Flutter web app (release)
RUN flutter build web --release

# ---- Build FastAPI backend and serve the static Flutter web ----
FROM python:3.11-slim AS final

WORKDIR /app

# Copy the FastAPI source code
COPY mechanica_api/ ./mechanica_api/

# Copy the built Flutter web files from the previous stage
COPY --from=flutter_builder /app/mechanica_app/build/web ./mechanica_api/static

# Install Python dependencies
RUN pip install --no-cache-dir fastapi uvicorn pydantic

# Expose the port used by Uvicorn
EXPOSE 8000

# Command to run the FastAPI server
CMD ["uvicorn", "mechanica_api.main:app", "--host", "0.0.0.0", "--port", "8000"]
