# **Comprehensive Report: Django and Docker Setup for `simple_wsi_viewer` Project**

This report provides a detailed account of the issues encountered and the solutions applied to set up and run the `simple_wsi_viewer` project on Docker, specifically focusing on resolving database errors and applying migrations in Django.

https://github.com/daangeijs/simple_wsi_viewer

---

### **1. Initial Setup: Running `simple_wsi_viewer` in Docker**

After configuring Docker Desktop on macOS, the `docker-compose.yml` file was set up to build and run the `wsi_viewer` application.

```yaml
services:
  web:
    # image: wsi_viewer:latest
    build: .  # Build the image locally from the Dockerfile
    command: python manage.py runserver 0.0.0.0:8000
    ...

  celery:
    # image: wsi_viewer:latest
    build: .  # Build the image locally from the Dockerfile
    command: celery -A wsi_viewer worker -l info
```

Key command to start the Docker containers:
```bash
docker-compose up
```

During this process, several errors were encountered, mainly related to missing tables in the database due to unapplied Django migrations.

---

### **2. Error: SQLite Version Mismatch**

#### **Error Message:**
```
django.db.utils.NotSupportedError: SQLite 3.31 or later is required (found 3.27.2)
```

#### **Solution:**
To resolve this, the Dockerfile was updated to ensure the correct version of SQLite was installed (3.31 or later). This was done by downloading and building the latest version of SQLite.

#### **Updated Dockerfile:**
```dockerfile
# Download, build, and install SQLite 3.41.2
WORKDIR /tmp
RUN wget https://www.sqlite.org/2023/sqlite-autoconf-3410200.tar.gz \
    && tar xvfz sqlite-autoconf-3410200.tar.gz \
    && cd sqlite-autoconf-3410200 \
    && ./configure --prefix=/usr/local \
    && make \
    && make install \
    && rm -rf /tmp/sqlite-autoconf-3410200*

# Ensure the newly installed SQLite version is used
ENV PATH="/usr/local/bin:$PATH"
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
```

#### **Commands to Rebuild and Run the Docker Containers:**
```bash
docker-compose build
docker-compose up
```

#### **Check SQLite Version Inside the Container:**
```bash
docker exec -it <web-container-name> sqlite3 --version
```

This ensured that the correct SQLite version was installed and being used by Django.

---

### **3. Error: Missing Tables in Database**

Several errors were encountered related to missing tables, such as `viewer_indexingstatus` and `viewer_image`. These errors occurred because the Django database migrations had not been applied to create the necessary tables.

#### **Example Error Message:**
```
OperationalError: no such table: viewer_indexingstatus
```

### **4. Solution: Apply Django Migrations**

To resolve these issues, Django migrations were applied to create the missing tables in the SQLite database.

#### **Command to Apply Migrations:**
```bash
docker-compose run web python manage.py migrate
```

This command runs any unapplied migrations, ensuring that all necessary tables, including `viewer_indexingstatus` and `viewer_image`, are created.

#### **Check for Unapplied Migrations:**
```bash
docker-compose run web python manage.py showmigrations
```

This command lists all migrations and shows whether they have been applied. If any migrations were pending, they were applied by running the `migrate` command.

---

### **5. Error: Adding Images to Database**

When trying to add images to the database, the following error occurred due to the missing `viewer_image` table:

#### **Error Message:**
```
OperationalError: no such table: viewer_image
```

#### **Solution:**
After applying the migrations, the table was created, and the command to add images to the database was successful.

#### **Command to Add Images** (using the path `/Users/tkshfj/Dropbox/repository/simple_wsi_viewer/slides`):
```bash
docker-compose run web python manage.py add_images /Users/tkshfj/Dropbox/repository/simple_wsi_viewer/slides
```

This command adds images to the `viewer_image` table from the specified directory.

---

### **6. Final Outcome**

After applying the necessary migrations, upgrading SQLite, and rebuilding the Docker containers, the `simple_wsi_viewer` application was successfully set up and running without issues.

Key steps included:
- Ensuring the correct SQLite version was installed.
- Running Django migrations to create missing tables.
- Adding images to the database once the migrations were applied.

---

### **Key Commands Summary**

- **Start Docker Containers:**
```bash
docker-compose up
```

- **Rebuild Docker Containers After Dockerfile Changes:**
```bash
docker-compose build
```

- **Check SQLite Version:**
```bash
docker exec -it <web-container-name> sqlite3 --version
```

- **Apply Django Migrations:**
```bash
docker-compose run web python manage.py migrate
```

- **Check Unapplied Migrations:**
```bash
docker-compose run web python manage.py showmigrations
```

- **Add Images to the Database** (using the path `/Users/tkshfj/Dropbox/repository/simple_wsi_viewer/slides`):
```bash
docker-compose run web python manage.py add_images /Users/tkshfj/Dropbox/repository/simple_wsi_viewer/slides
```

```sh
docker-compose build
docker-compose up
docker-compose run web python manage.py makemigrations
docker-compose run web python manage.py showmigrations
docker-compose run web python manage.py makemigrations viewer
docker-compose run web python manage.py migrate
docker-compose run web python manage.py add_images /Users/tkshfj/Dropbox/repository/simple_wsi_viewer/slides
```

---

### **Conclusion**

This comprehensive report outlines the process of setting up and running the `simple_wsi_viewer` application in Docker, with specific focus on resolving SQLite version mismatches and applying Django migrations. After these steps were completed, the application was running smoothly, with all necessary database tables created and functional.
