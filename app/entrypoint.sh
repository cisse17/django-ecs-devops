#!/bin/sh

set -e

case "$1" in

  web)
    echo "Starting Django web server..."
    python manage.py collectstatic --noinput
    exec gunicorn --bind 0.0.0.0:8000 crud.wsgi:application
    ;;

  celery)
    echo "Starting Celery worker..."
    exec celery -A crud worker --loglevel=info
    ;;

  beat)
    echo "Starting Celery Beat..."
    exec celery -A crud beat --loglevel=info
    ;;

  *)
    exec "$@"
    ;;

esac



# Concernant l'entrypoint : le case "$1" n'exécute qu'une seule branche selon l'argument reçu 
# — il ne lance jamais web et celery en même temps dans le même conteneur. 
# Chaque task ECS (web, celery, beat) lance sa propre instance de conteneur avec son propre argument, 
# indépendamment les unes des autres. Pas de confusion possible entre rôles.