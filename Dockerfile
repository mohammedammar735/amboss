FROM python:3.10-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget unzip curl gnupg2 ca-certificates \
    fonts-liberation libxss1 libappindicator3-1 libasound2 \
    libatk-bridge2.0-0 libgtk-3-0 libnss3 libx11-xcb1 \
    libxcb-dri3-0 libgbm1 libxshmfence1 libxrandr2 \
    libxcomposite1 libxcursor1 libxi6 libxtst6 libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome for Testing v136
RUN wget -O /tmp/chrome-linux.zip https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/136.0.7103.92/linux64/chrome-linux.zip && \
    unzip /tmp/chrome-linux.zip -d /opt && \
    ln -s /opt/chrome-linux/chrome /usr/bin/google-chrome && \
    chmod +x /usr/bin/google-chrome

# Install ChromeDriver v136
RUN wget -O /tmp/chromedriver.zip https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/136.0.7103.92/linux64/chromedriver-linux64.zip && \
    unzip /tmp/chromedriver.zip -d /tmp/chromedriver && \
    mv /tmp/chromedriver/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver && \
    chmod +x /usr/local/bin/chromedriver && \
    rm -rf /tmp/chromedriver*

# Set work directory
WORKDIR /app

# Copy code
COPY . /app

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose Flask port (optional)
EXPOSE 5000

# Start Flask app
CMD ["python", "app.py"]
