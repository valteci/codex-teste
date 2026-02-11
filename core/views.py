from django.db import connection
from django.db.utils import OperationalError
from django.http import JsonResponse


def health_live(request):
    return JsonResponse({'status': 'ok'})


def health_ready(request):
    try:
        connection.ensure_connection()
    except OperationalError:
        return JsonResponse({'status': 'error', 'database': 'unavailable'}, status=503)

    return JsonResponse({'status': 'ok', 'database': 'available'})
