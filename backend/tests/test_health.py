from fastapi.testclient import TestClient

from app.adapters.fake.readiness import FakeReadiness
from app.api.deps import readiness_dep
from app.main import create_app


def test_health_ok() -> None:
    client = TestClient(create_app())
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_ready_reports_dependency() -> None:
    app = create_app()
    app.dependency_overrides[readiness_dep] = lambda: FakeReadiness({"firestore": True})
    response = TestClient(app).get("/health/ready")
    assert response.status_code == 200
    assert response.json()["checks"] == {"firestore": True}


def test_ready_is_503_when_a_dependency_is_down() -> None:
    app = create_app()
    app.dependency_overrides[readiness_dep] = lambda: FakeReadiness({"firestore": False})
    response = TestClient(app).get("/health/ready")
    assert response.status_code == 503
