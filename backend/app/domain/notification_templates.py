"""Chapter 17 notification matrix. English copy is the MVP source."""

from dataclasses import dataclass
from enum import StrEnum


class Channel(StrEnum):
    PUSH = "push"
    IN_APP = "inApp"
    SMS = "sms"


class Recipient(StrEnum):
    CUSTOMER = "customer"
    MECHANIC = "mechanic"
    SUPPORT = "support"
    OTHER = "other"


@dataclass(frozen=True)
class NotificationTemplate:
    event_id: str
    recipient: Recipient
    channels: tuple[Channel, ...]
    title: str
    body: str
    deep_link: str


PUSH_IN_APP: tuple[Channel, ...] = (Channel.PUSH, Channel.IN_APP)
PUSH_IN_APP_SMS: tuple[Channel, ...] = (Channel.PUSH, Channel.IN_APP, Channel.SMS)
IN_APP_ONLY: tuple[Channel, ...] = (Channel.IN_APP,)

# SMS is attempted only for these events, when the flag is on and no push token exists.
SMS_EVENTS: frozenset[str] = frozenset({"mechanicAssigned", "paymentPaid"})

TEMPLATES: tuple[NotificationTemplate, ...] = (
    NotificationTemplate(
        event_id="bookingConfirmed",
        recipient=Recipient.CUSTOMER,
        channels=PUSH_IN_APP,
        title="Booking confirmed",
        body="We're finding a mechanic for your {serviceName}.",
        deep_link="/booking/details?id={bookingId}",
    ),
    NotificationTemplate(
        event_id="mechanicAssigned",
        recipient=Recipient.CUSTOMER,
        channels=PUSH_IN_APP_SMS,
        title="Mechanic assigned",
        body="{mechanicName} will reach you for {serviceName}.",
        deep_link="/tracking?id={bookingId}",
    ),
    NotificationTemplate(
        event_id="offerCreated",
        recipient=Recipient.MECHANIC,
        channels=PUSH_IN_APP,
        title="New job nearby",
        body="{serviceName}, {distanceKm} km, {totalRupees}. Tap to respond.",
        deep_link="/mechanic/offers/{offerId}",
    ),
    NotificationTemplate(
        event_id="offerExpired",
        recipient=Recipient.MECHANIC,
        channels=IN_APP_ONLY,
        title="Offer ended",
        body="This job is no longer available.",
        deep_link="/mechanic/home",
    ),
    NotificationTemplate(
        event_id="mechanicEnRoute",
        recipient=Recipient.CUSTOMER,
        channels=PUSH_IN_APP,
        title="Mechanic is on the way",
        body="{mechanicName} has started towards you.",
        deep_link="/tracking?id={bookingId}",
    ),
    NotificationTemplate(
        event_id="mechanicArrived",
        recipient=Recipient.CUSTOMER,
        channels=PUSH_IN_APP,
        title="Mechanic arrived",
        body="{mechanicName} has reached your location.",
        deep_link="/tracking?id={bookingId}",
    ),
    NotificationTemplate(
        event_id="serviceStarted",
        recipient=Recipient.CUSTOMER,
        channels=PUSH_IN_APP,
        title="Service started",
        body="Work has started on your {vehicleLabel}.",
        deep_link="/tracking/progress?id={bookingId}",
    ),
    NotificationTemplate(
        event_id="extraWorkRequested",
        recipient=Recipient.CUSTOMER,
        channels=PUSH_IN_APP,
        title="Approve extra work",
        body="{lineName} adds {amountRupees}. Approve or reject within 10 minutes.",
        deep_link="/booking/details?id={bookingId}",
    ),
    NotificationTemplate(
        event_id="serviceCompleted",
        recipient=Recipient.CUSTOMER,
        channels=PUSH_IN_APP,
        title="Service completed",
        body="Pay {totalRupees} to finish this booking.",
        deep_link="/invoice?id={bookingId}",
    ),
    NotificationTemplate(
        event_id="paymentPaid",
        recipient=Recipient.CUSTOMER,
        channels=PUSH_IN_APP_SMS,
        title="Payment successful",
        body="{totalRupees} paid for {displayNumber}. Your invoice is ready.",
        deep_link="/invoice?id={bookingId}",
    ),
    NotificationTemplate(
        event_id="paymentPaid",
        recipient=Recipient.MECHANIC,
        channels=PUSH_IN_APP,
        title="Job paid",
        body="{displayNumber} is paid. Your recorded share is {shareRupees}.",
        deep_link="/mechanic/earnings",
    ),
    NotificationTemplate(
        event_id="paymentFailed",
        recipient=Recipient.CUSTOMER,
        channels=PUSH_IN_APP,
        title="Payment failed",
        body="The payment did not go through. You can try again.",
        deep_link="/booking/details?id={bookingId}",
    ),
    NotificationTemplate(
        event_id="bookingCancelled",
        recipient=Recipient.OTHER,
        channels=PUSH_IN_APP,
        title="Booking cancelled",
        body="{displayNumber} was cancelled.",
        deep_link="/booking/details?id={bookingId}",
    ),
    NotificationTemplate(
        event_id="bookingFailed",
        recipient=Recipient.CUSTOMER,
        channels=PUSH_IN_APP,
        title="No mechanic available",
        body="We couldn't find a mechanic nearby.",
        deep_link="/booking/details?id={bookingId}",
    ),
    NotificationTemplate(
        event_id="cashConfirm",
        recipient=Recipient.CUSTOMER,
        channels=PUSH_IN_APP,
        title="Confirm cash payment",
        body="Confirm you paid {totalRupees} in cash.",
        deep_link="/booking/details?id={bookingId}",
    ),
    NotificationTemplate(
        event_id="reviewPrompt",
        recipient=Recipient.CUSTOMER,
        channels=PUSH_IN_APP,
        title="Rate your service",
        body="How was {mechanicName}?",
        deep_link="/booking/details?id={bookingId}",
    ),
    NotificationTemplate(
        event_id="verificationApproved",
        recipient=Recipient.MECHANIC,
        channels=PUSH_IN_APP,
        title="You're verified",
        body="You can go online and take jobs.",
        deep_link="/mechanic/home",
    ),
    NotificationTemplate(
        event_id="verificationRejected",
        recipient=Recipient.MECHANIC,
        channels=PUSH_IN_APP,
        title="Verification needs changes",
        body="{reason}",
        deep_link="/mechanic/onboarding",
    ),
    NotificationTemplate(
        event_id="disputeOpened",
        recipient=Recipient.SUPPORT,
        channels=IN_APP_ONLY,
        title="New dispute",
        body="{displayNumber} needs review.",
        deep_link="/admin/disputes/{disputeId}",
    ),
)

