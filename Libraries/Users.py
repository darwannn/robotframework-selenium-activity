import requests
import random

from datetime import datetime, timedelta
import secrets


class Users:
    def api_get_users(self):
        response = requests.get(
            "http://jsonplaceholder.typicode.com/users", verify=False
        )

        users = response.json()
        for user in users:
            random_days = random.randint(0, 355 * 50)
            random_date = datetime(1970, 1, 1) + timedelta(days=random_days)
            user["birthday"] = random_date.strftime("%m%d%Y")
            user["address"]["state"] = self.get_random_word()
        return users

    def get_random_word(self):
        response = requests.get(
            "https://random-word-api.herokuapp.com/word", verify=False
        )
        return response.json()[0].title()

    def generate_user_password(self):
        return secrets.token_urlsafe(32)