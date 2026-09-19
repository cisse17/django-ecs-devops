
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .serializers import NoteSerializers
from rest_framework import viewsets
from fbv.models import Note
from rest_framework.pagination import PageNumberPagination
from django.db.models import Q

class NotePageNumberPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = "pages_size"


class NoteViewSet(viewsets.ViewSet):
    """
    ViewSet pour gérer les opérations CRUD sur les notes.
    Seules les notes de l'utilisateur connecté sont accessibles.
    """
    serializer_class = NoteSerializers
    permission_classes = [IsAuthenticated]
    pagination_class = NotePageNumberPagination

    def list(self, request):
        """Retourne toutes les notes de l'utilisateur connecté"""
        # notes = Note.objects.filter(user=request.user)
        # serializer = self.serializer_class(notes, many=True)
        # return Response(serializer.data)
        queryset = Note.objects.filter(user=request.user)

        query = self.request.GET.get("q", "")
        if query:
            queryset = queryset.filter(Q(title__icontains=query) | Q(content__icontains=query))
        
        paginator = self.pagination_class()
        page = paginator.paginate_queryset(queryset, request)
        serializer = self.serializer_class(page, many=True)

        return paginator.get_paginated_response(serializer.data)


    def retrieve(self, request, pk=None):
        """Retourne une note spécifique par son ID"""
        try:
            note = Note.objects.get(pk=pk, user=request.user)
            serializer = self.serializer_class(note)
            return Response(serializer.data)
        except Note.DoesNotExist:
            return Response({"detail": "Note non trouvée."}, status=status.HTTP_404_NOT_FOUND)
            
    
    def create(self, request):

        """Crée une nouvelle note"""
        serializer = self.serializer_class(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def update(self, request, pk=None):
        """Met à jour complètement une note (PUT)"""
        try:
            note = Note.objects.get(pk=pk, user=request.user)
            serializer = NoteSerializers(note, data=request.data)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST) 
        except Note.DoesNotExist:
            return Response({"detail": "Note non trouvée."}, status=status.HTTP_404_NOT_FOUND)
        
    def partial_update(self, request, pk=None):
        """Met à jour partiellement une note (PATCH)"""
        try:
            note = Note.objects.get(pk=pk, user=request.user)
            serializer = NoteSerializers(note, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST) 
        except Note.DoesNotExist:
            return Response({"detail": "Note non trouvée."}, status=status.HTTP_404_NOT_FOUND)
        
    def destroy(self, request, pk=None):
        """Supprime une note"""
        try:
            note = Note.objects.get(pk=pk, user=request.user)
            note.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except Note.DoesNotExist:
            return Response({"detail": "Note non trouvée."}, status=status.HTTP_404_NOT_FOUND)



# ModelViewset 
"""class NoteModelViewSet(viewsets.ModelViewSet):
        permission_classes = [IsAuthenticated]
        serializer_class = NoteSerializers
        pagination_class = NotePagination

        def get_queryset(self):
            queryset = Note.objects.filter(user=self.request.user)
            query = self.request.GET.get("q")
            if query:
                queryset = queryset.filter(Q(title__icontains=query) | Q(content__icontains=query))
            return queryset
        
        def perform_create(self, serializer):
            serializer.save(user=self.request.user)
            
"""




