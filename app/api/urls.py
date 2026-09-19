from rest_framework.routers import DefaultRouter
from .views import NoteViewSet
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

router = DefaultRouter()

router.register("notes", NoteViewSet, basename="note")

urlpatterns = [
    path("", include(router.urls)),
    path("token/", TokenObtainPairView.as_view(), name="token" ),
    path("token/refresh", TokenRefreshView.as_view(), name="refreshtoken" ),

    path("schema/", SpectacularAPIView.as_view(), name="schema" ),
    path("docs/", SpectacularSwaggerView.as_view(), name="docs" ),

]