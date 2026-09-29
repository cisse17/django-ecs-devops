from django.views.generic import CreateView
from django.contrib.auth.views import LoginView, LogoutView
from .forms import RegisterForm
from django.urls import reverse, reverse_lazy
from django.contrib.auth.models import User
from django.contrib import messages
from django.http import HttpResponseRedirect
from django.shortcuts import redirect
from django.contrib.auth import login
from fbv.tasks import envoyer_email_bienvenu_html


class RegisterView(CreateView):
    model = User
    form_class = RegisterForm
    template_name = "accounts/register.html"
    success_url = reverse_lazy("home")

    def form_valid(self, form):
        # user = form.save()
       
        response = super().form_valid(form)  
        login(self.request, self.object) 
        # commenter temporairement pr tester aws vu que elasticache (redis) n'est pas encore configuré. à decommenter pr tester en local
        # envoyer_email_bienvenu_html.delay(self.object.id)
        messages.success(self.request, f'"Bienvenue {form.cleaned_data.get("username")} votre compte a été créé avec succès."')
        return response
    
    def form_invalid(self, form):
        messages.error(self.request, "Erreur lors de l'inscription. Veuillez vérifier les informations.")
        return super().form_invalid(form)
    

class LoginNoteView(LoginView):
    template_name = "accounts/login.html"
    # success_url = reverse_lazy("home")

    def get_success_url(self):
        return reverse("home")

    def form_valid(self, form):
        user = form.cleaned_data.get('username')
        messages.success(self.request, f" Bon retour {user} !")
        return super().form_valid(form)
    
    def form_invalid(self, form):
        messages.error(self.request, "Identifiants incorrects.")
        return super().form_invalid(form)
    

class LogoutNoteView(LogoutView):
    next_page = reverse_lazy("connexion")

    def dispatch(self, request, *args, **kwargs):
        messages.success(self.request, "Vous avez été déconnecté avec succés")
        return super().dispatch(request, *args, **kwargs)
    