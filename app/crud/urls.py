
from django.contrib import admin
from django.urls import path, include
from django.http import HttpResponse

from django.views.generic import RedirectView 

def health_check(request):
    return HttpResponse("ok", status=200)


urlpatterns = [
    path('admin/', admin.site.urls),
    path('health/', health_check, name="health")
    # redirect racine vers home
    path('', RedirectView.as_view(url='/home/', permanent=False)),

    path('home/', include("fbv.urls")), 
    path("accounts/", include("accounts.urls")),
    path("api/", include("api.urls")),
]
