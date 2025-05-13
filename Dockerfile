# Dockerfile

# Start with a Python base image that includes build tools
FROM python:3.9-slim

# Install essential tools including curl and jq for JSON parsing
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    unzip \
    curl \
    jq \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome Stable
# This will install the latest stable version available in the repository at build time
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' \
    && apt-get update && apt-get install -y google-chrome-stable --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Determine installed Chrome version and download the matching ChromeDriver
RUN CHROME_VERSION_FULL=$(google-chrome --version | awk '{print $3}') && \
    echo "Installed Chrome version: $CHROME_VERSION_FULL" && \
    # Try to get the ChromeDriver URL for the exact installed Chrome version from the CfT 'latest-patch-versions-per-build.json'
    # This JSON provides a mapping from Chrome build versions to their assets, including ChromeDriver.
    CHROMEDRIVER_URL=$(curl -sS https://googlechromelabs.github.io/chrome-for-testing/latest-patch-versions-per-build.json | \
                       jq -r --arg ver "$CHROME_VERSION_FULL" '.builds[$ver].downloads.chromedriver[] | select(.platform=="linux64") | .url' | head -n 1) && \
    \
    # Fallback 1: If exact full version string is not a key, try matching by major.minor.build prefix
    if [ -z "$CHROMEDRIVER_URL" ]; then \
        echo "No exact ChromeDriver match for Chrome $CHROME_VERSION_FULL in latest-patch-versions-per-build.json. Trying by build prefix..."; \
        CHROME_BUILD_PREFIX=$(echo "$CHROME_VERSION_FULL" | cut -d. -f1-3); \
        # Iterate through builds, find one that starts with our prefix, take the last one (presumably latest patch for that build)
        CHROMEDRIVER_URL=$(curl -sS https://googlechromelabs.github.io/chrome-for-testing/latest-patch-versions-per-build.json | \
                           jq -r --arg prefix "$CHROME_BUILD_PREFIX" '.builds | to_entries[] | select(.key | startswith($prefix)) | .value.downloads.chromedriver[] | select(.platform=="linux64") | .url' | tail -n 1); \
    fi && \
    \
    # Fallback 2: If still not found, try the 'known-good-versions-with-downloads.json' using the MAJOR Chrome version
    # This endpoint lists broader "known good" versions.
    if [ -z "$CHROMEDRIVER_URL" ]; then \
        echo "Still no match. Trying latest known good for MAJOR version from known-good-versions-with-downloads.json..."; \
        CHROME_MAJOR_VERSION=$(echo "$CHROME_VERSION_FULL" | cut -d. -f1); \
        CHROMEDRIVER_URL=$(curl -sS https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json | \
                           jq -r --argjson major_ver_num "$CHROME_MAJOR_VERSION" 'last(.versions[] | select(.version | startswith($major_ver_num + ".")) | .downloads.chromedriver[] | select(.platform=="linux64") | .url)'); \
    fi && \
    \
    # If a URL was found, download and install ChromeDriver
    if [ -n "$CHROMEDRIVER_URL" ]; then \
        echo "Using ChromeDriver Download URL: $CHROMEDRIVER_URL"; \
        wget --quiet -O /tmp/chromedriver.zip "$CHROMEDRIVER_URL"; \
        unzip -q /tmp/chromedriver.zip -d /tmp/; \
        # The zip from Chrome for Testing usually extracts to a folder like 'chromedriver-linux64'
        if [ -f /tmp/chromedriver-linux64/chromedriver ]; then \
            mv /tmp/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver; \
        else \
            # Fallback if the structure is different (e.g., older zips might extract directly)
            mv /tmp/chromedriver /usr/local/bin/chromedriver; \
        fi; \
        rm -rf /tmp/chromedriver.zip /tmp/chromedriver-linux64 /tmp/chromedriver; \
        chmod +x /usr/local/bin/chromedriver; \
    else \
        echo "ERROR: Could not automatically determine a matching ChromeDriver URL for Chrome $CHROME_VERSION_FULL." >&2; \
        echo "Please check https://googlechromelabs.github.io/chrome-for-testing/ and update Dockerfile if necessary." >&2; \
        exit 1; \
    fi

# Verify versions (optional, for debugging the build process)
RUN echo "--- Verification ---" && \
    echo "Installed Chrome version: $(google-chrome --version)" && \
    echo "Installed ChromeDriver version: $(chromedriver --version)" && \
    echo "--------------------"

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Port Render will use
ENV PORT 8080

# Command to run your application (using shell form for $PORT expansion)
CMD gunicorn --bind 0.0.0.0:$PORT app:app
