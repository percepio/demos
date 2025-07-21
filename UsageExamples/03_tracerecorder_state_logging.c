#include "main.h"
#include "FreeRTOS.h"
#include "task.h"
#include "trcRecorder.h"

/******************************************************************************
 * 03_tracerecorder_state_logging.c
 *
 * Demonstrates loggning of state changes with Percepio TraceRecorder, using the
 * trcStateMachine.h functions. This requires Percepio Tracealyzer for analysis.
 *
 * This example can be used with any TraceRecorder configuration, also continuous
 * streaming, but the default configuration is for snapshots using the RingBuffer
 * streamport module.
 *
 * For information on recording and viewing TraceRecorder traces, please refer
 * to https://percepio.com/tracealyzer/gettingstarted.
 *
 * Learn more in main.c and at https://percepio.com/tracealyzer.
 *****************************************************************************/


typedef enum {
    STATE_LOCKED,
    STATE_UNLOCKING,
    STATE_UNLOCKED,
    STATE_LOCKING,
    STATE_ERROR,
    STATE_COUNT
} MyState_t;

char trcStateName[STATE_COUNT][20] = {"LOCKED", "UNLOCKING", "UNLOCKED", "LOCKING", "ERROR"};

static TraceStateMachineHandle_t trcStateMachine;
static TraceStateMachineStateHandle_t trcStateHandle[STATE_COUNT];

static MyState_t currentState;

void SetState(MyState_t new_state)
{
    /* Updates the state */
    currentState = new_state;
    
    /* Logs the state change as an event in TraceRecorder, using the state handle
       provided by xTraceStateMachineStateCreate(). */
    xTraceStateMachineSetState(trcStateMachine, trcStateHandle[currentState]);
    
    /* Print to the console to show something is happening... */
    printf("State is now: %s\n", trcStateName[currentState]);
}

void demo_state_logging(void)
{
    /* Resets and start the TraceRecorder tracing. */
    xTraceEnable(TRC_START);    
   
    /* Creates the StateMachine object in TraceRecorder and obtain the trcStateMachine handle. */
    xTraceStateMachineCreate("Lock", &trcStateMachine);

    /* Registers the state names and obtain the state handles stored in the trcStateHandle array. */
    xTraceStateMachineStateCreate(trcStateMachine, trcStateName[STATE_LOCKED],    &trcStateHandle[STATE_LOCKED]);
    xTraceStateMachineStateCreate(trcStateMachine, trcStateName[STATE_UNLOCKING], &trcStateHandle[STATE_UNLOCKING]);
    xTraceStateMachineStateCreate(trcStateMachine, trcStateName[STATE_UNLOCKED],  &trcStateHandle[STATE_UNLOCKED]);
    xTraceStateMachineStateCreate(trcStateMachine, trcStateName[STATE_LOCKING],   &trcStateHandle[STATE_LOCKING]);
    xTraceStateMachineStateCreate(trcStateMachine, trcStateName[STATE_ERROR],     &trcStateHandle[STATE_ERROR]);
    
    printf("\n\rdemo_state_logging - Demonstrates state logging with TraceRecorder.\n\r"
             "Halt the execution after some second, then take a snapshot\n\r"
             "of the trace buffer and view it in Tracealyzer.\n\r"
             "See details in 03_tracerecorder_state_loggning.c.\n\r\n\r" );   
    
    SetState(STATE_LOCKING);   
    vTaskDelay(10);
    SetState(STATE_LOCKED);    
    vTaskDelay(20);
    SetState(STATE_UNLOCKING);    
    vTaskDelay(10);
    SetState(STATE_UNLOCKED);    
    vTaskDelay(20);
    SetState(STATE_LOCKING);    
    vTaskDelay(10);
    SetState(STATE_ERROR);    
    vTaskDelay(20);
    
    xTraceDisable();
    vTaskDelay(3000);
}

static void dummy_exectime(int min, int max)
{
     // Some execution time variations...
     int n = min + rand() % (max-min);
     for (volatile int i = 0; i < n; i++);
}
