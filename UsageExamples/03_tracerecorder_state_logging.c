#include "main.h"
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
    DEMO_PRINTF(trcStateName[currentState]);
}

void demo_state_logging(void)
{
    /* Resets and start the TraceRecorder tracing. */
    xTraceEnable(TRC_START);
   
    DEMO_PRINTF("DEMO_PRINTF also calls xTraceConsoleChannelPrintF()");

    /* Creates the StateMachine object in TraceRecorder and obtain the trcStateMachine handle. */
    xTraceStateMachineCreate("Lock", &trcStateMachine);

    /* Registers the state names and obtain the state handles stored in the trcStateHandle array. */
    xTraceStateMachineStateCreate(trcStateMachine, trcStateName[STATE_LOCKED],    &trcStateHandle[STATE_LOCKED]);
    xTraceStateMachineStateCreate(trcStateMachine, trcStateName[STATE_UNLOCKING], &trcStateHandle[STATE_UNLOCKING]);
    xTraceStateMachineStateCreate(trcStateMachine, trcStateName[STATE_UNLOCKED],  &trcStateHandle[STATE_UNLOCKED]);
    xTraceStateMachineStateCreate(trcStateMachine, trcStateName[STATE_LOCKING],   &trcStateHandle[STATE_LOCKING]);
    xTraceStateMachineStateCreate(trcStateMachine, trcStateName[STATE_ERROR],     &trcStateHandle[STATE_ERROR]);
        
    DEMO_PRINTF(LNBR "demo_state_logging - Demonstrates state logging with TraceRecorder." LNBR
             "Halt the execution after some second, then take a snapshot" LNBR
             "of the trace buffer and view it in Tracealyzer." LNBR
             "See details in 03_tracerecorder_state_loggning.c." LNBR );   
    
    SetState(STATE_LOCKING);   
    OS_delay_ms(10);
    SetState(STATE_LOCKED);    
    OS_delay_ms(20);
    SetState(STATE_UNLOCKING);    
    OS_delay_ms(10);
    SetState(STATE_UNLOCKED);    
    OS_delay_ms(20);
    SetState(STATE_LOCKING);    
    OS_delay_ms(10);
    SetState(STATE_ERROR);    
    OS_delay_ms(20);
    
    xTraceDisable();
    OS_delay_ms(3000);
}