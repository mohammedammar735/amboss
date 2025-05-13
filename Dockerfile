# Start with a Python base image that includes build tools
FROM python:3.9-slim

# Install Google Chrome and other dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    unzip \
    # Add Chrome's apt key
    && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    # Add Chrome to sources list
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' \
    # Install Chrome
    && apt-get update && apt-get install -y google-chrome-stable \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Install ChromeDriver (adjust version as needed to match Chrome version)
# Check Chrome version with: google-chrome --version (e.g., Chrome 124)
# Find matching ChromeDriver: https://googlechromelabs.github.io/chrome-for-testing/
ARG CHROMEDRIVER_VERSION="124.0.6367.201" # Example: Match this to your Chrome version
RUN wget -O /tmp/chromedriver.zip https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/${CHROMEDRIVER_VERSION}/linux64/chromedriver-linux64.zip \
    && unzip /tmp/chromedriver.zip -d /usr/local/bin/ \
    # The zip might contain a directory like chromedriver-linux64, so move the executable
    && mv /usr/local/bin/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver \
    && rm /tmp/chromedriver.zip \
    && chmod +x /usr/local/bin/chromedriver

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Port Render expects
ENV PORT 8080
# Command to run your application
CMD ["gunicorn", "--bind", "0.0.0.0:$PORT", "app:app"]
