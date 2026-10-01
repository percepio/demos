#include "main.h"
#include "dfm.h"
#include "dfmUtility.h"
#include "demo_app.h"

/* Application-defined alert type; symptom IDs come from dfmCodes.h via dfm.h. */
#define ALERT_TYPE_CUSTOM 8

void demo_custom_payload_alert(void)
{
    /* Keep the buffer valid until xDfmAlertEnd() has finished. */
    static char text[] = "Hello from the Percepio demo!\n"
    "This is a custom text payload provided with a DFM alert.\n"
    "You may use such payloads to provide device log files or "
    "other data from your device at any point you choose.\n"
    "See 15_dfm_custom_payload_alert.c for the code example.\n\n"
    "Note that this alert type is not defined by default in the "
    "Detect server and therefore showed with its numeric code.\n"
    "See Documentation/Console Help for details.\n";
    DfmAlertHandle_t alert;

    DEMO_PRINTF("Demo 8: Custom alert with a .txt payload.");
    
    if (xDfmAlertBegin(ALERT_TYPE_CUSTOM, "Custom alert", &alert) != DFM_SUCCESS) {
        DEMO_PRINTF("ERROR: Could not begin custom alert.");
        return;
    }

    xDfmAlertAddSymptom(alert, DFM_SYMPTOM_FILE, ulDfmCalculateChecksum(szDfmGetFileNameFromPath(__FILE__), 32));

    xDfmAlertAddSymptom(alert, DFM_SYMPTOM_LINE, __LINE__);

    /* The description is the filename; exclude the terminating NUL. */
    xDfmAlertAddPayload(alert, text, sizeof(text) - 1U, "hello.txt");

    if (xDfmAlertEnd(alert) != DFM_SUCCESS) {
        DEMO_PRINTF("ERROR: Could not send custom alert.");
        return;
    }

    DEMO_PRINTF("Custom alert sent with two symptoms and hello.txt.");
}
