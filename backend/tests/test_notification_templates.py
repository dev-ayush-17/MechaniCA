from app.domain.notification_templates import CHAPTER_17_EVENT_IDS, TEMPLATES


def test_every_chapter_17_template_id_has_a_non_empty_title() -> None:
    ids_in_code = {row.event_id for row in TEMPLATES}
    assert ids_in_code == CHAPTER_17_EVENT_IDS
    for row in TEMPLATES:
        assert row.title.strip(), f"{row.event_id}/{row.recipient.value} has an empty title"
        assert row.body.strip(), f"{row.event_id}/{row.recipient.value} has an empty body"
        assert row.deep_link.strip(), f"{row.event_id}/{row.recipient.value} has an empty deep link"
        assert row.event_id
        assert row.channels
