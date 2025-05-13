FROM python:3.10-slim

# Disable prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for Chrome and building Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget unzip curl gnupg2 \
    fonts-liberation libxss1 libappindicator3-1 libasound2 \
    libatk-bridge2.0-0 libgtk-3-0 libnss3 libx11-xcb1 \
    libxcb-dri3-0 libgbm1 libxshmfence1 libxrandr2 \
    libxcomposite1 libxcursor1 libxi6 libxtst6 libgl1-mesa-glx \
    build-essential zlib1g-dev libffi-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Add Google’s GPG key and Chrome repository
RUN curl -sSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/google.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

# Install Google Chrome stable
RUN apt-get update && apt-get install -y google-chrome-stable

# Install ChromeDriver v136 (matches Chrome v136 pre-installed on Render)
RUN wget -O /tmp/chromedriver.zip https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/136.0.7103.92/linux64/chromedriver-linux64.zip && \
    unzip /tmp/chromedriver.zip -d /tmp/chromedriver && \
    mv /tmp/chromedriver/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver && \
    chmod +x /usr/local/bin/chromedriver && \
    rm -rf /tmp/chromedriver*

# Set working directory
WORKDIR /app

# Copy application files
COPY . /app

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose port (optional for local testing)
EXPOSE 5000

# Run the app
CMD ["python", "app.py"]
