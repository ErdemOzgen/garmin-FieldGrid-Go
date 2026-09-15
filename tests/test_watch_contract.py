"""Watch package privacy boundaries; legacy renderer is deliberately separate."""

import re
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WATCH = ROOT / "apps/watch"


def test_watch_cannot_request_network_access():
    manifest = ET.parse(WATCH / "manifest.xml").getroot()
    ns = {"iq": "http://www.garmin.com/xml/connectiq"}
    permissions = {node.attrib["id"] for node in manifest.findall(".//iq:uses-permission", ns)}
    assert permissions == {"Positioning", "Sensor"}
    for source in (WATCH / "source").glob("*.mc"):
        assert not re.search(r"\b(makeWebRequest|makeImageRequest)\s*\(", source.read_text())


def test_watch_resources_cannot_embed_private_server_configuration():
    jungle = (WATCH / "monkey.jungle").read_text()
    resource_paths = re.search(r"^base.resourcePath\s*=\s*(.+)$", jungle, re.M)[1].split(";")
    for value in resource_paths:
        path = (WATCH / value.strip()).resolve()
        assert path.is_relative_to(WATCH.resolve())
    for source in (WATCH / "resources").rglob("*.xml"):
        assert "ConfigBaseUrl" not in source.read_text()
        assert "ConfigDevToken" not in source.read_text()


def test_grid_does_not_write_application_storage():
    for source in (WATCH / "source").glob("*.mc"):
        assert not re.search(r"\bStorage\s*\.\s*setValue\s*\(", source.read_text())


def test_watch_has_no_recording_or_phone_modules():
    forbidden = {
        "Activity",
        "ActivityRecording",
        "FitContributor",
        "Communications",
        "PersistedContent",
        "Background",
    }
    for source in (WATCH / "source").glob("*.mc"):
        imported = set(re.findall(r"(?:import|using)\s+Toybox\.(\w+)", source.read_text()))
        assert not imported & forbidden
    assert not (WATCH / "source/RecordingController.mc").exists()
