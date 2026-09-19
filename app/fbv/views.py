from django.views.generic import ListView, CreateView, UpdateView, DeleteView, DetailView
from .models import Note
from .forms import NoteForm
from django.contrib import messages
from django.urls import reverse_lazy, reverse
from django.shortcuts import redirect
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin
from django.db.models import Q
from django.contrib.auth.models import User


class NoteListView(LoginRequiredMixin, ListView):
    model = Note
    context_object_name = "notes"
    template_name = "fbv/home.html"
    success_url = reverse_lazy("home")
    paginate_by = 4

    def get_queryset(self):
        queryset = super().get_queryset().filter(user=self.request.user).order_by("-created_at")
        query = self.request.GET.get("q", "")

        if query:
            queryset = queryset.filter(Q(title__icontains=query) | Q(content__icontains=query))
        return queryset

    # le context_processors s'en occupe pr afficher sur ttes mes pages
    # def get_context_data(self, **kwargs):
    #     context = super().get_context_data(**kwargs)

    #     context["nb_users"] = User.objects.count()
    #     context["nb_notes"] = Note.objects.filter(
    #     user=self.request.user
    #     ).count()

    #     return context

class CreateNoteView(LoginRequiredMixin, CreateView):
    model = Note
    form_class = NoteForm
    template_name = "fbv/create_task.html"
    success_url = reverse_lazy("home")

    def form_valid(self, form):
        if self.request.user.is_authenticated:
            form.instance.user = self.request.user
            messages.success(self.request, f"Note {form.instance.title} a été crééé avec succés")
        return super().form_valid(form)

    def form_invalid(self, form):
        messages.error(self.request, "erreur lors de la creation de la note")
        return super().form_invalid()

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["button_text"] = "creer"
        return context

class UpdateNoteView(LoginRequiredMixin, UserPassesTestMixin, UpdateView):
    model =  Note
    form_class = NoteForm
    template_name = "fbv/update_task.html"

    def get_success_url(self, *args, **kwargs):
        return reverse("detail", kwargs={"pk": self.object.pk}) 

    def form_valid(self, form):
        form.instance.user = self.request.user
        messages.success(self.request, f"{form.instance.title} modifié avec succés")
        return super().form_valid(form)

    def form_invalid(self, form):
        messages.error(self.request, "erreur lors de la modification du formulaire")
        return super().form_invalid(form)

    def test_func(self):
        note = self.get_object()
        return note.user == self.request.user
    
    def handle_no_permission(self):
        messages.error(self.request, "Vous n'avez pas le droit de modifier cette note")
        return redirect("home")
    
class DeleteNoteView(LoginRequiredMixin, UserPassesTestMixin, DeleteView):
    model = Note
    template_name = "fbv/delete_task.html"
    success_url = reverse_lazy("home")


    def test_func(self):
        note = self.get_object()
        return note.user == self.request.user

    def handle_no_permission(self):
        messages.error(self.request, "Vous n'avez pas le droit de supprimer cette note")
        return redirect("home")
    
    def post(self, request, *args, **kwargs):
        self.object = self.get_object()
        messages.success(self.request, f"{self.object.title} supprimé avec succés")
        return super().post(request, *args, **kwargs)

class NoteDetailView(LoginRequiredMixin, UserPassesTestMixin, DetailView):
    model = Note
    context_object_name = "detail"
    template_name = "fbv/detail.html"

    def test_func(self):
        note = self.get_object()
        return note.user == self.request.user
    
    def handle_no_permission(self):
        messages.error(self.request, "Vous ne pouvez pas acceder à cette note")
        return redirect("home")