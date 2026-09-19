from django.core.mail import EmailMessage
from django.template.loader import render_to_string
from fbv.models import Note
from django.contrib.auth.models import User
from celery import shared_task
from django.utils import timezone


# test tache simple pr debugg celery beat
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

@shared_task
def test_celery_beat():
    """Tâche simple pour tester si Celery Beat fonctionne"""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    message = f"✅ Celery Beat fonctionne ! - {now}"
    print(message)
    logger.info(message)
    return message


@shared_task
def envoyer_email_bienvenu_html(user_id):

    user = User.objects.get(id=user_id)

    context = {
        'username': user.username,
        'unsubscribe_url': "#",
        'contact_url': '#',
        'site_url': 'https://bmc.pythonanywhere.com', # test 
    }

    subject = "Bienvenu sur notre AppNote et merci pour la creation de votre compte"
    message_html = render_to_string("fbv/emails/mail_bienvenu.html", context)
    email = EmailMessage(
        subject,
        message_html,
        'bassiroucisse1711@gmail.com',
        [user.email],
        
    )
    email.content_subtype = "html"
    email.send()
    return f"Email bienvenu envoyé à l'utilisateur {user.username}"



@shared_task
def envoyer_email_creation_note_html(user_id, note_id):
    user = User.objects.get(id=user_id)
    note = Note.objects.get(id=note_id)

    sujet = f"Creation d'une nouvelle note "
   
    word_count = len(note.content.split())
    reading_time = max(1, word_count // 200)

    context = {
        'username': user.username,
        'note_title': note.title,
        'note_content': note.content,
        'created_at': note.created_at.strftime('%d/%m/%Y à %H:%M'),
        'word_count': word_count,
        'reading_time': reading_time,
        'note_url' : '#'
    }

    message_html = render_to_string("fbv/emails/mail_creation_note.html", context)
    email = EmailMessage(
        sujet,
        message_html,
        'bassiroucisse1711@gmail.com',
        [user.email],
        

    )

    email.content_subtype = "html"
    email.send()
    return f"Email note créée envoyé à {user.email}"


# RÉSUMÉS PÉRIODIQUES
@shared_task
def envoyer_resume_quotidien():
    """Envoie un résumé quotidien des notes à tous les utilisateurs"""
    today = timezone.now().date()
    sent_count = 0
    
    for user in User.objects.all():
        notes_du_jour = Note.objects.filter(
            user=user,
            created_at__date=today
        )
        
        if notes_du_jour.exists():
            context = {
                "username": user.username,
                "notes": notes_du_jour,
                "nombre_notes": notes_du_jour.count(),
                "date": today.strftime("%d/%m/%Y"),
            }
            
            sujet = f"📝 Résumé quotidien - {today.strftime('%d/%m/%Y')}"
            message_html = render_to_string("fbv/emails/email_quotidien.html", context)
            
            email = EmailMessage(
                sujet,
                message_html,
                "bassiroucisse1711@gmail.com",
                [user.email],
            )
            email.content_subtype = "html"
            email.send()
            sent_count += 1
    
    return f" {sent_count} résumés quotidiens envoyés"


@shared_task
def envoyer_resume_hebdomadaire():
    """Envoie un résumé hebdomadaire des notes"""
    today = timezone.now().date()
    debut_semaine = today - timedelta(days=today.weekday())
    fin_semaine = debut_semaine + timedelta(days=6)
    sent_count = 0
    
    for user in User.objects.all():
        notes_semaine = Note.objects.filter(
            user=user,
            created_at__date__range=[debut_semaine, fin_semaine]
        )
        
        if notes_semaine.exists():
            context = {
                "username": user.username,
                "debut": debut_semaine.strftime("%d/%m/%Y"),
                "fin": fin_semaine.strftime("%d/%m/%Y"),
                "notes": notes_semaine,
                "nombre_notes": notes_semaine.count()
            }
            
            sujet = f" Résumé hebdomadaire - Semaine du {debut_semaine.strftime('%d/%m')}"
            message_html = render_to_string("fbv/emails/email_hebdo.html", context)
            
            email = EmailMessage(
                sujet,
                message_html,
                "bassiroucisse1711@gmail.com",
                [user.email],
            )
            email.content_subtype = "html"
            email.send()
            sent_count += 1
    
    return f"{sent_count} résumés hebdomadaires envoyés"


# MAINTENANCE

@shared_task
def supprimer_notes_anciennes(jours=30):
    """Supprime les notes non modifiées depuis X jours"""
    date_limite = timezone.now() - timedelta(days=jours)
    
    notes_a_supprimer = Note.objects.filter(
        updated_at__lt=date_limite
    )
    
    count = notes_a_supprimer.count()
    notes_a_supprimer.delete()
    
    logger.info(f"🗑️ {count} notes supprimées (plus de {jours} jours)")
    return f"🗑️ {count} notes supprimées"