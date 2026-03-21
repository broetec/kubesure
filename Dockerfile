FROM python:3.13-slim

# Prevent Python from writing .pyc files and force log directly to the terminal
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Copy the project files into the container
COPY . .

# Install Kubesure globally inside the container
RUN pip install --no-cache-dir .

# Define our CLI as the default entrypoint
ENTRYPOINT ["kubesure"]

# If the user runs the container without arguments, display the help
CMD ["--help"]
