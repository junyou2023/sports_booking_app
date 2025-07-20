import io
from PIL import Image
import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from sports.models import Category, Activity, Sport, Slot

pytestmark = pytest.mark.django_db

def dummy_image(name='test.png'):
    buf = io.BytesIO()
    Image.new('RGB', (10, 10), 'red').save(buf, format='PNG')
    buf.seek(0)
    return SimpleUploadedFile(name, buf.read(), content_type='image/png')

def test_category_upload():
    c = Category.objects.create(name='Yoga')
    c.image.save('up.png', dummy_image(), save=True)
    assert c.image.name.startswith('category/')

def test_is_nearby_filter():
    sport = Sport.objects.create(name='Run')
    cat = Category.objects.create(name='Road')
    act1 = Activity.objects.create(sport=sport, discipline=cat, title='A', is_nearby=True)
    Activity.objects.create(sport=sport, discipline=cat, title='B', is_nearby=False)
    assert Activity.objects.filter(is_nearby=True).count() == 1
