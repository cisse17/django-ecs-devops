FROM python:3.11-slim

WORKDIR /app

# j'installe curl pr le test dans mon conteneur health check
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Installation des dépendances Python
COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copie du projet
COPY . .

# Entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]

CMD ["web"]





# FROM python:3.11-slim

# WORKDIR /app

# ENV PYTHONDONTWRITEBYTECODE=1
# ENV PYTHONUNBUFFERED=1

# COPY requirements.txt . 

# RUN pip install --upgrade pip && \
#     pip install --no-cache-dir -r requirements.txt


# COPY . .

# # # collectstatic au BUILD
# # RUN python manage.py collectstatic --noinput 

# EXPOSE 8000

# # CMD ["sh", "-c", "python manage.py migrate && gunicorn --bind 0.0.0.0:8000 crud.wsgi:application"]
