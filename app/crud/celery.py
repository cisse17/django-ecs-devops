import os
from celery import Celery
from celery.schedules import crontab

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'crud.settings')

app = Celery('crud')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()


# test 
# Configuration des tâches périodiques
app.conf.beat_schedule = {
    #TÂCHE DE TEST - toutes les minutes (POUR TESTER) 
     # ─ MONITORING ─
    'health-check': {
        'task': 'fbv.tasks.test_celery_beat',
        'schedule': crontab(minute='*'),  # Toutes les minutes
    },

     # ─ RÉSUMÉS UTILISATEURS ─
    'resume-quotidien': {
        'task': 'fbv.tasks.envoyer_resume_quotidien',
        'schedule': crontab(hour=8, minute=0),  # Tous les jours à 8h
    },
    
    'resume-hebdomadaire': {
        'task': 'fbv.tasks.envoyer_resume_hebdomadaire',
        'schedule': crontab(day_of_week=1, hour=9, minute=0),  # Lundi à 9h
    },
    
    # ─ MAINTENANCE ─
    'nettoyage-notes': {
        'task': 'fbv.tasks.supprimer_notes_anciennes',
        'schedule': crontab(hour=3, minute=0),  # Tous les jours à 3h
        'args': (30,),  # 30 jours
    },
    
}
