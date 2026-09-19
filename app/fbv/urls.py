from django.urls import path

from .views import NoteListView, CreateNoteView, UpdateNoteView, NoteDetailView, DeleteNoteView

urlpatterns = [
    path("", NoteListView.as_view(), name="home"),
    path("create/", CreateNoteView.as_view(), name="create"),
    path("update/<str:pk>/", UpdateNoteView.as_view(), name="update"),
    path("detail/<str:pk>/", NoteDetailView.as_view(), name="detail"),
    path("delete/<str:pk>/", DeleteNoteView.as_view(), name="delete"),

]




