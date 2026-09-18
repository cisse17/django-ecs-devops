from django.test import TestCase
from django.contrib.auth import get_user_model
from fbv.models import Note
from django.urls import reverse

User = get_user_model()

from fbv.forms import NoteForm

# Create your tests here.

class TestNoteForm(TestCase):

    def test_form_valide(self):

        form_data = {
            "title": "Ma premiere note du formulaire",
            "content": "Ceci est le contenu de ma premiere note"
        }

        form = NoteForm(data=form_data)
        self.assertTrue(form.is_valid())

    def test_form_invalide(self):

        form_data = {
            "title": "",
            "content": "contenu sans titre, tester form invalide"
        }

        form = NoteForm(data=form_data)
        self.assertFalse(form.is_valid())
        # self.assertIn("title", form.errors)

    
class TestUserAccount(TestCase):

    def test_creer_un_utilisateur(self):
        user = User.objects.create_user(
            username="Bassirou",
            password="monpass123"
        )

        self.assertEqual(user.username, "Bassirou")
        self.assertEqual(user.is_active, True)
        self.assertEqual(user.is_superuser, False)
    
    def test_creer_un_super_utilisateur(self):
        admin = User.objects.create_superuser(
            username="admin",
            password="admin123"
        )
        self.assertTrue(admin.is_superuser)
        self.assertTrue(admin.is_staff)


class TestNoteModel(TestCase):

    def setUp(self):
        self.user = User.objects.create_user(
            username="testuser",
            password="testpass123"
        )
    
    def test_creer_une_note(self):
        note = Note.objects.create(
            user=self.user,
            title="Ma note",
            content="Mon contenu"
        )


        self.assertEqual(note.title, "Ma note")
        self.assertEqual(note.user, self.user)
    
    def test_modifier_une_note(self):
        note = Note.objects.create(
            user=self.user,
            title="Titre original",
            content="Contenu original"
        )

        note.title = "Titre modifié"
        note.save()
        note_modifiee = Note.objects.get(id=note.id)
        self.assertEqual(note_modifiee.title, "Titre modifié")

    def test_supprimer_une_note(self):
        note = Note.objects.create(
            user=self.user,
            title="Note à supprimer",
            content="contenu"
        )
        note.delete()
        note_count = Note.objects.count()
        self.assertEqual(note_count, 0)
    
    def test_une_note_appartient_a_un_utilisateur(self):
        note = Note.objects.create(
            user = self.user,
            title = "Note appartenant à user",
            content=" contenu appartenant à user"
        )

        self.assertEqual(note.user.username, self.user.username)


class TestNoteRelationModel(TestCase):
    def test_supprimer_un_utilisateur_supprime_ses_notes(self):
        user = User.objects.create_user(
            username="user1",
            password="pass123"
        )

        Note.objects.create(user=user, title="Note 1", content="contenu1")
        Note.objects.create(user=user, title="Note 2", content="contenu2")
        Note.objects.create(user=user, title="Note 3", content="contenu3")

        self.assertEqual(Note.objects.count(), 3)

        user.delete()

        self.assertEqual(Note.objects.count(), 0)


# Test Fonctionnelles (Tests des vues)
class TestNoteView(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="user1", password="pass")
        self.client.login(username="user1", password="pass")
        self.note = Note.objects.create(user=self.user, title="Note initiale", content="contenu initial")
    
    def test_afficher_liste_notes(self):
        response = self.client.get(reverse("home"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Note initiale")
        # self.assertContains(response, self.note.title)
    
    def test_creer_une_note_via_vue(self):
        response = self.client.post(reverse("create"), {
            "title": "Nouvelle note",
            "content": "Texte de test"
        })
        self.assertEqual(response.status_code, 302)
        self.assertTrue(Note.objects.filter(title="Nouvelle note").exists())
        self.assertEqual(Note.objects.count(), 2)

    def test_modifier_une_note_via_vue(self):
        response = self.client.post(reverse("update", args=[self.note.id]), {
            "title": "Titre modifié",
            "content": "Contenu modifié"
        })
        self.assertEqual(response.status_code, 302)
        self.note.refresh_from_db()
        self.assertEqual(self.note.title, "Titre modifié")

    
    def test_supprimer_une_note_via_vue(self):
        # creation d'une note à supprimer optionnlle je pouvais utiliser self.note de setUp
        self.note = Note.objects.create(user=self.user, title="titre a supprimer", content="contenu à supprimer")
        response = self.client.post(reverse("delete", args=[self.note.id]))
        self.assertEqual(response.status_code, 302)
        self.assertFalse(Note.objects.filter(title="titre a supprimer").exists())
        self.assertEqual(Note.objects.count(), 1)  

    def test_utilisateur_non_connecte_redirige(self):
        self.client.logout()
        response = self.client.get(reverse("home"))
        self.assertEqual(response.status_code, 302)  
        self.assertIn('/accounts/connexion/', response.url)
