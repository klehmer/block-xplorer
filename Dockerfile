# Use the official Python image from Docker Hub
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements.txt file into the container
COPY requirements.txt .

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire Flask app into the container
COPY . .

# Expose the port the app runs on
EXPOSE 5001

# Command to run the app
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:5001", "app:app"]
