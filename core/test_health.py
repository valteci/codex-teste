from unittest.mock import patch

from django.db.utils import OperationalError
from django.test import TestCase
from django.urls import reverse


class TestHealthChecks(TestCase):
    def test_live_endpoint(self):
        response = self.client.get(reverse('health-live'))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {'status': 'ok'})

    def test_ready_endpoint_when_database_is_available(self):
        response = self.client.get(reverse('health-ready'))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {'status': 'ok', 'database': 'available'})

    @patch('core.views.connection.ensure_connection', side_effect=OperationalError('db down'))
    def test_ready_endpoint_when_database_is_unavailable(self, _mocked_db):
        response = self.client.get(reverse('health-ready'))
        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json(), {'status': 'error', 'database': 'unavailable'})