# Unique event ids from chapter 17. paymentPaid has two recipient rows.
CHAPTER_17_EVENT_IDS: frozenset[str] = frozenset(
    {
        "bookingConfirmed",
        "mechanicAssigned",
        "offerCreated",
        "offerExpired",
        "mechanicEnRoute",
        "mechanicArrived",
        "serviceStarted",
        "extraWorkRequested",
        "serviceCompleted",
        "paymentPaid",
        "paymentFailed",
        "bookingCancelled",
        "bookingFailed",
        "cashConfirm",
        "reviewPrompt",
        "verificationApproved",
        "verificationRejected",
        "disputeOpened",
    }
)

_BY_EVENT_RECIPIENT: dict[tuple[str, Recipient], NotificationTemplate] = {
    (row.event_id, row.recipient): row for row in TEMPLATES
}


def lookup_template(event_id: str, recipient: Recipient) -> NotificationTemplate:
    template = _BY_EVENT_RECIPIENT.get((event_id, recipient))
    if template is None:
        raise KeyError(f"No notification template for {event_id}/{recipient.value}")
    return template


def render_template(template: NotificationTemplate, data: dict[str, str]) -> tuple[str, str, str]:
    """Replace {name} placeholders. Unknown keys stay in the string."""

    def _sub(text: str) -> str:
        rendered = text
        for key, value in data.items():
            rendered = rendered.replace("{" + key + "}", value)
        return rendered

    return _sub(template.title), _sub(template.body), _sub(template.deep_link)
