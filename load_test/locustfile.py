from locust import HttpUser, task, between


class N11SearchUser(HttpUser):
    wait_time = between(1, 3)
    host = "https://www.n11.com"
    
    search_terms = [
        "laptop",
        "telefon",
        "kulaklık",
        "ayakkabı",
        "kitap"
    ]
    
    def on_start(self):
        self.search_term = self.search_terms[0]
    
    @task(1)
    def search_product(self):
        with self.client.get(
            "/arama",
            params={"q": self.search_term},
            catch_response=True,
            name="Search Product"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Search failed with status code: {response.status_code}")
    
    @task(1)
    def list_search_results(self):
        with self.client.get(
            f"/arama?q={self.search_term}",
            catch_response=True,
            name="List Search Results"
        ) as response:
            if response.status_code == 200 and len(response.content) > 0:
                response.success()
            else:
                response.failure("Failed to load search results")
