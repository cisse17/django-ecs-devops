from django.contrib.auth.models import User
from .models import Note


def app_stats(request):
    return {
        "nb_users": User.objects.count(),
        "nb_notes": Note.objects.filter(
            user=request.user
        ).count() if request.user.is_authenticated else 0,
    }