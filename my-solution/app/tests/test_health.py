from fastapi.testclient import TestClient

import sys
from pathlib import Path


APP_DIR = Path(__file__).resolve().parents[1]
if str(APP_DIR) not in sys.path:
    sys.path.insert(0, str(APP_DIR))

import main


def test_health_live_ok() -> None:
    # Avoid external dependency checks on startup for unit tests
    main.app.router.on_startup.clear()

    client = TestClient(main.app)

    resp = client.get("/health/live")
    assert resp.status_code == 200
    payload = resp.json()
    assert payload["status"] == "ok"
    assert payload["service"] == "document-service"


def test_health_ready_returns_json() -> None:
    # Avoid external dependency checks on startup for unit tests
    main.app.router.on_startup.clear()

    client = TestClient(main.app)

    # In unit-test env there may be no AWS creds/bucket; readiness may be 503.
    resp = client.get("/health/ready")
    assert resp.status_code in {200, 503}
    data = resp.json() if resp.headers.get("content-type", "").startswith("application/json") else None
    assert data is not None

    if resp.status_code == 200:
        assert data.get("service") == "document-service"
    else:
        assert data.get("detail", {}).get("service") == "document-service"
