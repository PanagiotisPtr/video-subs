FROM nvidia/cuda:12.5.1-base-ubuntu24.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y python3 python3-pip python3-venv ffmpeg

# Create a directory for the app
RUN mkdir -p /app

# Set the working directory
WORKDIR /app

# Copy requirements.txt
COPY requirements.txt .

# Create and activate a virtual environment
RUN python3 -m venv venv
RUN . venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt

# Copy the application code
COPY src /app/src

# Set the working directory
WORKDIR /app/src

# Command to run the application
CMD ["venv/bin/python", "main.py"]
