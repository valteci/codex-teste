from django.test import TestCase
from django.urls import reverse


class TestHelloWorldPage(TestCase):
    def test_hello_world_page(self):
        response = self.client.get(reverse('hello-world'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Hello, world!')
