from django.db import models
from django.contrib.auth.models import User
from django.utils.text import slugify

class Note(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    # slug = models.SlugField(blank=True)
    title = models.CharField(max_length=255)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add = True, null=True)
    updated_at = models.DateTimeField(auto_now=True, null=True, blank=True)


    class Meta:
        ordering= ["-created_at"]

    def __str__(self):
        return self.title
    
    # def save(self, *args, **kwargs):
    #     if not self.slug:
    #         self.slug = slugify(self.title)
    #     super().save(*args, **kwargs)









# Create your models here.

# class Task(models.Model):
#     title = models.CharField(max_length=200)
#     completed = models.BooleanField(default=False)
#     created_at = models.DateTimeField(auto_now_add=True, null=True, blank=True)