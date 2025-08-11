"""
WSGI config for PlayNexus project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.2/howto/deployment/wsgi/
"""

import os
import sys

# Ensure pysqlite3 is available when using SQLite + SpatiaLite
try:  # pragma: no cover
    import pysqlite3 as sqlite3  # type: ignore
    sys.modules["sqlite3"] = sqlite3
except Exception:  # pragma: no cover
    pass

from django.core.wsgi import get_wsgi_application
from whitenoise import WhiteNoise

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'PlayNexus.settings')

application = get_wsgi_application()
application = WhiteNoise(application)
