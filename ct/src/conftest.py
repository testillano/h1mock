# Keep sorted
from collections import defaultdict
import glob
import json
import logging
import os
import pytest
#import xmltodict
import requests

#############
# CONSTANTS #
#############

# Endpoints
H1MOCK_ENDPOINT__admin = os.environ['H1MOCK_SERVICE_HOST'] + ':' + os.environ['H1MOCK_SERVICE_PORT_HTTP_ADMIN']
H1MOCK_ENDPOINT__traffic = os.environ['H1MOCK_SERVICE_HOST'] + ':' + os.environ['H1MOCK_SERVICE_PORT_HTTP_TRAFFIC']

# Api Path
H1MOCK_URI_PREFIX = 'app/v1'

######################
# CLASSES & FIXTURES #
######################

# Logging
class MyLogger:

  # CRITICAL ERROR WARNING INFO DEBUG NOSET
  def setLevelInfo(): logging.getLogger().setLevel(logging.INFO)
  def setLevelDebug(): logging.getLogger().setLevel(logging.DEBUG)

  def error(message): logging.getLogger().error(message)
  def warning(message): logging.getLogger().warning(message)
  def info(message): logging.getLogger().info(message)
  def debug(message): logging.getLogger().debug(message)

@pytest.fixture(scope='session')
def mylogger():
  return MyLogger

MyLogger.logger = logging.getLogger('CT')

# HTTP/1 abstract client:
class H1Client(object):
    """A client helper to perform rest operations: GET, POST.

    Attributes:
        endpoint: server endpoint to make the HTTP/1 connection
    """

    def __init__(self, endpoint):
        """Return a H1Client object for H1MOCK endpoint."""
        self._url_root = "http://" + endpoint

    def get(self, requestUrl):
        return requests.get(self._url_root + "/" + requestUrl)

    def postData(self, requestUrl, requestBody = None):
        return requests.post(self._url_root + "/" + requestUrl, data=requestBody)

    def postJson(self, requestUrl, requestBody = None):
        return requests.post(self._url_root + "/" + requestUrl, json=requestBody)

# H1MOCK Clients fixtures
@pytest.fixture(scope='session')
def h1mc_admin():
  h1mc = H1Client(H1MOCK_ENDPOINT__admin)
  yield h1mc
  print("H1MOCK-admin Teardown")

@pytest.fixture(scope='session')
def h1mc_traffic():
  h1mc = H1Client(H1MOCK_ENDPOINT__traffic)
  yield h1mc
  print("H1MOCK-traffic Teardown")

# Resources fixture
@pytest.fixture(scope='session')
def resources():
  resourcesDict={}
  MyLogger.info("Gathering test suite resources ...")
  for resource in glob.glob('resources/*'):
    f = open(resource, "r")
    name = os.path.basename(resource)
    resourcesDict[name] = f.read()
    f.close()

  def get_resources(key, **kwargs):
    # Be careful with templates containing curly braces:
    # https://stackoverflow.com/questions/5466451/how-can-i-print-literal-curly-brace-characters-in-python-string-and-also-use-fo
    resource = resourcesDict[key]

    if kwargs:
      args = defaultdict (str, kwargs)
      resource = resource.format_map(args)

    return resource

  yield get_resources

