# Use an official Python runtime as the base image
FROM python:3.10-slim-buster

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1


# Install VIPS dependencies, libvips, and OpenSlide dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libvips42 \
    wget \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libcairo2-dev \
    libgdk-pixbuf2.0-dev \
    libglib2.0-dev \
    libxml2-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libopenjp2-7-dev \
    libsqlite3-dev \
    && apt-get clean


# Download and build SQLite 3.41.2
WORKDIR /tmp
RUN wget https://www.sqlite.org/2023/sqlite-autoconf-3410200.tar.gz \
    && tar xvfz sqlite-autoconf-3410200.tar.gz \
    && cd sqlite-autoconf-3410200 \
    && ./configure --prefix=/usr/local \
    && make \
    && make install \
    && rm -rf /tmp/sqlite-autoconf-3410200*


# Ensure the newly installed SQLite version is used by setting PATH and LD_LIBRARY_PATH
ENV PATH="/usr/local/bin:$PATH"
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"


# Download, build, and install OpenSlide
WORKDIR /tmp
RUN wget https://github.com/openslide/openslide/releases/download/v3.4.1/openslide-3.4.1.tar.gz \
    && tar -xzf openslide-3.4.1.tar.gz \
    && cd openslide-3.4.1 \
    && ./configure \
    && make \
    && make install \
    && ldconfig \
    && rm -rf /tmp/openslide-3.4.1*


# Set the working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Copy the project code into the container
COPY . .
# Set the environment variable for Django
ENV DJANGO_SETTINGS_MODULE=wsi_viewer.settings

# Expose the port the app runs on
EXPOSE 8000

#CMD ["gunicorn", "wsu_viewer.wsgi:application", "--bind", "0.0.0.0:8000"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]