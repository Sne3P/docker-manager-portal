FROM python:3.11-alpine

# Create app directory
WORKDIR /app

# Copy Python server
COPY server.py /app/

# Make server executable  
RUN chmod +x server.py

# Expose port 8000
EXPOSE 8000

# Start custom Python server
CMD ["python", "server.py"]