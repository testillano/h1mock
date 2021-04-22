import pytest


def test_001_check_admin_keep_alive(h1mc_admin):

  # Send GET
  response = h1mc_admin.get("healthz")

  # Verify response
  assert response.status_code == 200

