
from django.urls import path
from .views import LoginNoteView, LogoutNoteView, RegisterView

urlpatterns = [
    path("inscription/", RegisterView.as_view(), name="inscription"),
    path("connexion/", LoginNoteView.as_view(), name="connexion"),
    path("deconnexion/", LogoutNoteView.as_view(), name="deconnexion"),

]