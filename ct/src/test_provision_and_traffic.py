import pytest
import json
import time


def test_001_provision_rules_and_functions(resources, h1mc_admin):

  # Send POST
  rulesAndFunctionsProvision = resources("rules-and-functions")
  response = h1mc_admin.postData("app/v1/provision/myprovision", rulesAndFunctionsProvision)

  # Verify response
  assert response.status_code == 201
  assert response.json()["result"] == "success: basename file 'myprovision' has been loaded"

  time.sleep(1)


def test_002_request_to_rules_and_functions(h1mc_traffic):

  # Send GET
  response = h1mc_traffic.get("app/v1/foo/bar")

  # Verify response
  assert response.status_code == 200
  assert response.json()["resultData"] == "answering a get"


def test_003_provision_default(resources, h1mc_admin):

  # Send POST
  default = resources("default")
  response = h1mc_admin.postData("app/v1/provision/other_provision", default)

  # Verify response
  assert response.status_code == 201
  assert response.json()["result"] == "success: basename file 'other_provision' has been loaded"

  time.sleep(1)


def test_004_request_to_default(h1mc_traffic):

  # Send GET
  response = h1mc_traffic.get("app/v1/any/path")

  # Verify response
  assert response.status_code == 404
  assert response.text == '<a href="https://github.com/testillano/h1mock#how-it-works">help here</a>'

