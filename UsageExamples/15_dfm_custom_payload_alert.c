#include "main.h"
#include "dfm.h"
#include "dfmUtility.h"
#include "demo_app.h"

void demo_custom_payload_alert(void)
{
    /* Keep the buffer valid until xDfmAlertEnd() has finished. */
    static char text[] = "Hello from the Percepio demo!\n"
    "This is a text payload provided in a custom DFM alert.\n"
    "Use this to include device log files or other custom data.\n\n"
    "See 15_dfm_custom_payload_alert.c for details.\n";

    DfmAlertHandle_t alert;

    DEMO_PRINTF("Demo 8: Custom alert with a .txt payload.");
    
    if (xDfmAlertBegin(DFM_TYPE_XYZ, "Custom alert", &alert) != DFM_SUCCESS) {
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
