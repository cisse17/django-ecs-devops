
from fbv.models import Note
from rest_framework import serializers

class NoteSerializers(serializers.ModelSerializer):
    user = serializers.StringRelatedField(read_only=True)
    class Meta:
        model = Note
        fields = "__all__"
        read_only_fields = ["id", "created_at", "updated_at", "user"]






